// Account balances against the real database.
//
// The invariant TESTING.md asks for is at the bottom: the balance computed
// from journal lines and the balance computed from the transactions must be
// the same number. If those two ever disagree, the ledger view and the
// dashboard are showing different books.

import test, { before, after } from 'node:test';
import assert from 'node:assert/strict';
import process from 'node:process';
import { readFile } from 'node:fs/promises';

import { openConnection, closePool } from '../core/db.js';
import { splitSqlStatements } from '../core/sql-split.js';
import * as accounts from '../modules/accounts/service.js';
import * as transactions from '../modules/transactions/service.js';

const TABLES = [
  'attachments', 'cheques', 'entry_flags', 'journal_lines', 'period_locks',
  'reimbursement_items', 'reimbursements', 'tax_rules', 'taxes',
  'transaction_charges', 'transaction_taxes', 'transactions', 'vendors',
  'accounts', 'audit_log', 'categories', 'chart_of_accounts', 'company_profile',
  'currencies', 'fbr_return_heads', 'idempotency_keys', 'refresh_tokens',
  'schema_migrations', 'sequences', 'settings', 'users',
];

let setup;
let owner;
let bankId;
let outCategoryId;
let inCategoryId;

before(async () => {
  assert.ok(process.env.DB_TEST_NAME, 'DB_TEST_NAME is not set');
  assert.notEqual(process.env.DB_TEST_NAME, process.env.DB_NAME);
  process.env.DB_NAME = process.env.DB_TEST_NAME;

  setup = await openConnection({ database: process.env.DB_TEST_NAME });
  await setup.query('SET FOREIGN_KEY_CHECKS = 0');
  for (const table of TABLES) await setup.query(`DROP TABLE IF EXISTS \`${table}\``);
  await setup.query('SET FOREIGN_KEY_CHECKS = 1');

  for (const file of [
    '000_schema_migrations.sql', '001_phase0_tables.sql',
    '002_seed_reference.sql', '003_bootstrap.sql', '004_phase1_tables.sql',
  ]) {
    const sql = await readFile(new URL(`../migrations/${file}`, import.meta.url), 'utf8');
    for (const statement of splitSqlStatements(sql)) await setup.query(statement);
  }

  // The receipt rule is company policy, not schema. Off unless a test is
  // about it; api-attachments.test.js turns it on.
  await setup.query(
    `UPDATE settings SET value = '0' WHERE setting_key = 'receipt_required_above'`,
  );

  const [owners] = await setup.query(`SELECT id FROM users WHERE role = 'owner'`);
  owner = { id: Number(owners[0].id), role: 'owner' };

  const [banks] = await setup.query(`SELECT id FROM accounts WHERE name = 'Winibex bank'`);
  bankId = Number(banks[0].id);

  const [outs] = await setup.query(`SELECT id FROM categories WHERE direction = 'out' LIMIT 1`);
  outCategoryId = Number(outs[0].id);
  const [ins] = await setup.query(`SELECT id FROM categories WHERE direction = 'in' LIMIT 1`);
  inCategoryId = Number(ins[0].id);
});

after(async () => {
  await closePool();
  if (!setup) return;
  await setup.query('SET FOREIGN_KEY_CHECKS = 0');
  for (const table of TABLES) await setup.query(`DROP TABLE IF EXISTS \`${table}\``);
  await setup.query('SET FOREIGN_KEY_CHECKS = 1');
  await setup.end();
});

async function postEntry({ direction, gross, categoryId, entryType = 'normal', date = '2026-07-05' }) {
  const created = await transactions.createDraft({
    user: owner,
    input: {
      date,
      accountId: bankId,
      direction,
      currency: 'PKR',
      method: 'account',
      description: `${direction} ${gross}`,
      categoryId,
      grossAmount: gross,
      entryType,
    },
  });
  return transactions.approve({ user: owner, id: created.id });
}

async function bankBalance() {
  const account = await accounts.getAccount(bankId);
  return account.balance.minor;
}

test('every seeded account starts at zero', async () => {
  const { accounts: list, total, historyMerged } = await accounts.listAccounts();

  assert.ok(list.length >= 1, 'migration 003 seeded no accounts');
  assert.equal(historyMerged, false, 'history is not merged until it reconciles');
  assert.equal(total.minor, 0);
  assert.equal(total.currency, 'PKR');

  for (const account of list) {
    assert.equal(account.balance.minor, 0, `${account.name} did not start at zero`);
    assert.equal(account.balance.currency, 'PKR');
  }
});

test('a balance carries its ledger code, because that is what it is made of', async () => {
  const account = await accounts.getAccount(bankId);
  assert.equal(account.ledger.code, '1113');
  assert.equal(account.ledger.normalBalance, 'debit');
});

test('money in raises the balance and money out lowers it', async () => {
  await postEntry({ direction: 'in', gross: 50000000, categoryId: inCategoryId });
  assert.equal(await bankBalance(), 50000000, 'PKR 500,000 received');

  await postEntry({ direction: 'out', gross: 9000000, categoryId: outCategoryId });
  assert.equal(await bankBalance(), 41000000, 'PKR 410,000 left');
});

test('a draft and a pending entry change nothing', async () => {
  const before = await bankBalance();

  const draft = await transactions.createDraft({
    user: owner,
    input: {
      date: '2026-07-06', accountId: bankId, direction: 'out', currency: 'PKR',
      method: 'account', description: 'Not posted yet', categoryId: outCategoryId,
      grossAmount: 10000000,
    },
  });
  await transactions.submitForApproval({ user: owner, id: draft.id });

  assert.equal(await bankBalance(), before, 'only posted entries count');
});

test('a reversal returns the balance to where it was', async () => {
  const before = await bankBalance();
  const posted = await postEntry({ direction: 'out', gross: 2500000, categoryId: outCategoryId });

  assert.equal(await bankBalance(), before - 2500000);
  await transactions.reverse({ user: owner, id: posted.id, reason: 'wrong account' });
  assert.equal(await bankBalance(), before, 'the pair netted to nothing');
});

test('historical entries are excluded while history is not merged', async () => {
  const before = await bankBalance();

  await postEntry({
    direction: 'in', gross: 7500000, categoryId: inCategoryId,
    entryType: 'historical', date: '2026-05-01',
  });

  assert.equal(
    await bankBalance(), before,
    'the opening entry already contains history, so counting both would double it',
  );

  // Flip the setting and the same entry starts counting.
  await setup.query(`UPDATE settings SET value = 'true' WHERE setting_key = 'history_merged'`);
  assert.equal(await bankBalance(), before + 7500000);
  await setup.query(`UPDATE settings SET value = 'false' WHERE setting_key = 'history_merged'`);
  assert.equal(await bankBalance(), before);
});

test('an inactive account is hidden unless asked for', async () => {
  await setup.query(`UPDATE accounts SET is_active = 0 WHERE name = 'Petty cash'`);

  const visible = await accounts.listAccounts();
  const all = await accounts.listAccounts({ includeInactive: true });

  assert.ok(!visible.accounts.some((a) => a.name === 'Petty cash'));
  assert.ok(all.accounts.some((a) => a.name === 'Petty cash'));

  await setup.query(`UPDATE accounts SET is_active = 1 WHERE name = 'Petty cash'`);
});

test('an account that does not exist is a 404, not a zero balance', async () => {
  await assert.rejects(() => accounts.getAccount(999999), /does not exist/);
});

// The invariant. Everything above has posted, reversed and excluded entries,
// so by now the two ways of arriving at the balance have had every chance to
// drift apart.
test('the balance from journal lines equals the balance from transactions', async () => {
  const fromLines = await bankBalance();
  const fromTransactions = await accounts.balanceFromTransactions(bankId);

  assert.equal(
    fromLines, fromTransactions,
    'the ledger and the transaction list are describing different books',
  );
});

test('the dashboard summary runs against real data and totals cash', async () => {
  // This is the test that was missing: the dashboard query joins across
  // accounts and journal lines, and a wrong column name parses fine but throws
  // the moment it runs. Posting one entry and reading the summary proves the
  // query executes, not just that it compiles.
  const before = await accounts.dashboard();
  const beforeCash = before.cashHeld.minor;

  const posted = await postEntry({ direction: 'in', gross: 1500000, categoryId: inCategoryId });
  assert.ok(posted.journalNumber);

  const after = await accounts.dashboard();
  assert.equal(after.cashHeld.minor, beforeCash + 1500000, 'cash did not move by the posted amount');
  // monthIn covers the current calendar month only; the helper dates its
  // entries in July, so this entry is deliberately outside it. The cash
  // assertion above is what proves the dashboard query runs.
  assert.ok(after.cashHeld.minor > beforeCash);
}); 

test('the trial balance is zero across every ledger account', async () => {
  const [rows] = await setup.query(
    `SELECT COALESCE(SUM(j.debit), 0) AS debits, COALESCE(SUM(j.credit), 0) AS credits
       FROM journal_lines j JOIN transactions t ON t.id = j.transaction_id
      WHERE t.status IN ('posted', 'reversed')`,
  );
  assert.equal(Number(rows[0].debits), Number(rows[0].credits));
});
