// Migration 001 against the real database.
//
// These do not check that the SQL ran. They check that the rules written into
// the schema actually bite, because a CHECK constraint that is accepted and
// then ignored is worse than no constraint: it looks like protection.

import test, { before, after } from 'node:test';
import assert from 'node:assert/strict';
import process from 'node:process';
import { readFile } from 'node:fs/promises';

import { openConnection } from '../core/db.js';
import { splitSqlStatements } from '../core/sql-split.js';

const EXPECTED_TABLES = [
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

let connection;

async function applyMigration(filename) {
  const sql = await readFile(new URL(`../migrations/${filename}`, import.meta.url), 'utf8');
  for (const statement of splitSqlStatements(sql)) {
    await connection.query(statement);
  }
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

  // Build the schema from the migration files themselves, in a database that
  // gets dropped afterwards. Tests must never depend on leftover state.
  await connection.query('SET FOREIGN_KEY_CHECKS = 0');
  for (const table of [...EXPECTED_TABLES].reverse()) {
    await connection.query(`DROP TABLE IF EXISTS \`${table}\``);
  }
  await connection.query('SET FOREIGN_KEY_CHECKS = 1');

  await applyMigration('000_schema_migrations.sql');
  await applyMigration('001_phase0_tables.sql');
});

after(async () => {
  if (!connection) return;
  await connection.query('SET FOREIGN_KEY_CHECKS = 0');
  for (const table of [...EXPECTED_TABLES].reverse()) {
    await connection.query(`DROP TABLE IF EXISTS \`${table}\``);
  }
  await connection.query('SET FOREIGN_KEY_CHECKS = 1');
  await connection.end();
});

async function tableNames() {
  const [rows] = await connection.query(
    'SELECT table_name AS name FROM information_schema.tables WHERE table_schema = DATABASE()',
  );
  return rows.map((row) => row.name).sort();
}

// A helper to seed just enough rows for the constraint tests below.
async function seedMinimum() {
  await connection.query(
    `INSERT IGNORE INTO chart_of_accounts (code, name, type, normal_balance, is_header, allow_manual_posting)
     VALUES ('1113', 'Bank, Winibex current account', 'asset', 'debit', 0, 1)`,
  );
  const [rows] = await connection.query(
    'SELECT id FROM chart_of_accounts WHERE code = ?',
    ['1113'],
  );
  return rows[0].id;
}

test('every Phase 0 table exists and nothing from a later phase does', async () => {
  const names = await tableNames();
  assert.deepEqual(names, [...EXPECTED_TABLES].sort());
});

test('applying migration 001 twice fails rather than half succeeding', async () => {
  // CREATE TABLE without IF NOT EXISTS is deliberate. A migration that has
  // already run must be skipped by the runner, not quietly reapplied.
  await assert.rejects(
    () => applyMigration('001_phase0_tables.sql'),
    /already exists/i,
  );
});

test('every table is utf8mb4 with the MariaDB collation', async () => {
  const [rows] = await connection.query(
    `SELECT table_name AS name, table_collation AS collation
     FROM information_schema.tables
     WHERE table_schema = DATABASE()`,
  );
  for (const row of rows) {
    assert.equal(
      row.collation,
      'utf8mb4_uca1400_ai_ci',
      `${row.name} is ${row.collation}`,
    );
  }
});

test('there can only ever be one owner', async () => {
  await connection.query(
    `INSERT INTO users (name, email, password_hash, role)
     VALUES ('Winibex office', 'office@example.test', 'x', 'owner')`,
  );

  await assert.rejects(
    () =>
      connection.query(
        `INSERT INTO users (name, email, password_hash, role)
         VALUES ('Second owner', 'second@example.test', 'x', 'owner')`,
      ),
    /duplicate/i,
    'a second owner account was accepted',
  );

  // Admins and staff are unlimited in number.
  await connection.query(
    `INSERT INTO users (name, email, password_hash, role)
     VALUES ('Maryam', 'maryam@example.test', 'x', 'staff'),
            ('Fazal', 'fazal@example.test', 'x', 'staff')`,
  );
});

test('an approval limit cannot be given to staff', async () => {
  await assert.rejects(
    () =>
      connection.query(
        `INSERT INTO users (name, email, password_hash, role, approval_limit)
         VALUES ('Limited staff', 'limited@example.test', 'x', 'staff', 1000000)`,
      ),
    /constraint/i,
  );
});

test('staff cannot be set to auto approve their own entries', async () => {
  await assert.rejects(
    () =>
      connection.query(
        `INSERT INTO users (name, email, password_hash, role, auto_approve_own)
         VALUES ('Auto staff', 'auto@example.test', 'x', 'staff', 1)`,
      ),
    /constraint/i,
  );
});

test('two users cannot share an email', async () => {
  await assert.rejects(
    () =>
      connection.query(
        `INSERT INTO users (name, email, password_hash, role)
         VALUES ('Impostor', 'maryam@example.test', 'x', 'staff')`,
      ),
    /duplicate/i,
  );
});

test('a header account cannot be posted to', async () => {
  await assert.rejects(
    () =>
      connection.query(
        `INSERT INTO chart_of_accounts (code, name, type, normal_balance, is_header, allow_manual_posting)
         VALUES ('1100', 'Current assets', 'asset', 'debit', 1, 1)`,
      ),
    /constraint/i,
    'a header account was left open for manual posting',
  );
});

test('two ledger accounts cannot share a code', async () => {
  await seedMinimum();
  await assert.rejects(
    () =>
      connection.query(
        `INSERT INTO chart_of_accounts (code, name, type, normal_balance)
         VALUES ('1113', 'Something else', 'asset', 'debit')`,
      ),
    /duplicate/i,
  );
});

test('a pass-through account must name the person whose account it is', async () => {
  const coaId = await seedMinimum();

  await assert.rejects(
    () =>
      connection.query(
        `INSERT INTO accounts (name, type, coa_id, opening_date)
         VALUES ('Someone personal account', 'pass_through', ?, '2025-03-01')`,
        [coaId],
      ),
    /constraint/i,
    'a pass-through account was created with no owner',
  );
});

test('an account cannot point at a ledger code that does not exist', async () => {
  await assert.rejects(
    () =>
      connection.query(
        `INSERT INTO accounts (name, type, coa_id, opening_date)
         VALUES ('Ghost account', 'bank', 999999, '2025-03-01')`,
      ),
    /foreign key/i,
  );
});

test('two accounts cannot share one ledger code', async () => {
  const coaId = await seedMinimum();
  await connection.query(
    `INSERT INTO accounts (name, type, coa_id, opening_date)
     VALUES ('Winibex bank', 'bank', ?, '2025-03-01')`,
    [coaId],
  );

  await assert.rejects(
    () =>
      connection.query(
        `INSERT INTO accounts (name, type, coa_id, opening_date)
         VALUES ('Winibex bank copy', 'bank', ?, '2025-03-01')`,
        [coaId],
      ),
    /duplicate/i,
    'two accounts were allowed to share a balance, which is the spreadsheet bug',
  );
});

test('the company profile can only ever hold one row', async () => {
  await connection.query(
    `INSERT INTO company_profile (id, legal_name) VALUES (1, 'Winibex PVT LTD')`,
  );

  await assert.rejects(
    () =>
      connection.query(
        `INSERT INTO company_profile (id, legal_name) VALUES (2, 'Someone else')`,
      ),
    /constraint/i,
  );
});

test('a sequence cannot be rewound below one', async () => {
  await connection.query(
    `INSERT INTO sequences (name, prefix, next_value) VALUES ('invoice', 'INV-', 5026)`,
  );

  await assert.rejects(
    () => connection.query('UPDATE sequences SET next_value = 0 WHERE name = ?', ['invoice']),
    /constraint/i,
  );
});

test('the audit log refuses text that is not valid JSON', async () => {
  const [users] = await connection.query('SELECT id FROM users LIMIT 1');

  await connection.query(
    `INSERT INTO audit_log (user_id, table_name, record_id, action, after_json)
     VALUES (?, 'users', ?, 'insert', ?)`,
    [users[0].id, users[0].id, JSON.stringify({ role: 'staff' })],
  );

  await assert.rejects(
    () =>
      connection.query(
        `INSERT INTO audit_log (table_name, record_id, action, after_json)
         VALUES ('users', 1, 'insert', 'not json at all')`,
      ),
    /constraint|json/i,
  );
});

test('a currency with an impossible number of decimal places is refused', async () => {
  await connection.query(
    `INSERT INTO currencies (code, name, symbol, minor_units) VALUES ('PKR', 'Pakistani Rupee', 'Rs', 2)`,
  );

  await assert.rejects(
    () =>
      connection.query(
        `INSERT INTO currencies (code, name, symbol, minor_units) VALUES ('XXX', 'Nonsense', 'X', 9)`,
      ),
    /constraint/i,
  );
});

test('a category must point at a real ledger account', async () => {
  const coaId = await seedMinimum();

  await connection.query(
    `INSERT INTO categories (name, main_head, direction, coa_id)
     VALUES ('Bank transfer in', 'balance_sheet', 'in', ?)`,
    [coaId],
  );

  await assert.rejects(
    () =>
      connection.query(
        `INSERT INTO categories (name, main_head, direction, coa_id)
         VALUES ('Floating category', 'admin', 'out', 999999)`,
      ),
    /foreign key/i,
  );
});

test('a user is never deleted while anything references them', async () => {
  const [users] = await connection.query(
    'SELECT id FROM users WHERE email = ?',
    ['maryam@example.test'],
  );

  await connection.query(
    `INSERT INTO refresh_tokens (user_id, token_hash, family_id, expires_at)
     VALUES (?, REPEAT('a', 64), UUID(), '2030-01-01 00:00:00')`,
    [users[0].id],
  );

  await assert.rejects(
    () => connection.query('DELETE FROM users WHERE id = ?', [users[0].id]),
    /foreign key/i,
    'a user with an active session could be deleted',
  );
});
