// The seeded chart of accounts and categories. A chart that is internally
// inconsistent produces statements that do not add up, and nobody notices
// until the accountant does.

import test, { before, after } from 'node:test';
import assert from 'node:assert/strict';
import process from 'node:process';
import { readFile } from 'node:fs/promises';

import { openConnection } from '../core/db.js';
import { splitSqlStatements } from '../core/sql-split.js';

const TABLES = [
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

async function dropAll() {
  await connection.query('SET FOREIGN_KEY_CHECKS = 0');
  for (const table of [...TABLES].reverse()) {
    await connection.query(`DROP TABLE IF EXISTS \`${table}\``);
  }
  await connection.query('SET FOREIGN_KEY_CHECKS = 1');
}

async function applyMigration(filename) {
  const sql = await readFile(new URL(`../migrations/${filename}`, import.meta.url), 'utf8');
  for (const statement of splitSqlStatements(sql)) {
    await connection.query(statement);
  }
}

before(async () => {
  assert.notEqual(process.env.DB_TEST_NAME, process.env.DB_NAME);
  try {
    connection = await openConnection({ database: process.env.DB_TEST_NAME });
  } catch (error) {
    throw new Error(
      'Could not reach the database. Start it with: docker compose up -d\n' +
        `Original error: ${error.message}`,
    );
  }
  await dropAll();
  await applyMigration('000_schema_migrations.sql');
  await applyMigration('001_phase0_tables.sql');
  await applyMigration('002_seed_reference.sql');
});

after(async () => {
  if (!connection) return;
  await dropAll();
  await connection.end();
});

async function rows(sql, params = []) {
  const [result] = await connection.query(sql, params);
  return result;
}

test('the six currencies the company actually uses are seeded', async () => {
  const codes = (await rows('SELECT code FROM currencies ORDER BY code')).map((r) => r.code);
  assert.deepEqual(codes, ['AED', 'EUR', 'GBP', 'PKR', 'QAR', 'USD']);
});

test('every ledger account except the five class roots has a parent', async () => {
  const orphans = await rows(
    `SELECT code, name FROM chart_of_accounts
     WHERE parent_id IS NULL AND code NOT IN ('1000','2000','3000','4000','5000','6000','7000','8000','9000')`,
  );
  assert.deepEqual(orphans, [], `accounts with no parent: ${orphans.map((r) => r.code).join(', ')}`);
});

test('a parent is always a header, and always in the same class', async () => {
  const wrong = await rows(
    `SELECT c.code, p.code AS parent_code, p.is_header
     FROM chart_of_accounts c JOIN chart_of_accounts p ON p.id = c.parent_id
     WHERE p.is_header = 0 OR LEFT(p.code, 1) <> LEFT(c.code, 1)`,
  );
  assert.deepEqual(wrong, []);
});

test('nothing can be posted to a header account', async () => {
  const bad = await rows(
    'SELECT code FROM chart_of_accounts WHERE is_header = 1 AND allow_manual_posting = 1',
  );
  assert.deepEqual(bad, []);
});

test('normal balance follows the account type, contra accounts aside', async () => {
  const wrong = await rows(
    `SELECT code, type, normal_balance FROM chart_of_accounts
     WHERE code NOT IN ('1219', '1229')
       AND ((type IN ('asset', 'expense')  AND normal_balance <> 'debit')
         OR (type IN ('liability', 'equity', 'income') AND normal_balance <> 'credit'))`,
  );
  assert.deepEqual(wrong, []);
});

test('the two accumulated depreciation accounts are contra', async () => {
  const contra = await rows(
    `SELECT code, type, normal_balance FROM chart_of_accounts WHERE code IN ('1219','1229')`,
  );
  assert.equal(contra.length, 2);
  for (const row of contra) {
    assert.equal(row.type, 'asset');
    assert.equal(row.normal_balance, 'credit', `${row.code} should be a credit balance`);
  }
});

test('the first digit of a code always matches its class', async () => {
  const expected = {
    1: 'asset',
    2: 'liability',
    3: 'equity',
    4: 'income',
    5: 'expense',
    6: 'expense',
    7: 'expense',
    8: 'expense',
    9: 'expense',
  };
  for (const row of await rows('SELECT code, type FROM chart_of_accounts')) {
    assert.equal(row.type, expected[row.code[0]], `${row.code} is typed ${row.type}`);
  }
});

test('the accounts the posting engine depends on exist and are system accounts', async () => {
  const required = ['1113', '1123', '2114', '2115', '3300', '3400', '4110', '5500', '9100'];
  const found = await rows(
    `SELECT code, is_system FROM chart_of_accounts WHERE code IN (?)`,
    [required],
  );
  assert.equal(found.length, required.length);
  for (const row of found) {
    assert.equal(row.is_system, 1, `${row.code} must not be renameable`);
  }
});

test('every category points at a real account that is not a header', async () => {
  const bad = await rows(
    `SELECT c.name, a.code, a.is_header
     FROM categories c JOIN chart_of_accounts a ON a.id = c.coa_id
     WHERE a.is_header = 1`,
  );
  assert.deepEqual(bad, []);

  const total = (await rows('SELECT COUNT(*) AS n FROM categories'))[0].n;
  assert.ok(Number(total) > 30, `only ${total} categories seeded`);
});

test('income categories are money in, cost categories are money out', async () => {
  const wrong = await rows(
    `SELECT c.name, c.direction, a.type
     FROM categories c JOIN chart_of_accounts a ON a.id = c.coa_id
     WHERE (a.type = 'income'  AND c.direction <> 'in')
        OR (a.type = 'expense' AND c.direction <> 'out')`,
  );
  assert.deepEqual(wrong, []);
});

test('every setting the application reads is seeded', async () => {
  const required = [
    'base_currency',
    'fiscal_year_start_month',
    'payroll_visible_to_all',
    'receipt_required_above',
    'large_cash_warning_above',
    'fx_deviation_warning_percent',
    'pass_through_max_days',
    'pseb_registered',
    'pra_registered',
    'books_live_from',
    'history_merged',
    'atl_status',
  ];
  const found = (await rows('SELECT setting_key FROM settings')).map((r) => r.setting_key);
  for (const key of required) {
    assert.ok(found.includes(key), `setting ${key} is missing`);
  }
});

test('the confirmed company facts are seeded as stated', async () => {
  const map = new Map(
    (await rows('SELECT setting_key, value FROM settings')).map((r) => [r.setting_key, r.value]),
  );
  assert.equal(map.get('pseb_registered'), 'true');
  assert.equal(map.get('pra_registered'), 'false');
  assert.equal(map.get('base_currency'), 'PKR');
  assert.equal(map.get('fiscal_year_start_month'), '7');
  assert.equal(map.get('books_live_from'), '2026-07-01');
  assert.equal(map.get('history_merged'), 'false');
});

test('the invoice sequence continues from the spreadsheet', async () => {
  const seq = (await rows('SELECT * FROM sequences WHERE name = ?', ['invoice']))[0];
  assert.equal(Number(seq.next_value), 5026);
});

test('no taxes are seeded, because they wait for the accountant', async () => {
  const taxTables = await rows(
    `SELECT table_name AS name FROM information_schema.tables
     WHERE table_schema = DATABASE() AND table_name IN ('taxes','tax_rules')`,
  );
  assert.deepEqual(taxTables, []);
});

test('the seed is reference data only, with no company or user rows', async () => {
  // Those come from 003, which is a template until Ahmad fills it in.
  const users = (await rows('SELECT COUNT(*) AS n FROM users'))[0].n;
  const accounts = (await rows('SELECT COUNT(*) AS n FROM accounts'))[0].n;
  const profile = (await rows('SELECT COUNT(*) AS n FROM company_profile'))[0].n;
  assert.equal(Number(users), 0);
  assert.equal(Number(accounts), 0);
  assert.equal(Number(profile), 0);
});
