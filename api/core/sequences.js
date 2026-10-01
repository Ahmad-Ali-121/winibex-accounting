// Gapless numbering for journal entries, invoices, quotations, receipts and
// payment vouchers. A gap in a numbered series is the first thing an auditor
// asks about, so the number is allocated inside the same transaction as the
// row that uses it. If the insert rolls back, the counter rolls back with it
// and the number is handed out again.
//
// This is why MariaDB's own SEQUENCE objects are not used: they allocate
// outside the transaction, deliberately, and leave holes.
//
// SELECT ... FOR UPDATE holds a row lock for the rest of the transaction, so
// two requests allocating at once are serialised rather than given the same
// number. Keep the transaction short.

import { assertInTransaction } from './db.js';

export const SEQUENCES = Object.freeze([
  'journal',
  'invoice',
  'quotation',
  'receipt',
  'voucher',
]);

export async function allocate(connection, name) {
  if (!SEQUENCES.includes(name)) {
    throw new Error(`Unknown sequence: ${name}`);
  }

  // Outside a transaction this would commit on its own and leak a number on
  // any later failure, which is exactly the bug it exists to prevent.
  await assertInTransaction(connection);

  const [rows] = await connection.query(
    'SELECT prefix, next_value FROM sequences WHERE name = ? FOR UPDATE',
    [name],
  );

  if (!rows[0]) {
    throw new Error(`Sequence "${name}" is not seeded`);
  }

  const value = Number(rows[0].next_value);
  const prefix = rows[0].prefix ?? '';

  await connection.query(
    'UPDATE sequences SET next_value = next_value + 1 WHERE name = ?',
    [name],
  );

  return { value, prefix, formatted: `${prefix}${value}` };
}

export async function peek(connection, name) {
  const [rows] = await connection.query(
    'SELECT prefix, next_value FROM sequences WHERE name = ?',
    [name],
  );
  if (!rows[0]) return null;
  return { value: Number(rows[0].next_value), prefix: rows[0].prefix ?? '' };
}
