// All SQL for attachments.

import { getPool } from '../../core/db.js';

export async function insert(runner, attachment) {
  const [result] = await runner.query(
    `INSERT INTO attachments
       (transaction_id, document_type, file_path, mime, size_bytes, sha256,
        uploaded_by, retain_until)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      attachment.transactionId, attachment.documentType, attachment.filePath,
      attachment.mime, attachment.sizeBytes, attachment.sha256,
      attachment.uploadedBy, attachment.retainUntil,
    ],
  );
  return Number(result.insertId);
}

export async function listFor(runner = getPool(), transactionId) {
  const [rows] = await runner.query(
    `SELECT a.id, a.transaction_id, a.document_type, a.mime, a.size_bytes,
            a.sha256, a.retain_until, a.created_at, u.name AS uploaded_by_name
       FROM attachments a
       JOIN users u ON u.id = a.uploaded_by
      WHERE a.transaction_id = ?
      ORDER BY a.id`,
    [transactionId],
  );
  return rows;
}

export async function findById(runner = getPool(), id) {
  const [rows] = await runner.query(
    `SELECT id, transaction_id, document_type, file_path, mime, size_bytes, sha256
       FROM attachments WHERE id = ?`,
    [id],
  );
  return rows[0] ?? null;
}

export async function hasReceipt(runner = getPool(), transactionId) {
  const [rows] = await runner.query(
    `SELECT id FROM attachments
      WHERE transaction_id = ? AND document_type = 'receipt' LIMIT 1`,
    [transactionId],
  );
  return rows.length > 0;
}

// Ten financial years after the entry's own date, not after today. The
// Companies Act 2017 counts from the transaction, and a receipt uploaded late
// must not expire earlier than the entry it belongs to.
export async function retainUntilFor(runner = getPool(), transactionId) {
  const [rows] = await runner.query(
    `SELECT DATE_ADD(date, INTERVAL 10 YEAR) AS retain_until, amount, direction, status
       FROM transactions WHERE id = ?`,
    [transactionId],
  );
  return rows[0] ?? null;
}
