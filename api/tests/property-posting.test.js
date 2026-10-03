// The property test. docs/TESTING.md asks for this one by name.
//
// Every other test checks a case somebody thought of. This one generates a few
// hundred valid operations in a random order and checks, after every single
// one, that the books still hold together:
//
//   1. Debits equal credits across the whole ledger
//   2. Every account's balance from journal lines equals its balance worked
//      out from the transactions themselves
//   3. An operation that was refused changed nothing at all
//
// The third is the one that catches a half-finished write. A failure here is
// worth more than a failure anywhere else in the suite, because nobody wrote
// the case: the generator found it.
//
// The seed is printed on every run and can be set with PROPERTY_SEED, so a
// failure is reproducible rather than a story about something that happened
// once on a Tuesday.

import test, { before, after } from 'node:test';
import assert from 'node:assert/strict';
import process from 'node:process';
import { readFile } from 'node:fs/promises';

import { openConnection, closePool } from '../core/db.js';
import { splitSqlStatements } from '../core/sql-split.js';
import * as transactions from '../modules/transactions/service.js';
import * as reimbursements from '../modules/reimbursements/service.js';
import { WARNING_CODES } from '../modules/transactions/validation.js';

const OPERATIONS = Number(process.env.PROPERTY_OPERATIONS ?? 150);
const SEED = Number(process.env.PROPERTY_SEED ?? Math.floor(Math.random() * 2 ** 31));

const TABLES = [
  'attachments', 'cheques', 'entry_flags', 'journal_lines', 'period_locks',
  'reimbursement_items', 'reimbursements', 'tax_rules', 'taxes',
  'transaction_charges', 'transaction_taxes', 'transactions', 'vendors',
  'accounts', 'audit_log', 'categories', 'chart_of_accounts', 'company_profile',
  'currencies', 'fbr_return_heads', 'idempotency_keys', 'refresh_tokens',
  'schema_migrations', 'sequences', 'settings', 'users',
];

// A small deterministic generator. Math.random would make a failure
// unreproducible, which is the one thing a property test cannot afford.
function mulberry32(seed) {
  let state = seed >>> 0;
  return () => {
    state = (state + 0x6d2b79f5) >>> 0;
    let value = Math.imul(state ^ (state >>> 15), 1 | state);
    value = (value + Math.imul(value ^ (value >>> 7), 61 | value)) ^ value;
    return ((value ^ (value >>> 14)) >>> 0) / 4294967296;
  };
}

const random = mulberry32(SEED);
const pick = (items) => items[Math.floor(random() * items.length)];
const between = (low, high) => low + Math.floor(random() * (high - low));

let connection;
let owner;
let accounts = [];
let inCategories = [];
let outCategories = [];
let people = [];

before(async () => {
  assert.ok(process.env.DB_TEST_NAME, 'DB_TEST_NAME is not set');
  assert.notEqual(process.env.DB_TEST_NAME, process.env.DB_NAME);
  process.env.DB_NAME = process.env.DB_TEST_NAME;

  connection = await openConnection({ database: process.env.DB_TEST_NAME });
  await connection.query('SET FOREIGN_KEY_CHECKS = 0');
  for (const table of TABLES) await connection.query(`DROP TABLE IF EXISTS \`${table}\``);
  await connection.query('SET FOREIGN_KEY_CHECKS = 1');

  for (const file of [
    '000_schema_migrations.sql', '001_phase0_tables.sql',
    '002_seed_reference.sql', '003_bootstrap.sql', '004_phase1_tables.sql',
  ]) {
    const sql = await readFile(new URL(`../migrations/${file}`, import.meta.url), 'utf8');
    for (const statement of splitSqlStatements(sql)) await connection.query(statement);
  }

  // The receipt rule is company policy, not schema. Off unless a test is
  // about it; api-attachments.test.js turns it on.
  await connection.query(
    `UPDATE settings SET value = '0' WHERE setting_key = 'receipt_required_above'`,
  );

  const [owners] = await connection.query(`SELECT id FROM users WHERE role = 'owner'`);
  owner = { id: Number(owners[0].id), role: 'owner' };

  await connection.query(
    `INSERT INTO users (name, email, password_hash, role) VALUES
       ('Person One', 'one@test.local', 'x', 'staff'),
       ('Person Two', 'two@test.local', 'x', 'staff')`,
  );
  const [staff] = await connection.query(`SELECT id FROM users WHERE role = 'staff'`);
  people = staff.map((row) => Number(row.id));

  const [accountRows] = await connection.query('SELECT id, name, type FROM accounts');
  accounts = accountRows.map((row) => ({ id: Number(row.id), name: row.name, type: row.type }));

  const [ins] = await connection.query(`SELECT id FROM categories WHERE direction = 'in'`);
  const [outs] = await connection.query(`SELECT id FROM categories WHERE direction = 'out'`);
  inCategories = ins.map((row) => Number(row.id));
  outCategories = outs.map((row) => Number(row.id));

  // Fund every account, or almost every money-out operation would be refused
  // for want of money and the generator would explore nothing.
  for (const account of accounts) {
    const draft = await transactions.createDraft({
      user: owner,
      input: {
        date: '2026-07-01', direction: 'in', accountId: account.id, method: 'account',
        description: `Funding ${account.name}`, categoryId: inCategories[0],
        grossAmount: 100000000, acknowledgedWarnings: WARNING_CODES,
      },
    });
    await transactions.approve({ user: owner, id: draft.id });
  }
});

after(async () => {
  await closePool();
  if (!connection) return;
  await connection.query('SET FOREIGN_KEY_CHECKS = 0');
  for (const table of TABLES) await connection.query(`DROP TABLE IF EXISTS \`${table}\``);
  await connection.query('SET FOREIGN_KEY_CHECKS = 1');
  await connection.end();
});

// --- the invariants ---------------------------------------------------------

async function trialBalance() {
  const [rows] = await connection.query(
    `SELECT COALESCE(SUM(j.debit), 0) AS debits, COALESCE(SUM(j.credit), 0) AS credits
       FROM journal_lines j JOIN transactions t ON t.id = j.transaction_id
      WHERE t.status IN ('posted', 'reversed')`,
  );
  return { debits: Number(rows[0].debits), credits: Number(rows[0].credits) };
}

async function balancesFromLines() {
  const [rows] = await connection.query(
    `SELECT a.id, COALESCE(SUM(j.debit - j.credit), 0) AS balance
       FROM accounts a
       LEFT JOIN journal_lines j ON j.coa_id = a.coa_id
       LEFT JOIN transactions t ON t.id = j.transaction_id
                               AND t.status IN ('posted', 'reversed')
      WHERE t.id IS NULL OR t.status IN ('posted', 'reversed')
      GROUP BY a.id`,
  );
  return new Map(rows.map((row) => [Number(row.id), Number(row.balance)]));
}

async function balancesFromTransactions() {
  const [rows] = await connection.query(
    `SELECT a.id,
            COALESCE(SUM(CASE WHEN t.direction = 'in' THEN t.amount ELSE -t.amount END), 0) AS balance
       FROM accounts a
       LEFT JOIN transactions t ON t.account_id = a.id
                               AND t.status IN ('posted', 'reversed')
                               AND t.entry_type IN ('normal', 'historical')
      GROUP BY a.id`,
  );
  return new Map(rows.map((row) => [Number(row.id), Number(row.balance)]));
}

async function snapshot() {
  // Not aliased `lines`: LINES is reserved in MariaDB, from LOAD DATA. The
  // same trap decision 045 hit with a column called `key`.
  const [rows] = await connection.query(
    `SELECT COUNT(*) AS transaction_count,
            (SELECT COUNT(*) FROM journal_lines) AS line_count,
            (SELECT COALESCE(SUM(debit), 0) FROM journal_lines) AS debit_total
       FROM transactions`,
  );
  return {
    transactions: Number(rows[0].transaction_count),
    lines: Number(rows[0].line_count),
    debits: Number(rows[0].debit_total),
  };
}

async function assertHolds(step, what) {
  const { debits, credits } = await trialBalance();
  assert.equal(debits, credits, `${step}: the trial balance is not zero after ${what}`);

  const fromLines = await balancesFromLines();
  const fromTransactions = await balancesFromTransactions();

  for (const [id, balance] of fromTransactions) {
    assert.equal(
      fromLines.get(id) ?? 0, balance,
      `${step}: account ${id} reads differently from its journal lines than from its transactions, after ${what}`,
    );
  }
}

// --- the operations ---------------------------------------------------------

async function moneyIn() {
  const account = pick(accounts);
  const draft = await transactions.createDraft({
    user: owner,
    input: {
      date: '2026-07-15', direction: 'in', accountId: account.id, method: 'account',
      description: `Received into ${account.name} ${between(1, 9999)}`,
      categoryId: pick(inCategories), grossAmount: between(10000, 5000000),
      acknowledgedWarnings: WARNING_CODES,
    },
  });
  await transactions.approve({ user: owner, id: draft.id });
  return 'money in';
}

async function moneyOut() {
  const account = pick(accounts);
  const draft = await transactions.createDraft({
    user: owner,
    input: {
      date: '2026-07-15', direction: 'out', accountId: account.id, method: 'account',
      description: `Paid from ${account.name} ${between(1, 9999)}`,
      categoryId: pick(outCategories), grossAmount: between(10000, 3000000),
      acknowledgedWarnings: WARNING_CODES,
    },
  });
  await transactions.approve({ user: owner, id: draft.id });
  return 'money out';
}

async function paidByAPerson() {
  const draft = await transactions.createDraft({
    user: owner,
    input: {
      date: '2026-07-15', direction: 'out', accountId: null, method: 'card',
      paidByType: 'person', paidByUserId: pick(people),
      description: `Personal card ${between(1, 9999)}`,
      categoryId: pick(outCategories), grossAmount: between(10000, 500000),
      acknowledgedWarnings: WARNING_CODES,
    },
  });
  await transactions.approve({ user: owner, id: draft.id });
  return 'a cost paid personally';
}

async function transfer() {
  const from = pick(accounts);
  const to = pick(accounts.filter((account) => account.id !== from.id));
  await transactions.createTransfer({
    user: owner,
    input: {
      date: '2026-07-15', fromAccountId: from.id, toAccountId: to.id,
      amount: between(10000, 2000000),
      fee: random() < 0.3 ? between(100, 5000) : 0,
      acknowledgedWarnings: WARNING_CODES,
    },
  });
  return 'a transfer';
}

async function reversal() {
  const [rows] = await connection.query(
    `SELECT id FROM transactions
      WHERE status = 'posted' AND reversed_by_id IS NULL AND reversal_of_id IS NULL
        AND entry_type = 'normal'
      ORDER BY RAND() LIMIT 1`,
  );
  if (rows.length === 0) return null;

  await transactions.reverse({
    user: owner, id: Number(rows[0].id), reason: 'property test reversal',
  });
  return 'a reversal';
}

async function reimbursement() {
  const person = pick(people);
  const outstanding = await reimbursements.outstandingFor(person);
  if (outstanding.items.length === 0) return null;

  const items = outstanding.items.slice(0, between(1, outstanding.items.length + 1));
  await reimbursements.createReimbursement({
    user: owner,
    input: {
      personUserId: person,
      accountId: accounts.find((account) => account.type === 'bank').id,
      date: '2026-07-20',
      items: items.map((item) => ({
        transactionId: item.transactionId, amount: item.remaining.minor,
      })),
      acknowledgedWarnings: WARNING_CODES,
    },
  });
  return 'a reimbursement';
}

const OPS = [
  { run: moneyIn, weight: 4 },
  { run: moneyOut, weight: 4 },
  { run: paidByAPerson, weight: 2 },
  { run: transfer, weight: 3 },
  { run: reversal, weight: 2 },
  { run: reimbursement, weight: 1 },
];

const WEIGHTED = OPS.flatMap((op) => Array(op.weight).fill(op));

test(`${OPERATIONS} random operations leave the books consistent after every one`, async () => {
  console.log(`  property test seed ${SEED}, reproduce with PROPERTY_SEED=${SEED}`);

  const counts = { applied: 0, refused: 0, skipped: 0 };
  await assertHolds('start', 'funding');

  for (let step = 1; step <= OPERATIONS; step += 1) {
    const before = await snapshot();
    const operation = pick(WEIGHTED);

    let what;
    try {
      what = await operation.run();
    } catch (error) {
      // A refusal is a valid outcome: cash below zero, nothing owed to anyone,
      // a duplicate it would not confirm. What matters is that it left no mark.
      counts.refused += 1;
      const after = await snapshot();
      assert.deepEqual(
        after, before,
        `step ${step}: a refused operation left something behind (${error.code ?? error.message})`,
      );
      await assertHolds(`step ${step}`, `a refused operation (${error.code ?? error.message})`);
      continue;
    }

    if (what === null) {
      counts.skipped += 1;
      continue;
    }

    counts.applied += 1;
    await assertHolds(`step ${step}`, what);
  }

  console.log(
    `  ${counts.applied} applied, ${counts.refused} refused and left no mark, ${counts.skipped} not possible yet`,
  );
  assert.ok(counts.applied > OPERATIONS / 4, 'too few operations actually ran to prove much');
});

test('every posted entry balances on its own, not just in total', async () => {
  const [rows] = await connection.query(
    `SELECT t.id, COALESCE(SUM(j.debit), 0) AS debits, COALESCE(SUM(j.credit), 0) AS credits
       FROM transactions t JOIN journal_lines j ON j.transaction_id = t.id
      WHERE t.status IN ('posted', 'reversed')
      GROUP BY t.id
     HAVING debits <> credits`,
  );
  assert.deepEqual(rows, [], 'these entries do not balance on their own');
});

test('no posted entry is missing its journal lines', async () => {
  const [rows] = await connection.query(
    `SELECT t.id, t.journal_number FROM transactions t
      LEFT JOIN journal_lines j ON j.transaction_id = t.id
      WHERE t.status IN ('posted', 'reversed') AND j.id IS NULL`,
  );
  assert.deepEqual(rows, [], 'posted entries with no journal behind them');
});

test('journal numbers run without gaps or duplicates', async () => {
  const [rows] = await connection.query(
    `SELECT journal_number FROM transactions
      WHERE journal_number IS NOT NULL ORDER BY id`,
  );
  const numbers = rows.map((row) => Number(String(row.journal_number).replace(/\D/g, '')));

  assert.equal(new Set(numbers).size, numbers.length, 'a journal number was used twice');

  const sorted = [...numbers].sort((a, b) => a - b);
  for (let index = 1; index < sorted.length; index += 1) {
    assert.equal(
      sorted[index], sorted[index - 1] + 1,
      `the series jumps from ${sorted[index - 1]} to ${sorted[index]}, which is the first thing an auditor asks about`,
    );
  }
});

test('every reversal nets to nothing against what it reversed', async () => {
  const [rows] = await connection.query(
    `SELECT r.id AS reversal_id, o.id AS original_id,
            COALESCE(SUM(j.debit - j.credit), 0) AS net
       FROM transactions r
       JOIN transactions o ON o.id = r.reversal_of_id
       JOIN journal_lines j ON j.transaction_id IN (r.id, o.id)
      GROUP BY r.id, o.id, j.coa_id
     HAVING net <> 0`,
  );
  assert.deepEqual(rows, [], 'a reversal did not cancel what it reversed, account by account');
});
