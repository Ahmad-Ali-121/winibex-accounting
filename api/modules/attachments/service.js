// Receipts and bank advices.
//
// A receipt can be attached before or after an entry is posted. That is on
// purpose: the photo is often taken later, and refusing it afterwards would
// mean entries with no evidence rather than entries with late evidence. The
// entry itself stays immutable either way; an attachment is a separate row.
//
// Nothing is ever deleted. Decision 007, and ten years of records under the
// Companies Act 2017.

import { withTransaction, getPool } from '../../core/db.js';
import { writeAudit, AuditAction } from '../../core/audit.js';
import { ErrorCode, badRequest, notFound } from '../../core/errors.js';
import { hashFile, relativeTo, absoluteFrom, streamFile, discard } from '../../core/uploads.js';
import * as repo from './repository.js';

const DOCUMENT_TYPES = new Set([
  'receipt', 'bank_advice', 'bank_statement', 'tax_certificate',
  'invoice_received', 'contract', 'other',
]);

function present(row) {
  return {
    id: Number(row.id),
    transactionId: Number(row.transaction_id),
    documentType: row.document_type,
    mime: row.mime,
    sizeBytes: Number(row.size_bytes),
    sha256: row.sha256,
    retainUntil: row.retain_until,
    uploadedByName: row.uploaded_by_name,
    createdAt: row.created_at,
  };
}

export async function listFor(transactionId) {
  const rows = await repo.listFor(getPool(), transactionId);
  return { attachments: rows.map(present) };
}

/**
 * Records an uploaded file against an entry.
 *
 * The file is already on disk by the time this runs: multer wrote it. If the
 * database write fails, the file is removed, because a file with no record is
 * invisible and would sit there forever.
 */
export async function attach({ user, transactionId, file, documentType = 'receipt', ip = null }) {
  if (!file) throw badRequest(ErrorCode.VALIDATION_FAILED, 'No file was sent.', { field: 'file' });

  if (!DOCUMENT_TYPES.has(documentType)) {
    await discard(file.path);
    throw badRequest(ErrorCode.VALIDATION_FAILED, 'That is not a document type we store.');
  }

  const entry = await repo.retainUntilFor(getPool(), transactionId);
  if (!entry) {
    await discard(file.path);
    throw notFound('That entry does not exist.');
  }

  try {
    const sha256 = await hashFile(file.path);

    const id = await withTransaction(async (connection) => {
      const attachmentId = await repo.insert(connection, {
        transactionId,
        documentType,
        filePath: relativeTo(file.path),
        mime: file.mimetype,
        sizeBytes: file.size,
        sha256,
        uploadedBy: user.id,
        retainUntil: entry.retain_until,
      });

      await writeAudit(connection, {
        userId: user.id, ip, table: 'attachments', recordId: attachmentId,
        action: AuditAction.INSERT,
        after: { transactionId, documentType, sizeBytes: file.size, sha256 },
      });

      return attachmentId;
    });

    const rows = await repo.listFor(getPool(), transactionId);
    return present(rows.find((row) => Number(row.id) === id));
  } catch (error) {
    // The row never landed, so the file on disk belongs to nothing.
    await discard(file.path);
    throw error;
  }
}

/// Returns what the route needs to stream the file back. Never a path the
/// caller supplied: the path comes from the database row.
export async function openFile(id) {
  const row = await repo.findById(getPool(), id);
  if (!row) throw notFound('That attachment does not exist.');

  return {
    stream: streamFile(absoluteFrom(row.file_path)),
    mime: row.mime,
    sizeBytes: Number(row.size_bytes),
  };
}

/**
 * Whether an entry may post without a receipt.
 *
 * A payment above the threshold needs evidence, because an expense with no
 * receipt is one an auditor will disallow and one FBR can treat as
 * unexplained. The threshold is a setting, not a constant.
 */
export async function assertReceiptRules(connection, entry) {
  const { transactionId, amount, direction, entryType = 'normal', transferGroupId = null, categoryId = null } = entry;

  // Money coming in has no receipt to attach; the bank advice is the evidence
  // and it is a different document.
  if (direction !== 'out') return;

  // A transfer between the company's own accounts is not a purchase. Neither
  // is the opening entry or a manual journal.
  if (transferGroupId) return;
  if (entryType !== 'normal') return;

  // Paying someone back, or moving money through the transit account, settles
  // something already recorded. The receipts were attached to the costs
  // themselves, which is where an auditor would look for them.
  if (categoryId) {
    const [category] = await connection.query(
      `SELECT a.code FROM categories c JOIN chart_of_accounts a ON a.id = c.coa_id WHERE c.id = ?`,
      [categoryId],
    );
    if (['2114', '1118'].includes(category[0]?.code)) return;
  }

  const [rows] = await connection.query(
    `SELECT value FROM settings WHERE setting_key = 'receipt_required_above'`,
  );
  const threshold = Number(rows[0]?.value ?? 0);
  if (threshold <= 0 || amount < threshold) return;

  if (!(await repo.hasReceipt(connection, transactionId))) {
    throw badRequest(
      ErrorCode.RECEIPT_REQUIRED,
      `A payment of this size needs a receipt attached before it can be posted.`,
      { details: { threshold } },
    );
  }
}
