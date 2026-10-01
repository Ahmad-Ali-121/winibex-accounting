// Applies migration files in order.
//
//   npm run migrate            shows what is applied and what is pending
//   npm run migrate:up         applies everything pending
//   npm run migrate:up -- --to 002_transactions.sql    stops after that file
//
// Production is different. Hostinger has no migration CLI, so the same files
// are pasted into phpMyAdmin in order. That works because every file records
// itself in schema_migrations as its last statement, and because the files use
// the DELIMITER directive phpMyAdmin understands.
//
// Migrations are not wrapped in a transaction. MariaDB commits implicitly on
// every CREATE, ALTER and DROP, so a transaction would be a false promise. The
// protection is that each file is small, ordered, and recorded.

import { readFile, readdir } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath, pathToFileURL } from 'node:url';

import { assertConfig, config } from '../core/config.js';
import { openConnection, assertSession } from '../core/db.js';
import { splitSqlStatements } from '../core/sql-split.js';

const MIGRATIONS_DIR = fileURLToPath(new URL('../migrations/', import.meta.url));

export function checksumOf(contents) {
  return createHash('sha256').update(contents, 'utf8').digest('hex');
}

export async function listMigrationFiles(directory = MIGRATIONS_DIR) {
  const entries = await readdir(directory);
  return entries.filter((name) => name.endsWith('.sql')).sort();
}

async function appliedRows(connection) {
  const [tables] = await connection.query(
    'SELECT COUNT(*) AS present FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = ?',
    ['schema_migrations'],
  );
  if (Number(tables[0].present) === 0) return new Map();

  const [rows] = await connection.query(
    'SELECT filename, applied_at, checksum FROM schema_migrations',
  );
  return new Map(rows.map((row) => [row.filename, row]));
}

export async function plan(connection, directory = MIGRATIONS_DIR) {
  const files = await listMigrationFiles(directory);
  const applied = await appliedRows(connection);

  const entries = [];
  for (const filename of files) {
    const contents = await readFile(path.join(directory, filename), 'utf8');
    const checksum = checksumOf(contents);
    const row = applied.get(filename);

    entries.push({
      filename,
      contents,
      checksum,
      isApplied: Boolean(row),
      appliedAt: row?.applied_at ?? null,
      // A file edited after it was applied is a real problem: the database and
      // the repository no longer agree. Null means it went in through
      // phpMyAdmin, where no checksum is recorded.
      changedSinceApplied: Boolean(row?.checksum) && row.checksum !== checksum,
    });
  }

  const missingFiles = [...applied.keys()].filter(
    (name) => !files.includes(name),
  );

  return { entries, missingFiles };
}

async function applyOne(connection, entry) {
  const statements = splitSqlStatements(entry.contents);
  if (statements.length === 0) {
    throw new Error(`${entry.filename} contains no statements`);
  }

  for (const [position, statement] of statements.entries()) {
    try {
      await connection.query(statement);
    } catch (error) {
      throw new Error(
        `${entry.filename} failed at statement ${position + 1} of ${statements.length}:\n` +
          `${statement.slice(0, 300)}\n\n${error.message}`,
      );
    }
  }

  // The file inserts its own row. The runner adds the checksum so a later edit
  // can be spotted. Applied through phpMyAdmin this stays null, which is fine.
  await connection.query(
    `INSERT INTO schema_migrations (filename, checksum)
     VALUES (?, ?)
     ON DUPLICATE KEY UPDATE checksum = VALUES(checksum)`,
    [entry.filename, entry.checksum],
  );

  return statements.length;
}

function describe(entry) {
  if (entry.changedSinceApplied) return 'CHANGED SINCE APPLIED';
  if (entry.isApplied) return 'applied';
  return 'pending';
}

async function main() {
  assertConfig();

  const command = process.argv[2] ?? 'status';
  const toIndex = process.argv.indexOf('--to');
  const stopAfter = toIndex === -1 ? null : process.argv[toIndex + 1];

  const connection = await openConnection();
  try {
    await assertSession(connection);
    console.log(`Database: ${config.db.database} on ${config.db.host}:${config.db.port}\n`);

    const { entries, missingFiles } = await plan(connection);

    for (const entry of entries) {
      console.log(`  ${describe(entry).padEnd(22)} ${entry.filename}`);
    }

    for (const filename of missingFiles) {
      console.log(`  ${'RECORDED BUT FILE GONE'.padEnd(22)} ${filename}`);
    }

    const changed = entries.filter((entry) => entry.changedSinceApplied);
    if (changed.length > 0) {
      throw new Error(
        'These files were edited after being applied: ' +
          `${changed.map((entry) => entry.filename).join(', ')}. ` +
          'Write a new migration instead of editing an applied one.',
      );
    }

    const pending = entries.filter((entry) => !entry.isApplied);

    if (command === 'status') {
      console.log(`\n${pending.length} pending.`);
      return;
    }

    if (command !== 'up') {
      throw new Error(`Unknown command "${command}". Use status or up.`);
    }

    if (pending.length === 0) {
      console.log('\nNothing to apply.');
      return;
    }

    console.log('');
    for (const entry of pending) {
      const count = await applyOne(connection, entry);
      console.log(`  applied ${entry.filename} (${count} statements)`);
      if (stopAfter && entry.filename === stopAfter) break;
    }
    console.log('\nDone.');
  } finally {
    await connection.end();
  }
}

// Only runs when invoked directly, so the functions above stay importable
// from tests without opening a connection.
if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main().catch((error) => {
    console.error(`\n${error.message}`);
    process.exit(1);
  });
}
