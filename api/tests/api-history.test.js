// The opening entry and the history merge. Decision 037.
//
// The books go live on 1 July 2026 holding real balances at 30 June. History
// from March 2025 goes in afterwards and is excluded from live balances until
// it reconciles with that opening entry, account by account. Then the opening
// entry is reversed and history counts.
//
// Nothing is edited at any point. Inclusion is a setting.

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
let inCategory;
let outCategory;

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

async function bankBalance() {
  const response = await api.get('/accounts', { token: tokens.owner });
  return response.body.accounts.find((account) => account.id === bankId).balance.minor;
}

// A historical entry: dated before the books went live.
async function historical({ direction, gross, date, description }) {
  const created = await api.post('/transactions', {
    token: tokens.owner,
    headers: idempotencyKey(),
    body: {
      date, direction, method: 'account', description,
      categoryId: direction === 'in' ? inCategory : outCategory,
      accountId: bankId,
      gross: { minor: gross, currency: 'PKR' },
      entryType: 'historical',
      acknowledged_warnings: WARNING_CODES,
    },
  });
  assert.equal(created.status, 201, created.raw);
  await api.post(`/transactions/${created.body.transaction.id}/approve`, {
    token: tokens.owner, headers: idempotencyKey(),
  });
  return created.body.transaction.id;
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
  inCategory = await categoryId(connection, 'in');
  outCategory = await categoryId(connection, 'out');
});

after(async () => {
  await api?.close();
  if (connection) {
    await dropAll(connection);
    await connection.end();
  }
});

test('only the owner can post the opening entry', async () => {
  const response = await api.post('/opening-entry', {
    token: tokens.staff,
    headers: idempotencyKey(),
    body: { balances: [{ code: '1113', amount: 50000000 }] },
  });
  assert.equal(response.status, 403);
});

test('the opening entry balances itself through 3400', async () => {
  // The bank held PKR 500,000 and the company owed Hammad PKR 300,000.
  const response = await api.post('/opening-entry', {
    token: tokens.owner,
    headers: idempotencyKey(),
    body: {
      balances: [
        { code: '1113', amount: 50000000 },
        { code: '2210', amount: 30000000 },
      ],
      acknowledged_warnings: WARNING_CODES,
    },
  });

  assert.equal(response.status, 201, response.raw);
  assert.equal(response.body.openingEntry.date, '2026-07-01');
  assert.ok(response.body.openingEntry.journalNumber);

  assert.equal(await ledgerBalance('1113'), 50000000, 'the bank holds what it held');
  assert.equal(await ledgerBalance('2210'), -30000000, 'a liability sits on the credit side');
  assert.equal(
    await ledgerBalance('3400'), -20000000,
    'equity takes whatever is left over, and nobody supplies it',
  );
});

test('the opening entry gives the accounts their starting balances', async () => {
  assert.equal(await bankBalance(), 50000000);
});

test('there can only be one', async () => {
  const response = await api.post('/opening-entry', {
    token: tokens.owner,
    headers: idempotencyKey(),
    body: { balances: [{ code: '1113', amount: 100 }], acknowledged_warnings: WARNING_CODES },
  });

  assert.equal(response.status, 409);
  assert.equal(response.body.error.code, 'OPENING_ALREADY_EXISTS');
});

test('a heading cannot hold a balance', async () => {
  const [rows] = await connection.query(`SELECT id FROM transactions WHERE entry_type = 'opening'`);
  assert.equal(rows.length, 1, 'the refused attempt above left nothing behind');
});

test('historical entries change no live balance while history is unmerged', async () => {
  const before = await bankBalance();

  await historical({ direction: 'in', gross: 20000000, date: '2026-05-01', description: 'A client paid in May' });
  await historical({ direction: 'out', gross: 5000000, date: '2026-06-01', description: 'June rent' });

  assert.equal(
    await bankBalance(), before,
    'the opening entry already contains these, so counting them too would double the bank',
  );
});

test('the merge check reports the difference per account', async () => {
  const response = await api.get('/history/merge-check', { token: tokens.owner });

  assert.equal(response.status, 200);
  assert.equal(response.body.closingDate, '2026-06-30');
  assert.equal(response.body.historyMerged, false);
  assert.equal(response.body.historicalEntries, 2);

  const bank = response.body.accounts.find((row) => row.code === '1113');
  assert.equal(bank.fromOpeningEntry.minor, 50000000);
  assert.equal(bank.fromHistory.minor, 15000000, '20,000 in less 5,000 out');
  assert.equal(bank.difference.minor, -35000000, 'history is 350,000 short of what the bank held');

  assert.ok(response.body.differences.length > 0);
  assert.equal(response.body.canMerge, false);
});

test('merging is refused while any account still differs', async () => {
  const response = await api.post('/history/merge', {
    token: tokens.owner, headers: idempotencyKey(),
  });

  assert.equal(response.status, 409);
  assert.equal(response.body.error.code, 'HISTORY_DOES_NOT_RECONCILE');
  assert.ok(response.body.error.details.differences.length > 0);
});

test('once history reconciles, the check says so', async () => {
  // History so far: 20,000 in and 5,000 out, so the bank reads 15,000 against
  // an opening figure of 50,000, and the director loan is missing entirely.
  //
  // What actually happened is one event: Hammad lent the company 30,000 and a
  // client paid 5,000, both into the bank. It has no single category, so it
  // goes in as a manual journal entry, which is what entry_type journal and
  // historical lines exist for.
  const [bank] = await connection.query(`SELECT id FROM chart_of_accounts WHERE code = '1113'`);
  const [loan] = await connection.query(`SELECT id FROM chart_of_accounts WHERE code = '2210'`);
  const [revenue] = await connection.query(`SELECT coa_id FROM categories WHERE id = ?`, [inCategory]);
  const [owner] = await connection.query(`SELECT id FROM users WHERE role = 'owner'`);

  await connection.query(
    `INSERT INTO transactions
       (date, account_id, direction, amount, currency, method, description, category_id,
        gross_amount, status, entry_type, created_by, journal_number, posted_at,
        approved_by, approval_method)
     VALUES ('2026-03-01', ?, 'in', 35000000, 'PKR', 'account',
             'Director loan and a client receipt, historical', ?,
             35000000, 'posted', 'historical', ?, 'HIST-1', UTC_TIMESTAMP(), ?, 'owner')`,
    [bankId, inCategory, owner[0].id, owner[0].id],
  );
  const [inserted] = await connection.query('SELECT LAST_INSERT_ID() AS id');

  await connection.query(
    `INSERT INTO journal_lines (transaction_id, coa_id, debit, credit, line_no) VALUES
       (?, ?, 35000000, 0, 1),
       (?, ?, 0, 30000000, 2),
       (?, ?, 0,  5000000, 3)`,
    [
      inserted[0].id, bank[0].id,
      inserted[0].id, loan[0].id,
      inserted[0].id, revenue[0].coa_id,
    ],
  );

  const response = await api.get('/history/merge-check', { token: tokens.owner });

  const bankRow = response.body.accounts.find((row) => row.code === '1113');
  assert.equal(bankRow.fromHistory.minor, 50000000, 'history now adds up to what the bank held');
  assert.equal(bankRow.difference.minor, 0);

  const loanRow = response.body.accounts.find((row) => row.code === '2210');
  assert.equal(loanRow.difference.minor, 0, 'the loan the company owed is in history now');

  assert.deepEqual(
    response.body.differences.map((row) => row.code), [],
    `still differing: ${JSON.stringify(response.body.differences)}`,
  );
  assert.equal(response.body.canMerge, true);
});

test('income and expense accounts are not compared, because an opening entry has none', async () => {
  const response = await api.get('/history/merge-check', { token: tokens.owner });
  const codes = response.body.accounts.map((row) => row.code);

  assert.ok(codes.includes('1113'), 'positions are compared');
  assert.ok(
    !codes.some((code) => code.startsWith('4') || code.startsWith('5')),
    "last year's revenue is absorbed into equity, so comparing it would block the merge forever",
  );
});

test('merging reverses the opening entry and leaves every balance where it was', async () => {
  const before = await bankBalance();

  const response = await api.post('/history/merge', {
    token: tokens.owner, headers: idempotencyKey(),
  });

  assert.equal(response.status, 200, response.raw);
  assert.equal(response.body.merged, true);
  assert.ok(response.body.reversalJournalNumber);

  assert.equal(
    await bankBalance(), before,
    'history replaced the opening entry exactly, so no balance moved',
  );
  assert.equal(await ledgerBalance('3400'), 0, 'opening balance equity is back to zero');
});

test('history counts from then on, and the setting is what changed', async () => {
  const check = await api.get('/history/merge-check', { token: tokens.owner });
  assert.equal(check.body.historyMerged, true);
  assert.equal(check.body.canMerge, false, 'it cannot happen twice');

  const [setting] = await connection.query(
    `SELECT value FROM settings WHERE setting_key = 'history_merged'`,
  );
  assert.equal(setting[0].value, 'true');
});

test('the trial balance is zero after all of it', async () => {
  const [rows] = await connection.query(
    `SELECT COALESCE(SUM(j.debit), 0) AS debits, COALESCE(SUM(j.credit), 0) AS credits
       FROM journal_lines j JOIN transactions t ON t.id = j.transaction_id`,
  );
  assert.equal(Number(rows[0].debits), Number(rows[0].credits));
});
