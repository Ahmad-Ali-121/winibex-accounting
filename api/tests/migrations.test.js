// The runner, against the real test database. Applying twice must be safe,
// and an edited file that is already applied must be caught, because that
// means the database and the repository no longer agree.

import test, { before, after } from 'node:test';
import assert from 'node:assert/strict';
import process from 'node:process';
import { mkdtemp, writeFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';

import { openConnection, assertSession } from '../core/db.js';
import { plan, listMigrationFiles, checksumOf } from '../scripts/migrate.js';
import { splitSqlStatements } from '../core/sql-split.js';

let connection;
let workDir;

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

  await connection.query('DROP TABLE IF EXISTS schema_migrations');
  workDir = await mkdtemp(path.join(tmpdir(), 'winibex-migrations-'));
});

after(async () => {
  await connection?.query('DROP TABLE IF EXISTS schema_migrations');
  await connection?.query('DROP TABLE IF EXISTS probe_widgets');
  await connection?.end();
  if (workDir) await rm(workDir, { recursive: true, force: true });
});

async function applyFile(contents) {
  for (const statement of splitSqlStatements(contents)) {
    await connection.query(statement);
  }
}

test('the connection has strict mode and UTC', async () => {
  assert.equal(await assertSession(connection), true);
});

test('migration files are named so a plain sort gives the right order', async () => {
  const files = await listMigrationFiles();
  assert.ok(files.length > 0, 'no migration files found');
  for (const name of files) {
    assert.match(name, /^\d{3}_[a-z0-9_]+\.sql$/, `${name} is not numbered correctly`);
  }
  assert.deepEqual(files, [...files].sort());
});

test('with no ledger table, every migration reads as pending', async () => {
  const { entries } = await plan(connection);
  assert.ok(entries.length > 0);
  assert.ok(entries.every((entry) => entry.isApplied === false));
});

test('migration 000 applies, and applying it twice is harmless', async () => {
  const { readFile } = await import('node:fs/promises');
  const url = new URL('../migrations/000_schema_migrations.sql', import.meta.url);
  const contents = await readFile(url, 'utf8');

  await applyFile(contents);
  await applyFile(contents);

  const [rows] = await connection.query(
    'SELECT COUNT(*) AS total FROM schema_migrations WHERE filename = ?',
    ['000_schema_migrations.sql'],
  );
  assert.equal(Number(rows[0].total), 1, 'the file recorded itself twice');
});

test('an applied migration reads as applied', async () => {
  const { entries } = await plan(connection);
  const first = entries.find((entry) => entry.filename === '000_schema_migrations.sql');
  assert.equal(first.isApplied, true);
  assert.equal(first.changedSinceApplied, false);
});

test('a file edited after being applied is detected', async () => {
  await connection.query(
    `INSERT INTO schema_migrations (filename, checksum) VALUES (?, ?)
     ON DUPLICATE KEY UPDATE checksum = VALUES(checksum)`,
    ['000_schema_migrations.sql', checksumOf('something else entirely')],
  );

  const { entries } = await plan(connection);
  const first = entries.find((entry) => entry.filename === '000_schema_migrations.sql');
  assert.equal(first.changedSinceApplied, true);

  // Put it back so later runs are clean.
  await connection.query(
    'UPDATE schema_migrations SET checksum = ? WHERE filename = ?',
    [first.checksum, first.filename],
  );
});

test('a row with no file on disk is reported, not ignored', async () => {
  await connection.query('INSERT INTO schema_migrations (filename) VALUES (?)', [
    '999_deleted_by_someone.sql',
  ]);

  const { missingFiles } = await plan(connection);
  assert.ok(missingFiles.includes('999_deleted_by_someone.sql'));

  await connection.query('DELETE FROM schema_migrations WHERE filename = ?', [
    '999_deleted_by_someone.sql',
  ]);
});

test('a file recorded without a checksum is not treated as changed', async () => {
  // This is what every migration applied through phpMyAdmin looks like.
  await connection.query(
    'UPDATE schema_migrations SET checksum = NULL WHERE filename = ?',
    ['000_schema_migrations.sql'],
  );

  const { entries } = await plan(connection);
  const first = entries.find((entry) => entry.filename === '000_schema_migrations.sql');
  assert.equal(first.isApplied, true);
  assert.equal(first.changedSinceApplied, false);
});

test('a failing statement does not get recorded as applied', async () => {
  const filename = '900_deliberately_broken.sql';
  const broken = [
    'CREATE TABLE probe_widgets (id INT PRIMARY KEY);',
    'THIS IS NOT SQL;',
    `INSERT INTO schema_migrations (filename) VALUES ('${filename}');`,
  ].join('\n');

  await writeFile(path.join(workDir, filename), broken, 'utf8');

  await assert.rejects(() => applyFile(broken), /You have an error|syntax/i);

  const [rows] = await connection.query(
    'SELECT COUNT(*) AS total FROM schema_migrations WHERE filename = ?',
    [filename],
  );
  assert.equal(Number(rows[0].total), 0, 'a half-applied migration recorded itself');
});
