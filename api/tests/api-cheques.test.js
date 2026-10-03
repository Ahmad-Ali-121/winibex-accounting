// The cheque register and the petty cash imprest.
//
// The register is a record of what was written and whether it has cleared. It
// posts nothing itself: the money is an ordinary transaction with
// method = cheque, linked to the register entry, so there is never a second
// set of books to reconcile against the first.

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
let pettyId;
let outCategory;
let inCategory;

before(async () => {
  connection = await connect();
  await buildSchema(connection);
  await seedUsers(connection);
  await seedAccounts(connection);
  api = await startServer();

  for (const role of ['owner', 'staff']) {
    tokens[role] = (await signIn(api, `${role}@test.local`)).body.accessToken;
  }

  bankId = await accountId(connection, 'Winibex bank');
  pettyId = await accountId(connection, 'Petty cash');
  outCategory = await categoryId(connection, 'out');
  inCategory = await categoryId(connection, 'in');
});

after(async () => {
  await api?.close();
  if (connection) {
    await dropAll(connection);
    await connection.end();
  }
});

function issue(body, token = tokens.owner) {
  return api.post('/cheques', {
    token,
    body: {
      accountId: bankId,
      chequeNumber: '000101',
      payee: 'A supplier',
      amount: { minor: 5000000, currency: 'PKR' },
      issueDate: '2026-07-05',
      ...body,
    },
  });
}

test('a cheque is recorded as issued', async () => {
  const response = await issue({});

  assert.equal(response.status, 201, response.raw);
  assert.equal(response.body.cheque.status, 'issued');
  assert.equal(response.body.cheque.clearedOn, null);
  assert.equal(response.body.cheque.amount.minor, 5000000);
  assert.equal(response.body.cheque.accountName, 'Winibex bank');
});

test('a cheque number cannot be reused on the same account', async () => {
  const response = await issue({ chequeNumber: '000101', payee: 'Someone else' });
  assert.notEqual(response.status, 201);
});

test('the same number on a different account is fine', async () => {
  const response = await issue({ accountId: pettyId, chequeNumber: '000101' });
  assert.equal(response.status, 201);
});

test('a cheque moves forward through the register', async () => {
  const created = await issue({ chequeNumber: '000102' });
  const id = created.body.cheque.id;

  const presented = await api.patch(`/cheques/${id}/status`, {
    token: tokens.owner, body: { status: 'presented' },
  });
  assert.equal(presented.body.cheque.status, 'presented');

  const cleared = await api.patch(`/cheques/${id}/status`, {
    token: tokens.owner, body: { status: 'cleared', clearedOn: '2026-07-09' },
  });
  assert.equal(cleared.body.cheque.status, 'cleared');
  assert.equal(String(cleared.body.cheque.clearedOn).slice(0, 10), '2026-07-09');
});

test('clearing without a date is refused, since reconciliation needs it', async () => {
  const created = await issue({ chequeNumber: '000103' });
  await api.patch(`/cheques/${created.body.cheque.id}/status`, {
    token: tokens.owner, body: { status: 'presented' },
  });

  const response = await api.patch(`/cheques/${created.body.cheque.id}/status`, {
    token: tokens.owner, body: { status: 'cleared' },
  });

  assert.equal(response.status, 400);
  assert.equal(response.body.error.field, 'clearedOn');
});

test('a cleared cheque cannot be cancelled afterwards', async () => {
  const created = await issue({ chequeNumber: '000104' });
  const id = created.body.cheque.id;

  await api.patch(`/cheques/${id}/status`, { token: tokens.owner, body: { status: 'presented' } });
  await api.patch(`/cheques/${id}/status`, {
    token: tokens.owner, body: { status: 'cleared', clearedOn: '2026-07-09' },
  });

  const response = await api.patch(`/cheques/${id}/status`, {
    token: tokens.owner, body: { status: 'cancelled' },
  });

  assert.equal(response.status, 409);
  assert.ok(/cleared cheque cannot become cancelled/i.test(response.body.error.message));
});

test('an issued cheque can be cancelled or bounced', async () => {
  const cancelled = await issue({ chequeNumber: '000105' });
  const one = await api.patch(`/cheques/${cancelled.body.cheque.id}/status`, {
    token: tokens.owner, body: { status: 'cancelled' },
  });
  assert.equal(one.body.cheque.status, 'cancelled');

  const bounced = await issue({ chequeNumber: '000106' });
  const two = await api.patch(`/cheques/${bounced.body.cheque.id}/status`, {
    token: tokens.owner, body: { status: 'bounced' },
  });
  assert.equal(two.body.cheque.status, 'bounced');
});

test('the register shows what is still outstanding', async () => {
  const response = await api.get(`/cheques?accountId=${bankId}`, { token: tokens.owner });

  assert.equal(response.status, 200);
  const outstanding = response.body.cheques
    .filter((cheque) => cheque.status === 'issued' || cheque.status === 'presented')
    .reduce((sum, cheque) => sum + cheque.amount.minor, 0);

  assert.equal(response.body.outstanding.minor, outstanding);
  assert.ok(response.body.outstanding.minor > 0, 'cheques written but not yet taken by the bank');
});

test('a cheque links to the payment it represents', async () => {
  const created = await issue({ chequeNumber: '000107' });

  const payment = await api.post('/transactions', {
    token: tokens.owner,
    headers: idempotencyKey(),
    body: {
      date: '2026-07-05', direction: 'out', method: 'cheque',
      description: 'Paid a supplier by cheque', categoryId: outCategory,
      accountId: bankId, gross: { minor: 5000000, currency: 'PKR' },
      reference: '000107', acknowledged_warnings: WARNING_CODES,
    },
  });
  await api.post(`/transactions/${payment.body.transaction.id}/approve`, {
    token: tokens.owner, headers: idempotencyKey(),
  });

  const linked = await api.patch(`/cheques/${created.body.cheque.id}/transaction`, {
    token: tokens.owner, body: { transactionId: payment.body.transaction.id },
  });

  assert.equal(linked.status, 200);
  assert.equal(linked.body.cheque.transactionId, payment.body.transaction.id);
  assert.ok(linked.body.cheque.journalNumber, 'the register points at a real posted entry');
});

test('staff can read the register but not write to it', async () => {
  assert.equal((await api.get('/cheques', { token: tokens.staff })).status, 200);
  assert.equal((await issue({ chequeNumber: '000108' }, tokens.staff)).status, 403);
});

// ---------------------------------------------------------------------------
// Petty cash imprest
// ---------------------------------------------------------------------------

test('petty cash reports how far below its float it is', async () => {
  await connection.query(
    `UPDATE settings SET value = '1000000' WHERE setting_key = 'petty_cash_imprest'`,
  );

  const empty = await api.get('/accounts/petty-cash', { token: tokens.owner });
  assert.equal(empty.status, 200);
  assert.equal(empty.body.imprest.minor, 1000000, 'the float is a setting, not a constant');

  const account = empty.body.accounts.find((row) => row.name === 'Petty cash');
  assert.equal(account.balance.minor, 0);
  assert.equal(account.belowFloat, true);
  assert.equal(account.suggestedTopUp.minor, 1000000, 'draw the whole float');
});

test('topping petty cash up reduces what it suggests drawing', async () => {
  const funded = await api.post('/transactions', {
    token: tokens.owner,
    headers: idempotencyKey(),
    body: {
      date: '2026-07-05', direction: 'in', method: 'cash',
      description: 'Petty cash top up', categoryId: inCategory,
      accountId: pettyId, gross: { minor: 600000, currency: 'PKR' },
      acknowledged_warnings: WARNING_CODES,
    },
  });
  await api.post(`/transactions/${funded.body.transaction.id}/approve`, {
    token: tokens.owner, headers: idempotencyKey(),
  });

  const response = await api.get('/accounts/petty-cash', { token: tokens.owner });
  const account = response.body.accounts.find((row) => row.name === 'Petty cash');

  assert.equal(account.balance.minor, 600000);
  assert.equal(account.suggestedTopUp.minor, 400000, 'what is left to restore the float');
  assert.equal(account.belowFloat, true);
});

test('petty cash at its float suggests nothing', async () => {
  await connection.query(
    `UPDATE settings SET value = '600000' WHERE setting_key = 'petty_cash_imprest'`,
  );

  const response = await api.get('/accounts/petty-cash', { token: tokens.owner });
  const account = response.body.accounts.find((row) => row.name === 'Petty cash');

  assert.equal(account.belowFloat, false);
  assert.equal(account.suggestedTopUp.minor, 0);
});

test('the register needs a login', async () => {
  assert.equal((await api.get('/cheques')).status, 401);
  assert.equal((await api.get('/accounts/petty-cash')).status, 401);
});
