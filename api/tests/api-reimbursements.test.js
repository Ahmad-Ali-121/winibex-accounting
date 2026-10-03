// Paid by a person, and paying them back.
//
// Worked example 1b in docs/CHART-OF-ACCOUNTS.md: Ahmad buys the subscription
// on his own card, so the company owes him rather than the bank being lighter.
// These prove the payable builds up, is visible, and clears exactly.

import test, { before, after } from 'node:test';
import assert from 'node:assert/strict';

import {
  connect, dropAll, buildSchema, seedUsers, seedAccounts,
  startServer, signIn, accountId, categoryId, userId, idempotencyKey,
} from './helpers/api.js';
import { WARNING_CODES } from '../modules/transactions/validation.js';

let connection;
let api;
const tokens = {};
let bankId;
let subscriptionCategory;
let ahmadId;

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
  subscriptionCategory = await categoryId(connection, 'out');
  ahmadId = await userId(connection, 'staff@test.local');

  // A reimbursement debits 2114, so a category has to point at it. If the
  // seed in migration 002 has one this finds it; if not, this creates it and
  // the test below says so.
  const [existing] = await connection.query(
    `SELECT c.id FROM categories c JOIN chart_of_accounts a ON a.id = c.coa_id WHERE a.code = '2114'`,
  );
  if (existing.length === 0) {
    await connection.query(
      `INSERT INTO categories (name, main_head, direction, coa_id, is_active)
       SELECT 'Reimbursement to a person', 'balance_sheet', 'out', id, 1
         FROM chart_of_accounts WHERE code = '2114'`,
    );
  }
});

after(async () => {
  await api?.close();
  if (connection) {
    await dropAll(connection);
    await connection.end();
  }
});

// A cost Ahmad paid on his own card, posted.
async function personalCost(minor, description) {
  const created = await api.post('/transactions', {
    token: tokens.owner,
    headers: idempotencyKey(),
    body: {
      date: '2026-07-05',
      direction: 'out',
      method: 'card',
      description,
      categoryId: subscriptionCategory,
      accountId: null,
      paidByType: 'person',
      paidByUserId: ahmadId,
      gross: { minor, currency: 'PKR' },
      acknowledged_warnings: WARNING_CODES,
    },
  });
  assert.equal(created.status, 201, created.raw);

  await api.post(`/transactions/${created.body.transaction.id}/approve`, {
    token: tokens.owner, headers: idempotencyKey(),
  });
  return created.body.transaction.id;
}

async function owedTo(id) {
  const response = await api.get('/people/balances', { token: tokens.owner });
  const person = response.body.people.find((p) => p.userId === id);
  return person ? person.owed.minor : 0;
}

test('a cost paid personally never touches a company account', async () => {
  const id = await personalCost(595300, 'Claude subscription on a personal card');

  const detail = await api.get(`/transactions/${id}`, { token: tokens.owner });
  assert.equal(detail.body.transaction.account_id, null, 'no company money moved');

  const lines = detail.body.lines;
  const credit = lines.find((line) => Number(line.credit) > 0);
  const [payable] = await connection.query(`SELECT id FROM chart_of_accounts WHERE code = '2114'`);
  assert.equal(Number(credit.coa_id), Number(payable[0].id), 'the company owes a person, not the bank');
});

test('what the company owes is visible per person', async () => {
  assert.equal(await owedTo(ahmadId), 595300);

  await personalCost(1200000, 'Domain renewals on a personal card');
  assert.equal(await owedTo(ahmadId), 1795300);
});

test('the outstanding list names the costs behind the figure', async () => {
  const response = await api.get(`/people/${ahmadId}/outstanding`, { token: tokens.owner });

  assert.equal(response.status, 200);
  assert.equal(response.body.items.length, 2);
  assert.equal(response.body.owed.minor, 1795300);
  assert.ok(response.body.items[0].journalNumber, 'a posted cost carries its book number');
  assert.equal(response.body.items[0].remaining.minor, response.body.items[0].amount.minor);
});

test('paying back more than is owed is refused', async () => {
  const outstanding = await api.get(`/people/${ahmadId}/outstanding`, { token: tokens.owner });
  const first = outstanding.body.items[0];

  const response = await api.post('/reimbursements', {
    token: tokens.owner,
    headers: idempotencyKey(),
    body: {
      personUserId: ahmadId,
      accountId: bankId,
      date: '2026-07-10',
      items: [{ transactionId: first.transactionId, amount: { minor: 99000000, currency: 'PKR' } }],
      acknowledged_warnings: WARNING_CODES,
    },
  });

  assert.equal(response.status, 400);
  assert.equal(response.body.error.code, 'REIMBURSEMENT_EXCEEDS_OWED');
  assert.ok(/outstanding amount/i.test(response.body.error.message));
});

test('staff cannot pay themselves back', async () => {
  const outstanding = await api.get(`/people/${ahmadId}/outstanding`, { token: tokens.owner });

  const response = await api.post('/reimbursements', {
    token: tokens.staff,
    headers: idempotencyKey(),
    body: {
      personUserId: ahmadId,
      accountId: bankId,
      date: '2026-07-10',
      items: [{
        transactionId: outstanding.body.items[0].transactionId,
        amount: { minor: 100000, currency: 'PKR' },
      }],
      acknowledged_warnings: WARNING_CODES,
    },
  });

  assert.equal(response.status, 403);
});

test('a reimbursement clears the payable and leaves a posted payment behind', async () => {
  const outstanding = await api.get(`/people/${ahmadId}/outstanding`, { token: tokens.owner });
  const owedBefore = outstanding.body.owed.minor;

  const response = await api.post('/reimbursements', {
    token: tokens.owner,
    headers: idempotencyKey(),
    body: {
      personUserId: ahmadId,
      accountId: bankId,
      date: '2026-07-10',
      note: 'Reimbursing Ahmad for July',
      items: outstanding.body.items.map((item) => ({
        transactionId: item.transactionId,
        amount: { minor: item.remaining.minor, currency: 'PKR' },
      })),
      acknowledged_warnings: WARNING_CODES,
    },
  });

  assert.equal(response.status, 201, response.raw);
  assert.equal(response.body.reimbursement.amount.minor, owedBefore);
  assert.equal(response.body.reimbursement.owedAfter.minor, 0);
  assert.ok(response.body.reimbursement.journalNumber, 'the payment is a posted entry like any other');

  assert.equal(await owedTo(ahmadId), 0, 'the payable did not clear');
});

test('the payment debits the payable and credits the bank', async () => {
  const [rows] = await connection.query(
    `SELECT t.id FROM reimbursements r JOIN transactions t ON t.id = r.transaction_id
      ORDER BY r.id DESC LIMIT 1`,
  );
  const detail = await api.get(`/transactions/${rows[0].id}`, { token: tokens.owner });

  const [payable] = await connection.query(`SELECT id FROM chart_of_accounts WHERE code = '2114'`);
  const [bank] = await connection.query(`SELECT id FROM chart_of_accounts WHERE code = '1113'`);

  const debit = detail.body.lines.find((line) => Number(line.debit) > 0);
  const credit = detail.body.lines.find((line) => Number(line.credit) > 0);

  assert.equal(Number(debit.coa_id), Number(payable[0].id));
  assert.equal(Number(credit.coa_id), Number(bank[0].id));
  assert.equal(Number(debit.debit), Number(credit.credit));
});

test('a cost already paid back cannot be paid back twice', async () => {
  const outstanding = await api.get(`/people/${ahmadId}/outstanding`, { token: tokens.owner });
  assert.equal(outstanding.body.items.length, 0, 'nothing should be left outstanding');
});

test('the trial balance is still zero', async () => {
  const [rows] = await connection.query(
    `SELECT COALESCE(SUM(j.debit), 0) AS debits, COALESCE(SUM(j.credit), 0) AS credits
       FROM journal_lines j JOIN transactions t ON t.id = j.transaction_id`,
  );
  assert.equal(Number(rows[0].debits), Number(rows[0].credits));
});

test('balances need a login', async () => {
  assert.equal((await api.get('/people/balances')).status, 401);
});
