// The transaction endpoints, over HTTP, against the real database.
//
// The service tests prove the rules. These prove the edge: that a bad request
// is refused before it reaches the rules, that the right person is refused,
// and that a repeated request does the work once.

import test, { before, after } from 'node:test';
import assert from 'node:assert/strict';

import {
  connect, dropAll, buildSchema, seedUsers, seedAccounts,
  startServer, signIn, accountId, categoryId, idempotencyKey,
} from './helpers/api.js';
import { WARNING_CODES } from '../modules/transactions/validation.js';

let connection;
let api;
const tokens = {};
let bankId;
let outCategory;

before(async () => {
  connection = await connect();
  await buildSchema(connection);
  await seedUsers(connection);
  await seedAccounts(connection);
  api = await startServer();

  for (const role of ['owner', 'admin', 'staff']) {
    const login = await signIn(api, `${role}@test.local`);
    tokens[role] = login.body.accessToken;
  }

  bankId = await accountId(connection);
  outCategory = await categoryId(connection, 'out');
});

after(async () => {
  await api?.close();
  if (connection) {
    await dropAll(connection);
    await connection.end();
  }
});

function entry(overrides = {}) {
  return {
    date: '2026-07-05',
    direction: 'out',
    method: 'card',
    description: 'Claude subscription',
    categoryId: outCategory,
    accountId: bankId,
    gross: { minor: 560000, currency: 'PKR' },
    // Not a validation test. The accounts start empty, so acknowledge the
    // warnings that follow from that and leave them to api-validation.test.js.
    acknowledged_warnings: WARNING_CODES,
    ...overrides,
  };
}

// Not async: it returns the promise api.post gives back, and the caller
// awaits it. Marking it async would mean either an await with nothing to wait
// for, or a return await, and the lint config refuses both.
function createEntry(token = tokens.owner, body = entry()) {
  return api.post('/transactions', { token, body, headers: idempotencyKey() });
}

// ---------------------------------------------------------------------------
// Validation at the edge
// ---------------------------------------------------------------------------

test('a float in a money field is refused, not rounded', async () => {
  const response = await createEntry(tokens.owner, entry({
    gross: { minor: 5600.5, currency: 'PKR' },
  }));

  assert.equal(response.status, 400);
  assert.equal(response.body.error.code, 'VALIDATION_FAILED');
  assert.ok(response.body.error.field.includes('minor'));
});

test('a foreign amount with no rate is refused before the database sees it', async () => {
  const response = await createEntry(tokens.owner, entry({
    foreign: { minor: 2000, currency: 'USD' },
  }));

  assert.equal(response.status, 400);
  assert.equal(response.body.error.field, 'fxRate');
});

test('paid by a person with nobody named is refused', async () => {
  const response = await createEntry(tokens.owner, entry({
    paidByType: 'person', accountId: null,
  }));

  assert.equal(response.status, 400);
  assert.equal(response.body.error.field, 'paidByUserId');
});

test('an ordinary entry with no account is refused', async () => {
  const response = await createEntry(tokens.owner, entry({ accountId: null }));
  assert.equal(response.status, 400);
  assert.equal(response.body.error.field, 'accountId');
});

test('a zero amount is refused, because direction carries the sign', async () => {
  const response = await createEntry(tokens.owner, entry({
    gross: { minor: 0, currency: 'PKR' },
  }));
  assert.equal(response.status, 400);
});

// ---------------------------------------------------------------------------
// Idempotency
// ---------------------------------------------------------------------------

test('a money-creating request with no key is refused', async () => {
  const response = await api.post('/transactions', { token: tokens.owner, body: entry() });
  assert.equal(response.status, 400);
  assert.equal(response.body.error.code, 'IDEMPOTENCY_KEY_REQUIRED');
});

test('the same key twice creates one transaction and replays the first answer', async () => {
  const headers = idempotencyKey();
  const body = entry({ description: 'Sent twice' });

  const first = await api.post('/transactions', { token: tokens.owner, body, headers });
  const second = await api.post('/transactions', { token: tokens.owner, body, headers });

  assert.equal(first.status, 201);
  assert.equal(second.status, 201);
  assert.equal(second.headers.get('idempotent-replay'), 'true');
  assert.deepEqual(second.body, first.body, 'the retry got a different answer');

  const [rows] = await connection.query(
    'SELECT COUNT(*) AS n FROM transactions WHERE description = ?',
    ['Sent twice'],
  );
  assert.equal(Number(rows[0].n), 1, 'a double tap created two expenses');
});

// ---------------------------------------------------------------------------
// Who may do what
// ---------------------------------------------------------------------------

test('staff can create and submit, but not approve', async () => {
  const created = await createEntry(tokens.staff);
  assert.equal(created.status, 201);
  const id = created.body.transaction.id;

  const submitted = await api.post(`/transactions/${id}/submit`, { token: tokens.staff });
  assert.equal(submitted.status, 200);
  assert.equal(submitted.body.status, 'pending');

  const approved = await api.post(`/transactions/${id}/approve`, {
    token: tokens.staff, headers: idempotencyKey(),
  });
  assert.equal(approved.status, 403);
  assert.ok(/owner or an admin/i.test(approved.body.error.message));
});

test('the owner approving a staff entry marks it as possibly self approved', async () => {
  const created = await createEntry(tokens.staff);
  const id = created.body.transaction.id;
  await api.post(`/transactions/${id}/submit`, { token: tokens.staff });

  const approved = await api.post(`/transactions/${id}/approve`, {
    token: tokens.owner, headers: idempotencyKey(),
  });
  assert.equal(approved.status, 200);

  const [rows] = await connection.query(
    'SELECT approval_method, possible_self_approval FROM transactions WHERE id = ?',
    [id],
  );
  assert.equal(rows[0].approval_method, 'owner');
  assert.equal(Number(rows[0].possible_self_approval), 1);
});

test('an admin cannot approve past their limit', async () => {
  await connection.query(
    `UPDATE users SET approval_limit = 100000 WHERE email = 'admin@test.local'`,
  );

  const created = await createEntry(tokens.staff);
  const id = created.body.transaction.id;
  await api.post(`/transactions/${id}/submit`, { token: tokens.staff });

  const approved = await api.post(`/transactions/${id}/approve`, {
    token: tokens.admin, headers: idempotencyKey(),
  });
  assert.equal(approved.status, 403);
  assert.equal(approved.body.error.code, 'APPROVAL_LIMIT_EXCEEDED');

  await connection.query(`UPDATE users SET approval_limit = NULL WHERE email = 'admin@test.local'`);
});

// ---------------------------------------------------------------------------
// Posting, journal, reversal
// ---------------------------------------------------------------------------

test('approving posts it and the journal lines balance', async () => {
  const created = await createEntry();
  const id = created.body.transaction.id;

  const approved = await api.post(`/transactions/${id}/approve`, {
    token: tokens.owner, headers: idempotencyKey(),
  });
  assert.equal(approved.status, 200);
  assert.ok(approved.body.journalNumber, 'a posted entry carries its book number');

  const journal = await api.get(`/transactions/${id}/journal`, { token: tokens.owner });
  assert.equal(journal.status, 200);
  assert.equal(journal.body.journalNumber, approved.body.journalNumber);

  const debits = journal.body.lines.reduce((sum, line) => sum + Number(line.debit), 0);
  const credits = journal.body.lines.reduce((sum, line) => sum + Number(line.credit), 0);
  assert.equal(debits, credits);
  assert.equal(debits, 560000);
});

test('a posted entry cannot be edited, by anyone', async () => {
  const created = await createEntry();
  const id = created.body.transaction.id;
  await api.post(`/transactions/${id}/approve`, { token: tokens.owner, headers: idempotencyKey() });

  const patched = await api.patch(`/transactions/${id}`, {
    token: tokens.owner,
    body: entry({ description: 'Trying to change a posted entry' }),
  });

  assert.equal(patched.status, 409);
  assert.equal(patched.body.error.code, 'ENTRY_NOT_EDITABLE');
});

test('a draft can be edited and its totals are recomputed', async () => {
  const created = await createEntry();
  const id = created.body.transaction.id;

  const patched = await api.patch(`/transactions/${id}`, {
    token: tokens.owner,
    body: entry({ gross: { minor: 1000000, currency: 'PKR' }, description: 'Changed my mind' }),
  });

  assert.equal(patched.status, 200);
  assert.equal(patched.body.transaction.amount, 1000000);
});

test('reversing needs a reason, and only works once', async () => {
  const created = await createEntry();
  const id = created.body.transaction.id;
  await api.post(`/transactions/${id}/approve`, { token: tokens.owner, headers: idempotencyKey() });

  const noReason = await api.post(`/transactions/${id}/reverse`, {
    token: tokens.owner, body: {}, headers: idempotencyKey(),
  });
  assert.equal(noReason.status, 400);

  const first = await api.post(`/transactions/${id}/reverse`, {
    token: tokens.owner, body: { reason: 'paid on the wrong card' }, headers: idempotencyKey(),
  });
  assert.equal(first.status, 200);

  const second = await api.post(`/transactions/${id}/reverse`, {
    token: tokens.owner, body: { reason: 'again' }, headers: idempotencyKey(),
  });
  assert.equal(second.status, 409);
  assert.equal(second.body.error.code, 'ALREADY_REVERSED');
});

// ---------------------------------------------------------------------------
// The two modules agreeing
// ---------------------------------------------------------------------------

test('posting through the API moves the balance the accounts endpoint reports', async () => {
  const before = await api.get('/accounts', { token: tokens.owner });
  const bankBefore = before.body.accounts.find((a) => a.id === bankId).balance.minor;

  const created = await createEntry(tokens.owner, entry({
    direction: 'out', gross: { minor: 2500000, currency: 'PKR' }, description: 'Office rent',
  }));
  await api.post(`/transactions/${created.body.transaction.id}/approve`, {
    token: tokens.owner, headers: idempotencyKey(),
  });

  const after = await api.get('/accounts', { token: tokens.owner });
  const bankAfter = after.body.accounts.find((a) => a.id === bankId).balance.minor;

  assert.equal(bankAfter, bankBefore - 2500000);
  assert.equal(after.body.accounts[0].balance.currency, 'PKR');
});

test('reading an entry that does not exist is a 404', async () => {
  const response = await api.get('/transactions/999999', { token: tokens.owner });
  assert.equal(response.status, 404);
});

test('none of this works without signing in', async () => {
  assert.equal((await api.get('/accounts')).status, 401);
  assert.equal((await api.post('/transactions', { body: entry(), headers: idempotencyKey() })).status, 401);
});
