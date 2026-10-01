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

export async function buildSchema(connection) {
  await dropAll(connection);
  await applyMigration(connection, '000_schema_migrations.sql');
  await applyMigration(connection, '001_phase0_tables.sql');
  await applyMigration(connection, '002_seed_reference.sql');
}

// One user per role, all with the same password, so tests can sign in as any
// of them without caring about the bootstrap migration.
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

  return {
    base,
    get: (path, options) => call('GET', path, options),
    post: (path, options) => call('POST', path, options),
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
