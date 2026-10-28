// What the batch C screens need from the server. Decision 065.
//
//   - the opening entry screen reads the accounts a balance can be given for,
//     and the entry once it exists
//   - reversing either leg of a transfer reverses the whole transfer
//   - a reversal cannot be reversed again
//   - the opening entry is reversed only by merging history

import test, { before, after } from 'node:test';
import assert from 'node:assert/strict';

import {
  connect, dropAll, buildSchema, seedUsers, seedAccounts,
  startServer, signIn, accountId, idempotencyKey,
} from './helpers/api.js';
import { businessToday } from '../core/dates.js';
import { WARNING_CODES } from '../modules/transactions/validation.js';

let connection;
let api;
let token;
let today;
let bankId;
let cashId;

const pkr = (minor) => ({ minor, currency: 'PKR' });

async function balanceOf(code) {
  const [rows] = await connection.query(
    `SELECT COALESCE(SUM(j.debit - j.credit), 0) AS net
       FROM journal_lines j
       JOIN transactions t ON t.id = j.transaction_id
       JOIN chart_of_accounts a ON a.id = j.coa_id
      WHERE a.code = ? AND t.status IN ('posted', 'reversed')`,
    [code],
  );
  return Number(rows[0].net);
}

before(async () => {
  connection = await connect();
  await buildSchema(connection);
  await seedUsers(connection);
  await seedAccounts(connection);
  api = await startServer();
  token = (await signIn(api, 'owner@test.local')).body.accessToken;
  today = businessToday();
  bankId = await accountId(connection, 'Winibex bank');
  cashId = await accountId(connection, 'Office cash');
});

after(async () => {
  await api?.close();
  if (connection) {
    await dropAll(connection);
    await connection.end();
  }
});

// --- the opening entry screen ------------------------------------------------

test('065: before the opening entry, the screen gets the accounts a balance can be given for', async () => {
  const response = await api.get('/opening-entry', { token });
  assert.equal(response.status, 200, response.raw);
  assert.equal(response.body.entry, null);
  assert.equal(response.body.balancesAt, '2026-06-30');

  const codes = response.body.accounts.map((account) => account.code);
  assert.ok(codes.includes('1113'), 'the bank can be given a balance');
  assert.ok(!codes.includes('3400'), '3400 takes the balancing figure, nobody types it');
  assert.ok(!codes.includes('1118'), 'funds in transit never holds an opening balance');
  for (const account of response.body.accounts) {
    assert.ok(['asset', 'liability', 'equity'].includes(account.type), `${account.code} is not a balance sheet account`);
  }
});

test('065: after the opening entry, the screen gets the entry, read only', async () => {
  const posted = await api.post('/opening-entry', {
    token, headers: idempotencyKey(),
    body: { balances: [{ code: '1113', amount: 50000000 }, { code: '1111', amount: 5000000 }] },
  });
  assert.equal(posted.status, 201, posted.raw);

  const response = await api.get('/opening-entry', { token });
  assert.equal(response.status, 200, response.raw);
  assert.ok(response.body.entry, 'the entry is there');
  assert.equal(response.body.entry.status, 'posted');

  const codes = response.body.entry.lines.map((line) => line.code);
  assert.ok(codes.includes('1113'));
  assert.ok(codes.includes('3400'), 'the balancing figure is shown too');
});

test('065: the opening entry cannot be reversed by hand', async () => {
  const info = await api.get('/opening-entry', { token });
  const response = await api.post(`/transactions/${info.body.entry.transactionId}/reverse`, {
    token, headers: idempotencyKey(), body: { reason: 'Wrong bank balance' },
  });
  assert.equal(response.status, 409, response.raw);
  assert.match(response.body.error.message, /only when history is merged/);
});

// --- transfers ---------------------------------------------------------------

test('065: reversing one leg of a transfer reverses the whole transfer', async () => {
  const moved = await api.post('/transfers', {
    token, headers: idempotencyKey(),
    body: {
      date: today, fromAccountId: bankId, toAccountId: cashId,
      amount: pkr(2000000), fee: pkr(5000), description: 'Cash for the office',
      acknowledged_warnings: WARNING_CODES,
    },
  });
  assert.equal(moved.status, 201, moved.raw);
  const { from, to } = moved.body.transfer;

  const bankBefore = await balanceOf('1113');
  const cashBefore = await balanceOf('1111');

  const reversed = await api.post(`/transactions/${to.transactionId}/reverse`, {
    token, headers: idempotencyKey(), body: { reason: 'Wrong account' },
  });
  assert.equal(reversed.status, 200, reversed.raw);
  assert.equal(reversed.body.legs.length, 2, 'both legs reversed');

  const [rows] = await connection.query(
    'SELECT status FROM transactions WHERE id IN (?, ?)', [from.transactionId, to.transactionId],
  );
  assert.deepEqual(rows.map((row) => row.status), ['reversed', 'reversed']);

  assert.equal(await balanceOf('1118'), 0, 'nothing left in transit');
  assert.equal(await balanceOf('1113') - bankBefore, 2005000, 'the bank gets the money and the fee back');
  assert.equal(await balanceOf('1111') - cashBefore, -2000000, 'the cash comes back out');
});

// --- a reversal is not reversed --------------------------------------------

test('065: a reversal cannot itself be reversed', async () => {
  const [categories] = await connection.query(
    `SELECT c.id FROM categories c JOIN chart_of_accounts a ON a.id = c.coa_id
      WHERE c.direction = 'out' AND c.is_active = 1 AND a.type = 'expense' ORDER BY a.code LIMIT 1`,
  );
  const created = await api.post('/transactions', {
    token, headers: idempotencyKey(),
    body: {
      date: today, direction: 'out', method: 'online', description: 'Printer paper',
      categoryId: Number(categories[0].id), accountId: bankId, gross: pkr(150000),
      acknowledged_warnings: WARNING_CODES,
    },
  });
  assert.equal(created.status, 201, created.raw);
  const id = created.body.transaction.id;
  const approved = await api.post(`/transactions/${id}/approve`, { token, headers: idempotencyKey() });
  assert.equal(approved.status, 200, approved.raw);

  const first = await api.post(`/transactions/${id}/reverse`, {
    token, headers: idempotencyKey(), body: { reason: 'Entered twice' },
  });
  assert.equal(first.status, 200, first.raw);

  const again = await api.post(`/transactions/${first.body.reversalId}/reverse`, {
    token, headers: idempotencyKey(), body: { reason: 'Undo the undo' },
  });
  assert.equal(again.status, 409, again.raw);
  assert.match(again.body.error.message, /itself a reversal/);
});
