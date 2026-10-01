// The splitter decides where one statement ends and the next begins. Get it
// wrong and a migration applies halfway. These run without a database.

import test from 'node:test';
import assert from 'node:assert/strict';

import { splitSqlStatements, isOnlyComments } from '../core/sql-split.js';

test('splits plain statements on the semicolon', () => {
  const parts = splitSqlStatements('SELECT 1; SELECT 2;');
  assert.deepEqual(parts, ['SELECT 1', 'SELECT 2']);
});

test('a trailing statement without a semicolon still counts', () => {
  assert.deepEqual(splitSqlStatements('SELECT 1'), ['SELECT 1']);
});

test('comment-only files produce no statements', () => {
  assert.deepEqual(splitSqlStatements('-- nothing here\n#  or here\n'), []);
  assert.deepEqual(splitSqlStatements('/* block */'), []);
  assert.equal(isOnlyComments('-- just a note'), true);
  assert.equal(isOnlyComments('SELECT 1'), false);
});

test('a semicolon inside a string is not a split point', () => {
  const parts = splitSqlStatements("INSERT INTO t (note) VALUES ('a; b'); SELECT 1;");
  assert.equal(parts.length, 2);
  assert.ok(parts[0].includes("'a; b'"));
});

test('a semicolon inside a comment is not a split point', () => {
  const parts = splitSqlStatements('SELECT 1 -- careful; here\n; SELECT 2;');
  assert.equal(parts.length, 2);
});

test('an escaped quote does not end the string early', () => {
  const parts = splitSqlStatements("SELECT 'it\\'s fine; really'; SELECT 2;");
  assert.equal(parts.length, 2);
});

test('a doubled quote does not end the string early', () => {
  const parts = splitSqlStatements("SELECT 'it''s fine; really'; SELECT 2;");
  assert.equal(parts.length, 2);
});

test('backtick identifiers are left alone', () => {
  const parts = splitSqlStatements('SELECT `odd;name` FROM t; SELECT 2;');
  assert.equal(parts.length, 2);
});

// This is the case the whole file exists for. Migration 002 carries the
// posted-row immutability trigger, whose body is full of semicolons.
test('DELIMITER keeps a trigger body in one piece', () => {
  const sql = `
CREATE TABLE t (id INT);

DELIMITER $$

CREATE TRIGGER trg_block_posted_update
BEFORE UPDATE ON transactions
FOR EACH ROW
BEGIN
  IF OLD.status = 'posted' THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'A posted transaction cannot be changed. Reverse it instead.';
  END IF;
END$$

DELIMITER ;

INSERT INTO schema_migrations (filename) VALUES ('002_transactions.sql');
`;

  const parts = splitSqlStatements(sql);
  assert.equal(parts.length, 3);
  assert.ok(parts[0].startsWith('CREATE TABLE'));
  assert.ok(parts[1].startsWith('CREATE TRIGGER'));
  assert.ok(parts[1].includes('END IF'), 'the trigger body was cut in half');
  assert.ok(parts[2].startsWith('INSERT INTO schema_migrations'));
});

test('the real migration 000 splits into exactly two statements', async () => {
  const { readFile } = await import('node:fs/promises');
  const url = new URL('../migrations/000_schema_migrations.sql', import.meta.url);
  const parts = splitSqlStatements(await readFile(url, 'utf8'));

  assert.equal(parts.length, 2);
  assert.ok(parts[0].startsWith('CREATE TABLE IF NOT EXISTS schema_migrations'));
  assert.ok(parts[1].startsWith('INSERT INTO schema_migrations'));
});

test('leading comments are stripped but executable comments survive', () => {
  const parts = splitSqlStatements(
    '-- a note\n# another\n/* and a block */\nSELECT 1;\n/*!40101 SET NAMES utf8mb4 */;',
  );
  assert.deepEqual(parts[0], 'SELECT 1');
  assert.ok(parts[1].startsWith('/*!40101'));
});
