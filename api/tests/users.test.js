// People and permissions. Only the owner adds people or changes what they may
// do, nobody is ever deleted, and a temporary password must be changed at
// first sign-in. SCHEMA.md Permissions, decision 062 for the screen.

import test, { before, after } from 'node:test';
import assert from 'node:assert/strict';

import { connect, dropAll, buildSchema, seedUsers, startServer, signIn } from './helpers/api.js';

let connection;
let api;
const tokens = {};
let createdId;

const TEMP = 'Temporary-Pass-1';

before(async () => {
  connection = await connect();
  await buildSchema(connection);
  await seedUsers(connection);
  api = await startServer();
  for (const role of ['owner', 'admin', 'staff']) {
    tokens[role] = (await signIn(api, `${role}@test.local`)).body.accessToken;
  }
});

after(async () => {
  await api?.close();
  if (connection) {
    await dropAll(connection);
    await connection.end();
  }
});

const newPerson = (overrides = {}) => ({
  name: 'Fazal',
  email: 'fazal@test.local',
  role: 'staff',
  temporaryPassword: TEMP,
  sharesOwnerLogin: false,
  ...overrides,
});

test('only the owner sees the list of people', async () => {
  const owner = await api.get('/people', { token: tokens.owner });
  assert.equal(owner.status, 200, owner.raw);
  assert.ok(owner.body.people.some((p) => p.email === 'owner@test.local'));
  assert.ok(!('passwordHash' in owner.body.people[0]) && !('password_hash' in owner.body.people[0]));

  for (const role of ['admin', 'staff']) {
    const response = await api.get('/people', { token: tokens[role] });
    assert.equal(response.status, 403, `${role}: ${response.raw}`);
  }
});

test('an admin cannot add a person', async () => {
  const response = await api.post('/people', { token: tokens.admin, body: newPerson() });
  assert.equal(response.status, 403, response.raw);
});

test('the owner adds a staff member, who must change the password at first sign-in', async () => {
  const response = await api.post('/people', { token: tokens.owner, body: newPerson() });
  assert.equal(response.status, 201, response.raw);
  const person = response.body.person;
  createdId = person.id;
  assert.equal(person.role, 'staff');
  assert.equal(person.mustChangePassword, true);
  assert.equal(person.approvalLimit, null);

  const login = await signIn(api, 'fazal@test.local', TEMP);
  assert.equal(login.status, 200, login.raw);
  assert.equal(login.body.user.mustChangePassword, true);

  const [audit] = await connection.query(
    `SELECT after_json FROM audit_log WHERE table_name = 'users' AND record_id = ?`, [createdId],
  );
  assert.equal(audit.length, 1, 'the addition is in the audit log');
  assert.doesNotMatch(JSON.stringify(audit[0].after_json), /Temporary-Pass|\$2[aby]?\$/, 'no password in the audit log');
});

test('staff never carry an approval limit or post their own entries', async () => {
  const response = await api.post('/people', {
    token: tokens.owner,
    body: newPerson({
      name: 'Odd staff', email: 'odd@test.local',
      approvalLimit: { minor: 1000000, currency: 'PKR' }, autoApproveOwn: true,
    }),
  });
  assert.equal(response.status, 201, response.raw);
  assert.equal(response.body.person.approvalLimit, null);
  assert.equal(response.body.person.autoApproveOwn, false);
});

test('the same email twice is refused in plain words', async () => {
  const response = await api.post('/people', { token: tokens.owner, body: newPerson({ name: 'Again' }) });
  assert.equal(response.status, 409, response.raw);
  assert.equal(response.body.error.message, 'Someone already signs in with that email.');
});

test('a temporary password under ten characters is refused', async () => {
  const response = await api.post('/people', {
    token: tokens.owner, body: newPerson({ email: 'short@test.local', temporaryPassword: 'short' }),
  });
  assert.equal(response.status, 400, response.raw);
  assert.equal(response.body.error.field, 'temporaryPassword');
});

test('another owner cannot be made', async () => {
  const response = await api.post('/people', {
    token: tokens.owner, body: newPerson({ email: 'owner2@test.local', role: 'owner' }),
  });
  assert.equal(response.status, 400, response.raw);
});

test('the owner makes a staff member an admin with a limit, and it is audited', async () => {
  const response = await api.patch(`/people/${createdId}`, {
    token: tokens.owner,
    body: { role: 'admin', approvalLimit: { minor: 5000000, currency: 'PKR' }, autoApproveOwn: true },
  });
  assert.equal(response.status, 200, response.raw);
  assert.equal(response.body.person.role, 'admin');
  assert.equal(response.body.person.approvalLimit.minor, 5000000);
  assert.equal(response.body.person.autoApproveOwn, true);

  const [rows] = await connection.query(
    `SELECT action FROM audit_log WHERE table_name = 'users' AND record_id = ? AND action = 'permission_change'`,
    [createdId],
  );
  assert.equal(rows.length, 1);
});

test('turning an admin back to staff clears the limit and own posting', async () => {
  const response = await api.patch(`/people/${createdId}`, { token: tokens.owner, body: { role: 'staff' } });
  assert.equal(response.status, 200, response.raw);
  assert.equal(response.body.person.approvalLimit, null);
  assert.equal(response.body.person.autoApproveOwn, false);
});

test('the office login itself cannot be changed here', async () => {
  const [rows] = await connection.query(`SELECT id FROM users WHERE role = 'owner'`);
  const response = await api.patch(`/people/${rows[0].id}`, {
    token: tokens.owner, body: { role: 'staff' },
  });
  assert.equal(response.status, 409, response.raw);
});

test('a reset password must be changed again, and ends open sessions', async () => {
  const before = await signIn(api, 'fazal@test.local', TEMP);
  assert.equal(before.status, 200);

  const reset = await api.post(`/people/${createdId}/reset-password`, {
    token: tokens.owner, body: { temporaryPassword: 'Another-Temp-22' },
  });
  assert.equal(reset.status, 200, reset.raw);
  assert.equal(reset.body.person.mustChangePassword, true);

  const [open] = await connection.query(
    'SELECT COUNT(*) AS n FROM refresh_tokens WHERE user_id = ? AND revoked_at IS NULL', [createdId],
  );
  assert.equal(Number(open[0].n), 0, 'every session was ended');

  assert.equal((await signIn(api, 'fazal@test.local', TEMP)).status, 401, 'the old password stops working');
  assert.equal((await signIn(api, 'fazal@test.local', 'Another-Temp-22')).status, 200);
});

test('a switched-off person cannot sign in, and is kept, not deleted', async () => {
  const response = await api.patch(`/people/${createdId}`, { token: tokens.owner, body: { isActive: false } });
  assert.equal(response.status, 200, response.raw);
  assert.equal(response.body.person.isActive, false);

  const login = await signIn(api, 'fazal@test.local', 'Another-Temp-22');
  assert.equal(login.status, 403, login.raw);

  const [rows] = await connection.query('SELECT COUNT(*) AS n FROM users WHERE id = ?', [createdId]);
  assert.equal(Number(rows[0].n), 1);

  const picker = await api.get('/users', { token: tokens.staff });
  assert.ok(!picker.body.users.some((u) => u.id === createdId), 'a switched-off person is not offered on entries');
});
