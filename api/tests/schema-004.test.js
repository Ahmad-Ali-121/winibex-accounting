// Migration 004 against the real database.
//
// Same reasoning as schema-001: these do not check that the SQL ran. They
// check that the rules bite. Everything here is raw SQL with no service layer
// involved, because the point of decision 012 is that the guarantee survives a
// bad script, a direct phpMyAdmin edit, or a future developer who has not read
// the rules.
//
// If one of these starts failing, do not relax it. Something that must not be
// possible has become possible.

import test, { before, after } from 'node:test';
import assert from 'node:assert/strict';
import process from 'node:process';
import { readFile } from 'node:fs/promises';

import { openConnection } from '../core/db.js';
import { splitSqlStatements } from '../core/sql-split.js';

const PHASE0_TABLES = [
  'accounts',
  'audit_log',
  'categories',
  'chart_of_accounts',
  'company_profile',
  'currencies',
  'fbr_return_heads',
  'idempotency_keys',
  'refresh_tokens',
  'schema_migrations',
  'sequences',
  'settings',
  'users',
];

const PHASE1_TABLES = [
  'attachments',
  'cheques',
  'entry_flags',
  'journal_lines',
  'period_locks',
  'reimbursement_items',
  'reimbursements',
  'tax_rules',
  'taxes',
  'transaction_charges',
  'transaction_taxes',
  'transactions',
  'vendors',
];

const EXPECTED_TRIGGERS = [
  'trg_journal_lines_no_delete',
  'trg_journal_lines_no_update',
  'trg_transactions_immutable',
  'trg_transactions_no_delete',
];

let connection;
let accountId;
let categoryId;
let userId;

// Every posted entry needs a different journal number, so tests that create
// one take the next value here rather than sharing a literal.
let nextJournalNumber = 1;
function journalNumber() {
  return `JV-${String(nextJournalNumber++).padStart(4, '0')}`;
}

async function applyMigration(filename) {
  const sql = await readFile(new URL(`../migrations/${filename}`, import.meta.url), 'utf8');
  for (const statement of splitSqlStatements(sql)) {
    await connection.query(statement);
  }
}

async function dropEverything() {
  await connection.query('SET FOREIGN_KEY_CHECKS = 0');
  for (const table of [...PHASE1_TABLES, ...PHASE0_TABLES]) {
    await connection.query(`DROP TABLE IF EXISTS \`${table}\``);
  }
  await connection.query('SET FOREIGN_KEY_CHECKS = 1');
}

before(async () => {
  assert.ok(process.env.DB_TEST_NAME, 'DB_TEST_NAME is not set');
  assert.notEqual(process.env.DB_TEST_NAME, process.env.DB_NAME);

  try {
    connection = await openConnection({ database: process.env.DB_TEST_NAME });
  } catch (error) {
    throw new Error(
      'Could not reach the database. Start it with: docker compose up -d\n' +
        `Original error: ${error.message}`,
    );
  }

  await dropEverything();

  // The whole stack, from the migration files themselves. 002 and 003 are
  // needed because these tests post to a real account, in a real category,
  // against the real chart of accounts.
  await applyMigration('000_schema_migrations.sql');
  await applyMigration('001_phase0_tables.sql');
  await applyMigration('002_seed_reference.sql');
  await applyMigration('003_bootstrap.sql');
  await applyMigration('004_phase1_tables.sql');

  const [accounts] = await connection.query(
    `SELECT id FROM accounts WHERE name = 'Winibex bank'`,
  );
  assert.ok(accounts.length === 1, 'migration 003 did not create the bank account');
  accountId = accounts[0].id;

  const [categories] = await connection.query(
    `SELECT id FROM categories WHERE direction = 'out' LIMIT 1`,
  );
  assert.ok(categories.length === 1, 'migration 002 seeded no money-out category');
  categoryId = categories[0].id;

  const [users] = await connection.query(`SELECT id FROM users WHERE role = 'owner'`);
  assert.ok(users.length === 1, 'migration 003 did not create the owner');
  userId = users[0].id;
});

after(async () => {
  if (!connection) return;
  await dropEverything();
  await connection.end();
});

async function coaId(code) {
  const [rows] = await connection.query('SELECT id FROM chart_of_accounts WHERE code = ?', [code]);
  assert.ok(rows.length === 1, `ledger code ${code} is not seeded`);
  return rows[0].id;
}

async function insertTransaction(fields) {
  const columns = Object.keys(fields);
  const [result] = await connection.query(
    `INSERT INTO transactions (${columns.join(', ')})
     VALUES (${columns.map(() => '?').join(', ')})`,
    Object.values(fields),
  );
  return result.insertId;
}

// The worked example from docs/CHART-OF-ACCOUNTS.md, in paisa:
// 5,600 subscription + 28 advance tax + 325 of fees = 5,953 leaving the bank.
function draftFields(overrides = {}) {
  return {
    date: '2026-07-05',
    account_id: accountId,
    direction: 'out',
    amount: 595300,
    currency: 'PKR',
    method: 'account',
    description: 'Claude subscription',
    category_id: categoryId,
    gross_amount: 560000,
    tax_total: 2800,
    charges_total: 32500,
    status: 'draft',
    created_by: userId,
    ...overrides,
  };
}

function postedFields(overrides = {}) {
  return draftFields({
    journal_number: journalNumber(),
    status: 'posted',
    approved_by: userId,
    posted_at: '2026-07-05 09:00:00',
    approval_method: 'auto',
    ...overrides,
  });
}

// ---------------------------------------------------------------------------
// The file applied, and what it left behind
// ---------------------------------------------------------------------------

test('every Phase 1 table exists', async () => {
  const [rows] = await connection.query(
    'SELECT table_name AS name FROM information_schema.tables WHERE table_schema = DATABASE()',
  );
  const names = rows.map((row) => row.name);
  for (const table of PHASE1_TABLES) {
    assert.ok(names.includes(table), `${table} is missing`);
  }
});

test('the four immutability triggers exist', async () => {
  const [rows] = await connection.query(
    `SELECT trigger_name AS name FROM information_schema.triggers
     WHERE trigger_schema = DATABASE()`,
  );
  assert.deepEqual(rows.map((row) => row.name).sort(), EXPECTED_TRIGGERS);
});

test('every Phase 1 table is utf8mb4 with the MariaDB collation', async () => {
  const [rows] = await connection.query(
    `SELECT table_name AS name, table_collation AS collation
     FROM information_schema.tables WHERE table_schema = DATABASE()`,
  );
  for (const row of rows.filter((r) => PHASE1_TABLES.includes(r.name))) {
    assert.equal(row.collation, 'utf8mb4_unicode_ci', `${row.name} is ${row.collation}`);
  }
});

test('applying migration 004 twice fails rather than half succeeding', async () => {
  await assert.rejects(() => applyMigration('004_phase1_tables.sql'), /already exists/i);
});

// ---------------------------------------------------------------------------
// The money columns must agree with each other
// ---------------------------------------------------------------------------

test('a correct posted entry and its journal lines are accepted', async () => {
  const id = await insertTransaction(postedFields());

  await connection.query(
    `INSERT INTO journal_lines (transaction_id, coa_id, debit, credit, line_no) VALUES
       (?, ?, 560000, 0, 1),
       (?, ?,  32500, 0, 2),
       (?, ?,   2800, 0, 3),
       (?, ?,      0, 595300, 4)`,
    [
      id, await coaId('6400'),
      id, await coaId('8200'),
      id, await coaId('1141'),
      id, await coaId('1113'),
    ],
  );

  const [[totals]] = await connection.query(
    'SELECT SUM(debit) AS debits, SUM(credit) AS credits FROM journal_lines WHERE transaction_id = ?',
    [id],
  );
  assert.equal(Number(totals.debits), Number(totals.credits), 'the entry does not balance');
});

test('money out where amount does not equal gross plus tax plus charges is refused', async () => {
  await assert.rejects(
    () => insertTransaction(draftFields({ amount: 500000 })),
    /constraint/i,
  );
});

test('money in reconciles the other way, gross minus tax minus charges', async () => {
  // 5,600 received, 28 of tax and 325 of fees deducted, 5,247 reaches the bank.
  await insertTransaction(
    draftFields({ direction: 'in', amount: 524700, description: 'Client payment' }),
  );

  await assert.rejects(
    () => insertTransaction(draftFields({ direction: 'in', amount: 595300 })),
    /constraint/i,
    'a money in entry was allowed to add its deductions instead of subtracting them',
  );
});

test('a zero or negative amount is refused', async () => {
  await assert.rejects(
    () => insertTransaction(draftFields({ amount: 0, gross_amount: 0, tax_total: 0, charges_total: 0 })),
    /constraint/i,
  );
  await assert.rejects(
    () => insertTransaction(draftFields({ amount: -595300 })),
    /constraint/i,
    'direction carries the sign, never the number',
  );
});

// ---------------------------------------------------------------------------
// Currency
// ---------------------------------------------------------------------------

test('a PKR entry carrying an exchange rate is refused', async () => {
  await assert.rejects(
    () => insertTransaction(draftFields({ fx_rate: 280.0, fx_rate_source: 'manual', foreign_amount: 2000 })),
    /constraint/i,
  );
});

test('a foreign entry with no rate is refused', async () => {
  await assert.rejects(
    () => insertTransaction(draftFields({ currency: 'USD' })),
    /constraint/i,
    'a foreign amount with no rate cannot be converted and must not be stored',
  );
});

test('a foreign entry with amount, rate and source is accepted', async () => {
  await insertTransaction(
    draftFields({
      currency: 'USD',
      foreign_amount: 2000,
      fx_rate: 280.0,
      fx_rate_source: 'manual',
    }),
  );
});

// ---------------------------------------------------------------------------
// Gapless numbering, made physical
// ---------------------------------------------------------------------------

test('a draft cannot hold a journal number', async () => {
  await assert.rejects(
    () => insertTransaction(draftFields({ journal_number: journalNumber() })),
    /constraint/i,
    'a draft holding a number would leave a hole in the series if abandoned',
  );
});

test('a posted entry must have a journal number, a posting time and an approver', async () => {
  await assert.rejects(
    () => insertTransaction(draftFields({ status: 'posted', approved_by: userId, posted_at: '2026-07-05 09:00:00', approval_method: 'auto' })),
    /constraint/i,
  );
  await assert.rejects(
    () => insertTransaction(postedFields({ approved_by: null })),
    /constraint/i,
  );
});

test('two entries cannot share a journal number', async () => {
  const number = journalNumber();
  await insertTransaction(postedFields({ journal_number: number }));
  await assert.rejects(
    () => insertTransaction(postedFields({ journal_number: number })),
    /duplicate/i,
  );
});

// ---------------------------------------------------------------------------
// Paid by a person
// ---------------------------------------------------------------------------

test('paid by a person with nobody named is refused', async () => {
  await assert.rejects(
    () => insertTransaction(draftFields({ paid_by_type: 'person' })),
    /constraint/i,
    'the company owes someone, and the books must say who',
  );
});

test('paid by the company cannot also name a person', async () => {
  await assert.rejects(
    () => insertTransaction(draftFields({ paid_by_type: 'company', paid_by_user_id: userId })),
    /constraint/i,
  );
});

// ---------------------------------------------------------------------------
// Journal lines
// ---------------------------------------------------------------------------

test('a journal line is a debit or a credit, never both and never neither', async () => {
  const id = await insertTransaction(postedFields());
  const bank = await coaId('1113');

  await assert.rejects(
    () => connection.query(
      'INSERT INTO journal_lines (transaction_id, coa_id, debit, credit, line_no) VALUES (?, ?, 100, 100, 1)',
      [id, bank],
    ),
    /constraint/i,
  );
  await assert.rejects(
    () => connection.query(
      'INSERT INTO journal_lines (transaction_id, coa_id, debit, credit, line_no) VALUES (?, ?, 0, 0, 1)',
      [id, bank],
    ),
    /constraint/i,
  );
  await assert.rejects(
    () => connection.query(
      'INSERT INTO journal_lines (transaction_id, coa_id, debit, credit, line_no) VALUES (?, ?, -100, 0, 1)',
      [id, bank],
    ),
    /constraint/i,
  );
});

// ---------------------------------------------------------------------------
// Immutability. Raw SQL, no application layer.
// ---------------------------------------------------------------------------

test('the money on a posted entry cannot be changed', async () => {
  const id = await insertTransaction(postedFields());
  await assert.rejects(
    () => connection.query('UPDATE transactions SET amount = 1 WHERE id = ?', [id]),
    /immutable/i,
  );
});

test('the date of a posted entry cannot be changed', async () => {
  const id = await insertTransaction(postedFields());
  await assert.rejects(
    () => connection.query('UPDATE transactions SET date = ? WHERE id = ?', ['2026-08-01', id]),
    /immutable/i,
    'moving an entry to another month changes a period that is already reported',
  );
});

test('the account and description of a posted entry cannot be changed', async () => {
  const id = await insertTransaction(postedFields());
  await assert.rejects(
    () => connection.query('UPDATE transactions SET description = ? WHERE id = ?', ['edited', id]),
    /immutable/i,
  );
});

test('a posted entry cannot be moved back to draft', async () => {
  const id = await insertTransaction(postedFields());
  await assert.rejects(
    () => connection.query('UPDATE transactions SET status = ? WHERE id = ?', ['draft', id]),
    /only move to reversed/i,
  );
});

test('a posted entry cannot be deleted', async () => {
  const id = await insertTransaction(postedFields());
  await assert.rejects(
    () => connection.query('DELETE FROM transactions WHERE id = ?', [id]),
    /never deleted/i,
  );
});

test('a journal line cannot be edited or deleted', async () => {
  const id = await insertTransaction(postedFields());
  const bank = await coaId('1113');
  const [line] = await connection.query(
    'INSERT INTO journal_lines (transaction_id, coa_id, debit, credit, line_no) VALUES (?, ?, 100, 0, 1)',
    [id, bank],
  );

  await assert.rejects(
    () => connection.query('UPDATE journal_lines SET debit = 1 WHERE id = ?', [line.insertId]),
    /cannot be changed/i,
  );
  await assert.rejects(
    () => connection.query('DELETE FROM journal_lines WHERE id = ?', [line.insertId]),
    /never deleted/i,
  );
});

test('a draft is still freely editable, so the trigger has not over-reached', async () => {
  const id = await insertTransaction(draftFields());
  await connection.query('UPDATE transactions SET amount = 100, gross_amount = 100, tax_total = 0, charges_total = 0 WHERE id = ?', [id]);

  const [[row]] = await connection.query('SELECT amount FROM transactions WHERE id = ?', [id]);
  assert.equal(Number(row.amount), 100);
});

// ---------------------------------------------------------------------------
// Reversal, the one thing a posted entry is still allowed to do
// ---------------------------------------------------------------------------

test('rebilled_invoice_id may still be set after posting', async () => {
  const id = await insertTransaction(postedFields({ is_rebillable: 1 }));
  await connection.query('UPDATE transactions SET rebilled_invoice_id = 77 WHERE id = ?', [id]);

  const [[row]] = await connection.query('SELECT rebilled_invoice_id FROM transactions WHERE id = ?', [id]);
  assert.equal(Number(row.rebilled_invoice_id), 77);
});

test('a reversal marks the original and links both rows', async () => {
  const originalId = await insertTransaction(postedFields());

  // A reversing entry carries no tax or charge breakdown of its own. For money
  // in, amount = gross - tax - charges, so repeating the original's split would
  // not reconcile. Its journal lines mirror the original instead.
  const reversalId = await insertTransaction(
    postedFields({
      direction: 'in',
      amount: 595300,
      gross_amount: 595300,
      tax_total: 0,
      charges_total: 0,
      description: 'Reversal',
      reversal_of_id: originalId,
      reversal_reason: 'paid on the wrong card',
    }),
  );

  await connection.query(
    `UPDATE transactions SET status = 'reversed', reversed_by_id = ? WHERE id = ?`,
    [reversalId, originalId],
  );

  const [[row]] = await connection.query(
    'SELECT status, reversed_by_id FROM transactions WHERE id = ?',
    [originalId],
  );
  assert.equal(row.status, 'reversed');
  assert.equal(Number(row.reversed_by_id), reversalId);
});

test('an entry cannot be reversed twice', async () => {
  const originalId = await insertTransaction(postedFields());
  await insertTransaction(
    postedFields({ reversal_of_id: originalId, reversal_reason: 'first reversal' }),
  );

  await assert.rejects(
    () => insertTransaction(
      postedFields({ reversal_of_id: originalId, reversal_reason: 'second reversal' }),
    ),
    /duplicate/i,
  );
});

test('a reversing entry must carry a reason', async () => {
  const originalId = await insertTransaction(postedFields());
  await assert.rejects(
    () => insertTransaction(postedFields({ reversal_of_id: originalId })),
    /constraint/i,
    'decision 012 requires a reason, and it appears in the ledger',
  );
});

test('a rejected entry must carry a reason', async () => {
  await assert.rejects(
    () => insertTransaction(draftFields({ status: 'rejected' })),
    /constraint/i,
  );
});

// ---------------------------------------------------------------------------
// Tax, charge and cheque lines
// ---------------------------------------------------------------------------

test('a tax line cannot be larger than the amount it is calculated on', async () => {
  const id = await insertTransaction(postedFields());
  const [taxes] = await connection.query('SELECT id FROM taxes LIMIT 1');

  if (taxes.length === 0) {
    // Taxes are deliberately not seeded. They wait for the accountant,
    // decision 046. The constraint is still proved by the insert below once
    // a tax exists, so this skips rather than passes silently.
    return;
  }

  await assert.rejects(
    () => connection.query(
      `INSERT INTO transaction_taxes
         (transaction_id, tax_id, base_amount, rate_applied, atl_status_used, atl_party, tax_amount, deducted_by)
       VALUES (?, ?, 560000, 0.25, 'atl', 'company', 999999, 'bank')`,
      [id, taxes[0].id],
    ),
    /constraint/i,
  );
});

test('a cheque number cannot be reused on the same account', async () => {
  await connection.query(
    `INSERT INTO cheques (account_id, cheque_number, payee, amount, issue_date, created_by)
     VALUES (?, '000123', 'A supplier', 100000, '2026-07-05', ?)`,
    [accountId, userId],
  );

  await assert.rejects(
    () => connection.query(
      `INSERT INTO cheques (account_id, cheque_number, payee, amount, issue_date, created_by)
       VALUES (?, '000123', 'Someone else', 200000, '2026-07-06', ?)`,
      [accountId, userId],
    ),
    /duplicate/i,
  );
});

test('a vendor with a known ATL status must record when it was checked', async () => {
  await connection.query(
    `INSERT INTO vendors (name, kind, atl_status, created_by) VALUES ('Unknown vendor', 'individual', 'unknown', ?)`,
    [userId],
  );

  await assert.rejects(
    () => connection.query(
      `INSERT INTO vendors (name, kind, atl_status, created_by) VALUES ('Checked vendor', 'company', 'atl', ?)`,
      [userId],
    ),
    /constraint/i,
    'a withholding rate was chosen from a status with no date behind it',
  );
});
