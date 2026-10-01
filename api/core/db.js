// The database pool.
//
// Hostinger does not let us change global settings on the server, so every
// connection sets its own strict mode, time zone and isolation level. If these
// are wrong the database silently truncates money instead of refusing it, so
// assertSession() checks them at startup rather than trusting the SET.

import mysql from 'mysql2/promise';
import { config } from './config.js';

export const SESSION_SQL_MODE =
  'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ZERO_DATE,NO_ZERO_IN_DATE,NO_ENGINE_SUBSTITUTION,ONLY_FULL_GROUP_BY';

export const SESSION_SETUP = [
  `SET SESSION sql_mode = '${SESSION_SQL_MODE}'`,
  "SET SESSION time_zone = '+00:00'",
  "SET SESSION transaction_isolation = 'READ-COMMITTED'",
];

export function connectionOptions(overrides = {}) {
  return {
    host: config.db.host,
    port: config.db.port,
    user: config.db.user,
    password: config.db.password,
    database: config.db.database,

    // Without this the driver rounds a BIGINT past JavaScript's safe integer
    // limit with no error. Money is BIGINT paisa. Decision 044.
    supportBigNumbers: true,

    // Timestamps are UTC everywhere.
    timezone: 'Z',

    // Removes a whole class of injection. The migration runner is the only
    // thing that needs more than one statement, and it sends them one by one.
    multipleStatements: false,

    dateStrings: ['DATE'],
    charset: 'utf8mb4',
    connectTimeout: 10000,
    ...overrides,
  };
}

let pool = null;

export function getPool() {
  if (pool) return pool;

  pool = mysql.createPool({
    ...connectionOptions(),
    waitForConnections: true,
    connectionLimit: config.db.connectionLimit,
    queueLimit: 0,
    enableKeepAlive: true,
  });

  // Runs once per physical connection, including replacements the pool makes
  // later. assertSession() is what proves it actually worked.
  pool.on('connection', (connection) => {
    for (const statement of SESSION_SETUP) {
      connection.query(statement);
    }
  });

  return pool;
}

export async function closePool() {
  if (!pool) return;
  const closing = pool;
  pool = null;
  await closing.end();
}

// Opens a standalone connection with the session settings applied. Used by the
// migration runner and by tests, which must not share the pool.
export async function openConnection(overrides = {}) {
  const connection = await mysql.createConnection(connectionOptions(overrides));
  for (const statement of SESSION_SETUP) {
    await connection.query(statement);
  }
  return connection;
}

export async function assertSession(runner = getPool()) {
  const [rows] = await runner.query(
    'SELECT @@SESSION.sql_mode AS sqlMode, @@SESSION.time_zone AS timeZone',
  );
  const { sqlMode, timeZone } = rows[0];

  if (!String(sqlMode).includes('STRICT_ALL_TABLES')) {
    throw new Error(`Strict mode is not on for this connection. sql_mode is ${sqlMode}`);
  }
  if (String(timeZone) !== '+00:00') {
    throw new Error(`Connection time zone is ${timeZone}, expected +00:00`);
  }
  return true;
}

// Every write goes through here. The callback is handed one connection and
// must use it for everything, because work sent to the pool instead would run
// outside the transaction and would not roll back with it.
//
// A posting writes the transaction, its tax and charge lines, its journal
// lines and the audit entry. Either all of that lands or none of it does.
export async function withTransaction(callback, { pool = getPool() } = {}) {
  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();
    const result = await callback(connection);
    await connection.commit();
    return result;
  } catch (error) {
    try {
      await connection.rollback();
    } catch (rollbackError) {
      // The original error is the useful one. Losing it to a rollback failure
      // would hide why the write failed in the first place.
      console.error('Rollback failed:', rollbackError);
    }
    throw error;
  } finally {
    connection.release();
  }
}

// DDL commits implicitly, so a migration cannot be rolled back. Anything that
// calls this and then runs CREATE or ALTER is lying to itself.
export async function assertInTransaction(connection) {
  const [rows] = await connection.query('SELECT @@in_transaction AS inside');
  if (Number(rows[0].inside) !== 1) {
    throw new Error('This must run inside a transaction. Use withTransaction().');
  }
}

export async function ping() {
  const [rows] = await getPool().query('SELECT VERSION() AS version');
  return rows[0].version;
}
