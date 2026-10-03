// Shared setup for API tests.
//
// Point the pool at the test database before anything opens a connection.
// config.db.database is a getter for exactly this reason.
process.env.DB_NAME = process.env.DB_TEST_NAME;

import { readFile } from 'node:fs/promises';

import { createApp } from '../../app.js';
import { openConnection, closePool } from '../../core/db.js';
import { splitSqlStatements } from '../../core/sql-split.js';
import { hashPassword } from '../../core/password.js';

// Phase 1 tables are listed first so they drop before the Phase 0 tables they
// point at. dropAll reverses this list, so the order here is creation order.
export const TABLES = [
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
  'taxes',
  'tax_rules',
  'vendors',
  'cheques',
  'transactions',
  'journal_lines',
  'transaction_taxes',
  'transaction_charges',
  'entry_flags',
  'attachments',
  'reimbursements',
  'reimbursement_items',
  'period_locks',
];

export const TEST_PASSWORD = 'test-password-1234';

export async function connect() {
  try {
    return await openConnection({ database: process.env.DB_TEST_NAME });
  } catch (error) {
    throw new Error(
      'Could not reach the database. Start it with: docker compose up -d\n' +
        `Original error: ${error.message}`,
    );
  }
}

export async function dropAll(connection) {
  await connection.query('SET FOREIGN_KEY_CHECKS = 0');
  for (const table of [...TABLES].reverse()) {
    await connection.query(`DROP TABLE IF EXISTS \`${table}\``);
  }
  await connection.query('SET FOREIGN_KEY_CHECKS = 1');
}

export async function applyMigration(connection, filename) {
  const sql = await readFile(new URL(`../../migrations/${filename}`, import.meta.url), 'utf8');
  for (const statement of splitSqlStatements(sql)) {
    await connection.query(statement);
  }
}

// 003 is deliberately not applied. It bootstraps the real owner login, and
// seedUsers below creates its own, which the one-owner constraint would refuse
// alongside it. Everything 003 seeds that tests need is created here instead.
export async function buildSchema(connection) {
  await dropAll(connection);
  await applyMigration(connection, '000_schema_migrations.sql');
  await applyMigration(connection, '001_phase0_tables.sql');
  await applyMigration(connection, '002_seed_reference.sql');
  await applyMigration(connection, '004_phase1_tables.sql');

  // The receipt rule is off unless a test turns it on. It is real company
  // policy, not a property of the schema, and leaving it on would make every
  // other suite about receipts.
  await connection.query(
    `UPDATE settings SET value = '0' WHERE setting_key = 'receipt_required_above'`,
  );
}

// One user per role, all with the same password, so tests can sign in as any
// of them without caring about the bootstrap migration. Maryam carries
// shares_owner_login, because she is the reason possible_self_approval exists.
export async function seedUsers(connection) {
  const hash = await hashPassword(TEST_PASSWORD);
  await connection.query(
    `INSERT INTO users (name, email, password_hash, role, is_active, shares_owner_login) VALUES
       ('Winibex office', 'owner@test.local',    ?, 'owner', 1, 0),
       ('Admin person',   'admin@test.local',    ?, 'admin', 1, 0),
       ('Maryam',         'staff@test.local',    ?, 'staff', 1, 1),
       ('Former person',  'inactive@test.local', ?, 'staff', 0, 0)`,
    [hash, hash, hash, hash],
  );
}

// The company accounts migration 003 would have created, built from the
// seeded chart of accounts so the ledger codes are the real ones.
export async function seedAccounts(connection) {
  await connection.query(
    `INSERT INTO accounts (name, type, coa_id, opening_date)
     SELECT seed.name, seed.type, coa.id, '2025-03-01'
     FROM (
                 SELECT 'Winibex bank' AS name, 'bank'       AS type, '1113' AS code
       UNION ALL SELECT 'Office cash',       'cash',       '1111'
       UNION ALL SELECT 'Petty cash',        'petty_cash', '1112'
     ) AS seed
     JOIN chart_of_accounts coa ON coa.code = seed.code`,
  );
}

export async function accountId(connection, name = 'Winibex bank') {
  const [rows] = await connection.query('SELECT id FROM accounts WHERE name = ?', [name]);
  return Number(rows[0].id);
}

export async function categoryId(connection, direction = 'out') {
  const [rows] = await connection.query(
    'SELECT id FROM categories WHERE direction = ? LIMIT 1',
    [direction],
  );
  return Number(rows[0].id);
}

export async function userId(connection, email) {
  const [rows] = await connection.query('SELECT id FROM users WHERE email = ?', [email]);
  return Number(rows[0].id);
}

// Starts the real app on an ephemeral port and returns a tiny fetch wrapper.
export async function startServer() {
  const app = createApp();
  const server = await new Promise((resolve) => {
    const listener = app.listen(0, '127.0.0.1', () => resolve(listener));
  });

  const { port } = server.address();
  const base = `http://127.0.0.1:${port}/api/v1`;

  async function call(method, path, { body, token, headers = {} } = {}) {
    const response = await fetch(`${base}${path}`, {
      method,
      headers: {
        'content-type': 'application/json',
        ...(token ? { authorization: `Bearer ${token}` } : {}),
        ...headers,
      },
      body: body === undefined ? undefined : JSON.stringify(body),
    });

    const text = await response.text();
    let json = null;
    try {
      json = text ? JSON.parse(text) : null;
    } catch {
      json = null;
    }

    return { status: response.status, body: json, raw: text, headers: response.headers };
  }

  // Multipart, for receipt uploads. Content-Type must not be set by hand: the
  // boundary is generated with the body and the server needs the matching one.
  async function upload(path, { token, file, filename, mime, fields = {} } = {}) {
    const form = new globalThis.FormData();
    form.append('file', new globalThis.Blob([file], { type: mime }), filename);
    for (const [key, value] of Object.entries(fields)) form.append(key, value);

    const response = await fetch(`${base}${path}`, {
      method: 'POST',
      headers: token ? { authorization: `Bearer ${token}` } : {},
      body: form,
    });

    const text = await response.text();
    let json = null;
    try {
      json = text ? JSON.parse(text) : null;
    } catch {
      json = null;
    }
    return { status: response.status, body: json, raw: text, headers: response.headers };
  }

  return {
    base,
    get: (path, options) => call('GET', path, options),
    post: (path, options) => call('POST', path, options),
    patch: (path, options) => call('PATCH', path, options),
    upload,
    async close() {
      await new Promise((resolve) => server.close(resolve));
      await closePool();
    },
  };
}

export async function signIn(api, email, password = TEST_PASSWORD) {
  const response = await api.post('/auth/login', { body: { email, password } });
  return response;
}

// Every money-creating request needs its own key. The client generates one
// when the form opens; a test generates one per call unless it is deliberately
// reusing one. Decision 024.
export function idempotencyKey() {
  return { 'idempotency-key': crypto.randomUUID() };
}
