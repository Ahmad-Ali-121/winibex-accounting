// Transfers between company accounts.
//
// Two rows, one group id, each balanced on its own through 1118 Funds in
// transit. The test that matters most is the last one: once both legs are
// posted, 1118 is back at zero. If it is not, money is sitting in a clearing
// account and one of the two accounts is wrong.

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
let cashId;
let pettyId;
let inCategory;

async function ledgerBalance(code) {
  const [rows] = await connection.query(
    `SELECT COALESCE(SUM(j.debit - j.credit), 0) AS balance
       FROM journal_lines j
       JOIN transactions t ON t.id = j.transaction_id
       JOIN chart_of_accounts a ON a.id = j.coa_id
      WHERE a.code = ? AND t.status IN ('posted', 'reversed')`,
    [code],
  );
  return Number(rows[0].balance);
}

async function accountBalance(id) {
  const response = await api.get('/accounts', { token: tokens.owner });
  return response.body.accounts.find((account) => account.id === id).balance.minor;
}

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
  cashId = await accountId(connection, 'Office cash');
  pettyId = await accountId(connection, 'Petty cash');
  inCategory = await categoryId(connection, 'in');

  // Fund the bank, so a transfer out of it is not fighting an empty account.
  const funded = await api.post('/transactions', {
    token: tokens.owner,
    headers: idempotencyKey(),
    body: {
      date: '2026-07-02', direction: 'in', method: 'account',
      description: 'Opening funds for the bank', categoryId: inCategory,
      accountId: bankId, gross: { minor: 50000000, currency: 'PKR' },
      acknowledged_warnings: WARNING_CODES,
    },
  });
  await api.post(`/transactions/${funded.body.transaction.id}/approve`, {
    token: tokens.owner, headers: idempotencyKey(),
  });
});

after(async () => {
  await api?.close();
  if (connection) {
    await dropAll(connection);
    await connection.end();
  }
});

function transfer(body) {
  return api.post('/transfers', {
    token: tokens.owner,
    headers: idempotencyKey(),
    body: { acknowledged_warnings: WARNING_CODES, ...body },
  });
}

test('a transfer moves money between two accounts and creates two linked legs', async () => {
  const bankBefore = await accountBalance(bankId);
  const cashBefore = await accountBalance(cashId);

  const response = await transfer({
    date: '2026-07-05',
    fromAccountId: bankId,
    toAccountId: cashId,
    amount: { minor: 5000000, currency: 'PKR' },
    description: 'Office cash top up',
  });

  assert.equal(response.status, 201, response.raw);
  assert.ok(response.body.transfer.transferGroupId);
  assert.ok(response.body.transfer.from.journalNumber);
  assert.ok(response.body.transfer.to.journalNumber);
  assert.notEqual(
    response.body.transfer.from.journalNumber,
    response.body.transfer.to.journalNumber,
    'each leg is its own entry in the book',
  );

  assert.equal(await accountBalance(bankId), bankBefore - 5000000);
  assert.equal(await accountBalance(cashId), cashBefore + 5000000);
});

test('both legs share one group id and can be read back together', async () => {
  const created = await transfer({
    date: '2026-07-06', fromAccountId: bankId, toAccountId: pettyId,
    amount: { minor: 1000000, currency: 'PKR' },
  });

  const group = await api.get(`/transfers/${created.body.transfer.transferGroupId}`, {
    token: tokens.owner,
  });

  assert.equal(group.status, 200);
  assert.equal(group.body.legs.length, 2);
  assert.deepEqual(group.body.legs.map((leg) => leg.direction).sort(), ['in', 'out']);
  assert.ok(group.body.legs.every((leg) => leg.status === 'posted'));
});

test('a transfer to the same account is refused', async () => {
  const response = await transfer({
    date: '2026-07-05', fromAccountId: bankId, toAccountId: bankId,
    amount: { minor: 100000, currency: 'PKR' },
  });

  assert.equal(response.status, 400);
  assert.equal(response.body.error.code, 'TRANSFER_SAME_ACCOUNT');
});

test('a bank fee is recorded, so the two legs are allowed to differ', async () => {
  const bankBefore = await accountBalance(bankId);
  const cashBefore = await accountBalance(cashId);

  const response = await transfer({
    date: '2026-07-07', fromAccountId: bankId, toAccountId: cashId,
    amount: { minor: 2000000, currency: 'PKR' },
    fee: { minor: 5000, currency: 'PKR' },
    description: 'Cash withdrawal with a bank fee',
  });

  assert.equal(response.status, 201);
  assert.equal(await accountBalance(bankId), bankBefore - 2005000, 'the fee leaves the bank too');
  assert.equal(await accountBalance(cashId), cashBefore + 2000000, 'the destination receives the amount');
  assert.equal(await ledgerBalance('8100'), 5000, 'the fee is a cost, not a disappearance');
});

test('staff cannot move money between accounts', async () => {
  const response = await api.post('/transfers', {
    token: tokens.staff,
    headers: idempotencyKey(),
    body: {
      date: '2026-07-05', fromAccountId: bankId, toAccountId: cashId,
      amount: { minor: 100000, currency: 'PKR' },
      acknowledged_warnings: WARNING_CODES,
    },
  });

  assert.equal(response.status, 403);
});

test('a transfer out of cash the company does not have is blocked, and neither leg survives', async () => {
  const [before] = await connection.query('SELECT COUNT(*) AS n FROM transactions');

  const response = await transfer({
    date: '2026-07-08', fromAccountId: pettyId, toAccountId: bankId,
    amount: { minor: 99000000, currency: 'PKR' },
  });

  assert.equal(response.status, 400);
  assert.equal(response.body.error.code, 'CASH_BELOW_ZERO');

  const [after] = await connection.query('SELECT COUNT(*) AS n FROM transactions');
  assert.equal(
    Number(after[0].n), Number(before[0].n),
    'a failed transfer left half of itself behind',
  );
});

// The one that matters.
test('funds in transit is back at zero once both legs are posted', async () => {
  assert.equal(
    await ledgerBalance('1118'), 0,
    'money is sitting in the clearing account, so one of the two accounts is wrong',
  );
});

test('the trial balance is zero', async () => {
  const [rows] = await connection.query(
    `SELECT COALESCE(SUM(j.debit), 0) AS debits, COALESCE(SUM(j.credit), 0) AS credits
       FROM journal_lines j JOIN transactions t ON t.id = j.transaction_id`,
  );
  assert.equal(Number(rows[0].debits), Number(rows[0].credits));
});
