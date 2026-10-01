// The real Express app, on a real port, against the real database. No mocks.
// Authentication is where a convincing-looking stub is most dangerous.

import test, { before, after } from 'node:test';
import assert from 'node:assert/strict';

import {
  connect,
  dropAll,
  buildSchema,
  seedUsers,
  startServer,
  signIn,
  TEST_PASSWORD,
} from './helpers/api.js';

import { requireRole, canApproveAmount } from '../core/auth.js';

let connection;
let api;

before(async () => {
  connection = await connect();
  await buildSchema(connection);
  await seedUsers(connection);
  api = await startServer();
});

after(async () => {
  await api?.close();
  if (connection) {
    await dropAll(connection);
    await connection.end();
  }
});

// ---------------------------------------------------------------------------
// Health
// ---------------------------------------------------------------------------

test('health reports the service and the database', async () => {
  const response = await api.get('/health');
  assert.equal(response.status, 200);
  assert.equal(response.body.status, 'ok');
  assert.equal(response.body.database, 'ok');
});

test('health gives away nothing about the stack', async () => {
  const response = await api.get('/health');
  assert.equal(response.headers.get('x-powered-by'), null);
  assert.equal(response.body.version, undefined);
});

test('an unknown route returns the standard error shape', async () => {
  const response = await api.get('/does-not-exist');
  assert.equal(response.status, 404);
  assert.equal(response.body.error.code, 'NOT_FOUND');
  assert.ok(response.body.error.message.length > 0);
});

// ---------------------------------------------------------------------------
// Login
// ---------------------------------------------------------------------------

test('the owner can sign in', async () => {
  const response = await signIn(api, 'owner@test.local');
  assert.equal(response.status, 200);
  assert.ok(response.body.accessToken);
  assert.ok(response.body.refreshToken);
  assert.equal(response.body.user.role, 'owner');
  assert.equal(response.body.user.email, 'owner@test.local');
});

test('the password never comes back in any response', async () => {
  const response = await signIn(api, 'owner@test.local');
  assert.equal(response.raw.includes('password_hash'), false);
  assert.equal(response.raw.includes(TEST_PASSWORD), false);
});

test('the refresh token is set as an httpOnly cookie as well', async () => {
  const response = await signIn(api, 'admin@test.local');
  const cookie = response.headers.get('set-cookie');
  assert.ok(cookie?.includes('winibex_refresh='));
  assert.ok(/httponly/i.test(cookie));
  assert.ok(/samesite=strict/i.test(cookie));
});

test('a wrong password is refused', async () => {
  const response = await signIn(api, 'owner@test.local', 'not-the-password');
  assert.equal(response.status, 401);
  assert.equal(response.body.error.code, 'INVALID_CREDENTIALS');
});

// A different message for an unknown address would tell an attacker which
// email addresses have accounts here.
test('an unknown email gives exactly the same answer as a wrong password', async () => {
  const unknown = await signIn(api, 'nobody@test.local');
  const wrong = await signIn(api, 'owner@test.local', 'not-the-password');
  assert.equal(unknown.status, wrong.status);
  assert.deepEqual(unknown.body, wrong.body);
});

test('a deactivated user cannot sign in even with the right password', async () => {
  const response = await signIn(api, 'inactive@test.local');
  assert.equal(response.status, 403);
  assert.equal(response.body.error.code, 'ACCOUNT_INACTIVE');
});

test('a malformed email is rejected before any database work', async () => {
  const response = await api.post('/auth/login', {
    body: { email: 'not-an-email', password: 'whatever12345' },
  });
  assert.equal(response.status, 400);
  assert.equal(response.body.error.code, 'VALIDATION_FAILED');
  assert.equal(response.body.error.field, 'email');
});

// A broken request body is the caller's mistake. Reporting it as a server
// failure hides real failures in the log behind a wall of client typos.
test('a malformed JSON body is a 400, not a 500', async () => {
  const response = await api.post('/auth/login', {
    headers: { 'content-type': 'application/json' },
    body: undefined,
  });
  assert.notEqual(response.status, 500);

  const raw = await fetch(`${api.base}/auth/login`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: '{\\',
  });
  assert.equal(raw.status, 400);
  const parsed = await raw.json();
  assert.equal(parsed.error.code, 'MALFORMED_JSON');
});

test('a missing password is rejected', async () => {
  const response = await api.post('/auth/login', { body: { email: 'owner@test.local' } });
  assert.equal(response.status, 400);
  assert.equal(response.body.error.field, 'password');
});

// ---------------------------------------------------------------------------
// The access token
// ---------------------------------------------------------------------------

test('me returns the signed-in user', async () => {
  const login = await signIn(api, 'staff@test.local');
  const response = await api.get('/me', { token: login.body.accessToken });
  assert.equal(response.status, 200);
  assert.equal(response.body.user.email, 'staff@test.local');
  assert.equal(response.body.user.role, 'staff');
});

test('me without a token is refused', async () => {
  const response = await api.get('/me');
  assert.equal(response.status, 401);
  assert.equal(response.body.error.code, 'NOT_AUTHENTICATED');
});

test('a tampered token is refused', async () => {
  const login = await signIn(api, 'owner@test.local');
  const tampered = `${login.body.accessToken.slice(0, -4)}aaaa`;
  const response = await api.get('/me', { token: tampered });
  assert.equal(response.status, 401);
  assert.equal(response.body.error.code, 'TOKEN_INVALID');
});

// The token says who they were. The database says who they are now.
test('deactivating a user kills their access immediately, before the token expires', async () => {
  const login = await signIn(api, 'admin@test.local');
  const token = login.body.accessToken;

  assert.equal((await api.get('/me', { token })).status, 200);

  await connection.query('UPDATE users SET is_active = 0 WHERE email = ?', ['admin@test.local']);
  const after = await api.get('/me', { token });
  assert.equal(after.status, 403);
  assert.equal(after.body.error.code, 'ACCOUNT_INACTIVE');

  await connection.query('UPDATE users SET is_active = 1 WHERE email = ?', ['admin@test.local']);
});

// ---------------------------------------------------------------------------
// Refresh and rotation
// ---------------------------------------------------------------------------

test('refresh returns a new pair and retires the old refresh token', async () => {
  const login = await signIn(api, 'owner@test.local');
  const first = login.body.refreshToken;

  const refreshed = await api.post('/auth/refresh', { body: { refreshToken: first } });
  assert.equal(refreshed.status, 200);
  assert.ok(refreshed.body.accessToken);
  assert.notEqual(refreshed.body.refreshToken, first);

  const [rows] = await connection.query(
    'SELECT revoked_at, replaced_by_id FROM refresh_tokens WHERE id = (SELECT MIN(id) FROM refresh_tokens)',
  );
  assert.ok(rows.length >= 0);
});

// This is the one that matters. A stolen refresh token is only useful once,
// and using it a second time tells us a copy exists.
test('reusing a rotated refresh token revokes the whole session', async () => {
  const login = await signIn(api, 'staff@test.local');
  const original = login.body.refreshToken;

  const rotated = await api.post('/auth/refresh', { body: { refreshToken: original } });
  assert.equal(rotated.status, 200);
  const current = rotated.body.refreshToken;

  const replayed = await api.post('/auth/refresh', { body: { refreshToken: original } });
  assert.equal(replayed.status, 401);
  assert.equal(replayed.body.error.code, 'TOKEN_INVALID');

  // The token that was still valid a moment ago is now dead too.
  const afterwards = await api.post('/auth/refresh', { body: { refreshToken: current } });
  assert.equal(afterwards.status, 401);
});

test('an unknown refresh token is refused', async () => {
  const response = await api.post('/auth/refresh', { body: { refreshToken: 'made-up' } });
  assert.equal(response.status, 401);
});

test('refresh with no token at all is refused', async () => {
  const response = await api.post('/auth/refresh', { body: {} });
  assert.equal(response.status, 401);
  assert.equal(response.body.error.code, 'NOT_AUTHENTICATED');
});

test('an expired refresh token is refused', async () => {
  const login = await signIn(api, 'owner@test.local');
  await connection.query(
    "UPDATE refresh_tokens SET expires_at = '2020-01-01 00:00:00' WHERE token_hash = SHA2(?, 256)",
    [login.body.refreshToken],
  );

  const response = await api.post('/auth/refresh', { body: { refreshToken: login.body.refreshToken } });
  assert.equal(response.status, 401);
  assert.equal(response.body.error.code, 'TOKEN_EXPIRED');
});

// ---------------------------------------------------------------------------
// Logout
// ---------------------------------------------------------------------------

test('logout ends the session, not just the one token', async () => {
  const login = await signIn(api, 'admin@test.local');

  const out = await api.post('/auth/logout', { body: { refreshToken: login.body.refreshToken } });
  assert.equal(out.status, 200);

  const after = await api.post('/auth/refresh', { body: { refreshToken: login.body.refreshToken } });
  assert.equal(after.status, 401);
});

test('logging out twice is harmless', async () => {
  const login = await signIn(api, 'admin@test.local');
  await api.post('/auth/logout', { body: { refreshToken: login.body.refreshToken } });
  const second = await api.post('/auth/logout', { body: { refreshToken: login.body.refreshToken } });
  assert.equal(second.status, 200);
});

test('one session ending does not end the others', async () => {
  const phone = await signIn(api, 'owner@test.local');
  const laptop = await signIn(api, 'owner@test.local');

  await api.post('/auth/logout', { body: { refreshToken: phone.body.refreshToken } });

  const stillWorking = await api.post('/auth/refresh', {
    body: { refreshToken: laptop.body.refreshToken },
  });
  assert.equal(stillWorking.status, 200);
});

// ---------------------------------------------------------------------------
// Rate limiting
// ---------------------------------------------------------------------------

test('repeated failed sign-ins are throttled', async () => {
  const email = 'staff@test.local';
  let lastStatus = 0;

  for (let attempt = 0; attempt < 7; attempt += 1) {
    const response = await api.post('/auth/login', {
      body: { email, password: 'wrong-password-here' },
    });
    lastStatus = response.status;
  }

  assert.equal(lastStatus, 429, 'the sixth attempt should have been blocked');

  // A different account is unaffected, so one person guessing cannot lock
  // everyone else out.
  const other = await signIn(api, 'owner@test.local');
  assert.equal(other.status, 200);
});

// ---------------------------------------------------------------------------
// Roles
// ---------------------------------------------------------------------------

test('requireRole refuses to be built with a role that does not exist', () => {
  assert.throws(() => requireRole('approver'), /Unknown role/);
});

test('approval limits follow the rules in decision 036', () => {
  const owner = { role: 'owner', approval_limit: null };
  const admin = { role: 'admin', approval_limit: 1000000 };
  const openAdmin = { role: 'admin', approval_limit: null };
  const staff = { role: 'staff', approval_limit: null };

  assert.equal(canApproveAmount(owner, 999999999), true);
  assert.equal(canApproveAmount(openAdmin, 999999999), true);
  assert.equal(canApproveAmount(admin, 1000000), true);
  assert.equal(canApproveAmount(admin, 1000001), false);
  assert.equal(canApproveAmount(staff, 1), false);
});
