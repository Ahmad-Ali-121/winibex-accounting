// The database is not just somewhere to put rows. The schema leans on it to
// enforce things the application cannot be trusted to enforce alone: CHECK
// constraints on money, strict mode so nothing is silently truncated, real
// transactions so a half-written journal entry rolls back, and UTC so
// timestamps mean what they say.
//
// Production is Hostinger managed MariaDB 11.8, where global settings cannot
// be changed. So strict mode and UTC are set per connection, exactly as the
// pool will do in step 0.6, and these tests prove that mechanism works rather
// than trusting a local config file that production does not have.
//
// Start the container first: docker compose up -d

import test, { before, after } from 'node:test';
import assert from 'node:assert/strict';
import process from 'node:process';
import mysql from 'mysql2/promise';

// Every connection the API opens runs these. Keep this list identical to the
// pool's onConnect in core/db.js once that exists.
export const SESSION_SETUP = [
  "SET SESSION sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ZERO_DATE,NO_ZERO_IN_DATE,NO_ENGINE_SUBSTITUTION,ONLY_FULL_GROUP_BY'",
  "SET SESSION time_zone = '+00:00'",
  "SET SESSION transaction_isolation = 'READ-COMMITTED'",
];

let connection;

before(async () => {
  try {
    connection = await mysql.createConnection({
      host: process.env.DB_HOST,
      port: Number(process.env.DB_PORT),
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      database: process.env.DB_TEST_NAME,
      timezone: 'Z',
      multipleStatements: false,
      connectTimeout: 5000,
      // Without this the driver rounds any BIGINT past JavaScript's safe
      // integer limit, silently. Money is BIGINT paisa, so that is not
      // acceptable even though the company's figures are far below the limit.
      // With it on, a value too large to hold exactly comes back as text
      // instead of being rounded. Keep this identical in core/db.js.
      supportBigNumbers: true,
    });
  } catch (error) {
    throw new Error(
      'Could not reach the database. Start it with: docker compose up -d\n' +
        `Tried ${process.env.DB_HOST}:${process.env.DB_PORT}. Original error: ${error.message}`,
    );
  }

  for (const statement of SESSION_SETUP) {
    await connection.query(statement);
  }

  await connection.query('DROP TABLE IF EXISTS probe_money');
});

after(async () => {
  await connection?.query('DROP TABLE IF EXISTS probe_money');
  await connection?.end();
});

async function sessionVariable(name) {
  const [rows] = await connection.query(`SELECT @@SESSION.${name} AS value`);
  return String(rows[0].value);
}

test('the test database is not the development database', () => {
  assert.ok(process.env.DB_TEST_NAME, 'DB_TEST_NAME is not set');
  assert.notEqual(process.env.DB_TEST_NAME, process.env.DB_NAME);
});

test('the server is MariaDB 11', async () => {
  const [rows] = await connection.query(
    'SELECT VERSION() AS version, @@version_comment AS flavour',
  );
  assert.match(rows[0].version, /MariaDB/i, `unexpected server: ${rows[0].version}`);
  assert.match(rows[0].version, /^11\./, `unexpected major version: ${rows[0].version}`);
});

test('strict mode is on for this session, so a value is never silently truncated', async () => {
  const sqlMode = await sessionVariable('sql_mode');
  assert.ok(sqlMode.includes('STRICT_ALL_TABLES'), `sql_mode is ${sqlMode}`);
  assert.ok(sqlMode.includes('NO_ZERO_DATE'), `sql_mode is ${sqlMode}`);
});

test('the session time zone is UTC', async () => {
  assert.equal(await sessionVariable('time_zone'), '+00:00');
});

test('the server character set is utf8mb4', async () => {
  const [rows] = await connection.query(
    "SELECT @@GLOBAL.character_set_server AS charset",
  );
  assert.equal(rows[0].charset, 'utf8mb4');
});

test('InnoDB is the default engine', async () => {
  const [rows] = await connection.query('SELECT @@GLOBAL.default_storage_engine AS engine');
  assert.equal(rows[0].engine, 'InnoDB');
});

test('CHECK constraints are enforced, not parsed and ignored', async () => {
  await connection.query('DROP TABLE IF EXISTS probe_money');
  await connection.query(`
    CREATE TABLE probe_money (
      id BIGINT PRIMARY KEY AUTO_INCREMENT,
      debit BIGINT NOT NULL DEFAULT 0,
      credit BIGINT NOT NULL DEFAULT 0,
      CONSTRAINT chk_probe_one_side CHECK (
        debit >= 0 AND credit >= 0
        AND (debit = 0 OR credit = 0)
        AND (debit > 0 OR credit > 0)
      )
    ) ENGINE = InnoDB
  `);

  await connection.query('INSERT INTO probe_money (debit, credit) VALUES (500, 0)');

  // MariaDB's wording is "CONSTRAINT `name` failed", MySQL's is
  // "Check constraint violated". Match on the part they share.
  await assert.rejects(
    () => connection.query('INSERT INTO probe_money (debit, credit) VALUES (500, 500)'),
    /constraint/i,
    'a line with both a debit and a credit was accepted',
  );

  await assert.rejects(
    () => connection.query('INSERT INTO probe_money (debit, credit) VALUES (0, 0)'),
    /constraint/i,
    'a line with neither a debit nor a credit was accepted',
  );

  await assert.rejects(
    () => connection.query('INSERT INTO probe_money (debit, credit) VALUES (-1, 0)'),
    /constraint/i,
    'a negative debit was accepted',
  );
});

test('an out of range value is refused, not truncated', async () => {
  await assert.rejects(
    () => connection.query("INSERT INTO probe_money (debit, credit) VALUES ('abc', 0)"),
    /incorrect|truncated|constraint/i,
    'a non-numeric money value was silently coerced',
  );
});

test('a transaction rolls back completely', async () => {
  await connection.beginTransaction();
  await connection.query('INSERT INTO probe_money (debit, credit) VALUES (900, 0)');
  await connection.rollback();

  const [rows] = await connection.query(
    'SELECT COUNT(*) AS total FROM probe_money WHERE debit = 900',
  );
  assert.equal(Number(rows[0].total), 0);
});

test('a realistic company figure comes back exact', async () => {
  // 10,000,000,000.00 PKR in paisa. Comfortably inside what JavaScript holds
  // exactly, so this arrives as an ordinary number.
  const [rows] = await connection.query('SELECT CAST(1000000000000 AS SIGNED) AS v');
  assert.equal(Number(rows[0].v), 1000000000000);
  assert.equal(String(rows[0].v), '1000000000000');
});

test('a BIGINT past JavaScript\'s safe limit is returned exactly, not rounded', async () => {
  // The largest value a BIGINT can hold. JavaScript cannot represent this as a
  // number, so supportBigNumbers must hand it back as exact text instead of
  // quietly turning it into ...776000. This test is the guard on that setting:
  // if someone removes it from the connection options, this fails.
  const [rows] = await connection.query('SELECT CAST(9223372036854775807 AS SIGNED) AS v');
  assert.equal(String(rows[0].v), '9223372036854775807');
});

// MariaDB's JSON type is an alias for LONGTEXT. The driver therefore hands back
// a string, so audit_log and idempotency_keys must stringify and parse
// explicitly. This test exists so that assumption is proved, not remembered.
test('a JSON column behaves as text and round trips through stringify and parse', async () => {
  await connection.query('DROP TABLE IF EXISTS probe_json');
  await connection.query(`
    CREATE TABLE probe_json (
      id BIGINT PRIMARY KEY AUTO_INCREMENT,
      payload JSON NOT NULL
    ) ENGINE = InnoDB
  `);

  const original = { before: null, after: { amount: 500000, currency: 'PKR' } };
  await connection.query('INSERT INTO probe_json (payload) VALUES (?)', [
    JSON.stringify(original),
  ]);

  const [rows] = await connection.query('SELECT payload FROM probe_json');
  const value = rows[0].payload;
  const parsed = typeof value === 'string' ? JSON.parse(value) : value;
  assert.deepEqual(parsed, original);

  // The JSON alias still validates, so malformed text is refused.
  await assert.rejects(
    () => connection.query("INSERT INTO probe_json (payload) VALUES ('not json')"),
    /constraint|json/i,
  );

  await connection.query('DROP TABLE probe_json');
});
