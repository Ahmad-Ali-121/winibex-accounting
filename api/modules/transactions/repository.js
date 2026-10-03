// All SQL for transactions. Nothing else in the feature talks to the database.
//
// Every function takes a `runner` first: either a pooled connection from
// withTransaction, or the pool itself for a plain read. A write must always be
// given the transaction's connection, because work sent to the pool instead
// would run outside the transaction and would not roll back with it.

import { getPool } from '../../core/db.js';

const TRANSACTION_COLUMNS = [
  'date', 'account_id', 'direction', 'amount', 'currency', 'foreign_amount',
  'fx_rate', 'fx_rate_source', 'method', 'description', 'category_id',
  'client_id', 'project_id', 'is_rebillable', 'fund_source', 'paid_by_type',
  'paid_by_user_id', 'received_by_user_id', 'vendor_id', 'cheque_id',
  'gross_amount', 'tax_total', 'charges_total', 'withheld_total', 'reference',
  'transfer_group_id', 'status', 'entry_type', 'created_by',
];

export async function insertTransaction(runner, fields) {
  const columns = TRANSACTION_COLUMNS.filter((name) => fields[name] !== undefined);
  const [result] = await runner.query(
    `INSERT INTO transactions (${columns.join(', ')})
     VALUES (${columns.map(() => '?').join(', ')})`,
    columns.map((name) => fields[name]),
  );
  return Number(result.insertId);
}

export async function insertJournalLines(runner, transactionId, lines) {
  if (lines.length === 0) return 0;
  const [result] = await runner.query(
    `INSERT INTO journal_lines (transaction_id, coa_id, debit, credit, line_no, memo)
     VALUES ${lines.map(() => '(?, ?, ?, ?, ?, ?)').join(', ')}`,
    lines.flatMap((line) => [transactionId, line.coaId, line.debit, line.credit, line.lineNo, line.memo ?? null]),
  );
  return result.affectedRows;
}

export async function insertTaxLines(runner, transactionId, taxes) {
  if (taxes.length === 0) return 0;
  const [result] = await runner.query(
    `INSERT INTO transaction_taxes
       (transaction_id, tax_id, base_amount, rate_applied, atl_status_used,
        atl_party, tax_amount, is_override, deducted_by)
     VALUES ${taxes.map(() => '(?, ?, ?, ?, ?, ?, ?, ?, ?)').join(', ')}`,
    taxes.flatMap((tax) => [
      transactionId, tax.taxId, tax.baseAmount, tax.rateApplied, tax.atlStatusUsed,
      tax.atlParty, tax.amount, tax.isOverride ? 1 : 0, tax.deductedBy,
    ]),
  );
  return result.affectedRows;
}

export async function insertChargeLines(runner, transactionId, charges) {
  if (charges.length === 0) return 0;
  const [result] = await runner.query(
    `INSERT INTO transaction_charges (transaction_id, type, amount, coa_id, note)
     VALUES ${charges.map(() => '(?, ?, ?, ?, ?)').join(', ')}`,
    charges.flatMap((charge) => [transactionId, charge.type, charge.amount, charge.coaId, charge.note ?? null]),
  );
  return result.affectedRows;
}

// FOR UPDATE holds the row for the rest of the transaction, so two people
// approving the same entry at once are serialised rather than both posting it.
export async function lockById(runner, id) {
  const [rows] = await runner.query('SELECT * FROM transactions WHERE id = ? FOR UPDATE', [id]);
  return rows[0] ?? null;
}

export async function findById(runner = getPool(), id) {
  const [rows] = await runner.query('SELECT * FROM transactions WHERE id = ?', [id]);
  return rows[0] ?? null;
}

export async function findDetail(runner = getPool(), id) {
  const transaction = await findById(runner, id);
  if (!transaction) return null;

  const [lines] = await runner.query(
    'SELECT coa_id, debit, credit, line_no, memo FROM journal_lines WHERE transaction_id = ? ORDER BY line_no',
    [id],
  );
  const [taxes] = await runner.query(
    'SELECT * FROM transaction_taxes WHERE transaction_id = ? ORDER BY id',
    [id],
  );
  const [charges] = await runner.query(
    'SELECT * FROM transaction_charges WHERE transaction_id = ? ORDER BY id',
    [id],
  );
  return { transaction, lines, taxes, charges };
}

export async function updateDraft(runner, id, fields) {
  const columns = TRANSACTION_COLUMNS.filter(
    (name) => fields[name] !== undefined && name !== 'created_by' && name !== 'status',
  );
  if (columns.length === 0) return 0;

  const [result] = await runner.query(
    `UPDATE transactions SET ${columns.map((name) => `${name} = ?`).join(', ')}
     WHERE id = ? AND status = 'draft'`,
    [...columns.map((name) => fields[name]), id],
  );
  return result.affectedRows;
}

export async function deleteChildRows(runner, id) {
  await runner.query('DELETE FROM transaction_taxes WHERE transaction_id = ?', [id]);
  await runner.query('DELETE FROM transaction_charges WHERE transaction_id = ?', [id]);
}

export async function setStatus(runner, id, status, extra = {}) {
  const fields = { status, ...extra };
  const columns = Object.keys(fields);
  const [result] = await runner.query(
    `UPDATE transactions SET ${columns.map((name) => `${name} = ?`).join(', ')} WHERE id = ?`,
    [...columns.map((name) => fields[name]), id],
  );
  return result.affectedRows;
}

// Posting writes the number, the time, the approver and the status together,
// because the CHECK constraint refuses a posted row missing any of them.
export async function markPosted(runner, id, { journalNumber, approvedBy, approvalMethod, possibleSelfApproval }) {
  const [result] = await runner.query(
    `UPDATE transactions
        SET status = 'posted', journal_number = ?, posted_at = UTC_TIMESTAMP(),
            approved_by = ?, approval_method = ?, possible_self_approval = ?
      WHERE id = ? AND status IN ('draft', 'pending')`,
    [journalNumber, approvedBy, approvalMethod, possibleSelfApproval ? 1 : 0, id],
  );
  return result.affectedRows;
}

export async function markReversed(runner, id, reversalId) {
  const [result] = await runner.query(
    `UPDATE transactions SET status = 'reversed', reversed_by_id = ?
      WHERE id = ? AND status = 'posted'`,
    [reversalId, id],
  );
  return result.affectedRows;
}

// --- ledger lookups ---------------------------------------------------------

export async function coaIdByCode(runner, code) {
  const [rows] = await runner.query('SELECT id FROM chart_of_accounts WHERE code = ?', [code]);
  return rows[0] ? Number(rows[0].id) : null;
}

export async function accountCoaId(runner, accountId) {
  const [rows] = await runner.query(
    'SELECT coa_id, is_active, opening_date, type, name FROM accounts WHERE id = ?',
    [accountId],
  );
  return rows[0] ?? null;
}

export async function categoryCoaId(runner, categoryId) {
  const [rows] = await runner.query(
    'SELECT coa_id, is_active, direction FROM categories WHERE id = ?',
    [categoryId],
  );
  return rows[0] ?? null;
}

export async function taxCoaIds(runner, taxIds) {
  if (taxIds.length === 0) return new Map();
  const [rows] = await runner.query(
    `SELECT id, coa_id FROM taxes WHERE id IN (${taxIds.map(() => '?').join(', ')})`,
    taxIds,
  );
  return new Map(rows.map((row) => [Number(row.id), Number(row.coa_id)]));
}

// --- what validation needs to ask the database ------------------------------

// A balance from the ledger, used to refuse cash going below zero and to warn
// about a bank account doing the same. Reversed entries count, because their
// lines stay in the book and are cancelled by the reversing entry.
export async function ledgerBalance(runner, coaId, { historyMerged, excludeId = null }) {
  const [rows] = await runner.query(
    `SELECT COALESCE(SUM(j.debit - j.credit), 0) AS balance
       FROM journal_lines j
       JOIN transactions t ON t.id = j.transaction_id
      WHERE j.coa_id = ?
        AND t.status IN ('posted', 'reversed')
        AND (? = 1 OR t.entry_type <> 'historical')
        AND (? IS NULL OR t.id <> ?)`,
    [coaId, historyMerged ? 1 : 0, excludeId, excludeId],
  );
  return Number(rows[0].balance);
}

export async function openingEntryExists(runner, excludeId = null) {
  const [rows] = await runner.query(
    `SELECT id FROM transactions
      WHERE entry_type = 'opening' AND status <> 'rejected'
        AND (? IS NULL OR id <> ?) LIMIT 1`,
    [excludeId, excludeId],
  );
  return rows.length > 0;
}

// Same amount, same account, within a few days. The caller shows the match, so
// the row itself comes back rather than a boolean.
export async function findSameAmountNearby(runner, { accountId, amount, date, days, excludeId }) {
  if (!accountId) return null;
  const [rows] = await runner.query(
    `SELECT id, journal_number, date, description FROM transactions
      WHERE account_id = ? AND amount = ?
        AND status IN ('draft', 'pending', 'posted')
        AND date BETWEEN DATE_SUB(?, INTERVAL ? DAY) AND DATE_ADD(?, INTERVAL ? DAY)
        AND (? IS NULL OR id <> ?)
      ORDER BY date DESC, id DESC LIMIT 1`,
    [accountId, amount, date, days, date, days, excludeId, excludeId],
  );
  return rows[0] ?? null;
}

export async function findSameDescription(runner, { description, amount, date, days, excludeId }) {
  const [rows] = await runner.query(
    `SELECT id, journal_number, date, description FROM transactions
      WHERE description = ? AND amount = ?
        AND status IN ('draft', 'pending', 'posted')
        AND date BETWEEN DATE_SUB(?, INTERVAL ? DAY) AND ?
        AND (? IS NULL OR id <> ?)
      ORDER BY date DESC, id DESC LIMIT 1`,
    [description, amount, date, days, date, excludeId, excludeId],
  );
  return rows[0] ?? null;
}

// What this category usually costs. Six months, posted entries only, and at
// least three of them before the average means anything.
export async function categoryAverage(runner, { categoryId, months, excludeId }) {
  const [rows] = await runner.query(
    `SELECT COUNT(*) AS n, COALESCE(AVG(amount), 0) AS average
       FROM transactions
      WHERE category_id = ? AND status = 'posted'
        AND date >= DATE_SUB(CURDATE(), INTERVAL ? MONTH)
        AND (? IS NULL OR id <> ?)`,
    [categoryId, months, excludeId, excludeId],
  );
  return { count: Number(rows[0].n), average: Number(rows[0].average) };
}

export async function lastRateFor(runner, currency, excludeId = null) {
  const [rows] = await runner.query(
    `SELECT id, fx_rate, date FROM transactions
      WHERE currency = ? AND fx_rate IS NOT NULL
        AND status IN ('posted', 'reversed')
        AND (? IS NULL OR id <> ?)
      ORDER BY date DESC, id DESC LIMIT 1`,
    [currency, excludeId, excludeId],
  );
  return rows[0] ?? null;
}

export async function hasReceipt(runner, transactionId) {
  const [rows] = await runner.query(
    `SELECT id FROM attachments WHERE transaction_id = ? AND document_type = 'receipt' LIMIT 1`,
    [transactionId],
  );
  return rows.length > 0;
}

export async function insertFlags(runner, transactionId, entries) {
  if (entries.length === 0) return 0;
  const [result] = await runner.query(
    `INSERT INTO entry_flags (transaction_id, severity, code, detail, acknowledged_by, acknowledged_at)
     VALUES ${entries.map(() => '(?, ?, ?, ?, ?, ?)').join(', ')}`,
    entries.flatMap((entry) => [
      transactionId,
      entry.severity,
      entry.code,
      (entry.detail ?? entry.message ?? '').slice(0, 255),
      entry.acknowledgedBy ?? null,
      entry.acknowledgedBy ? new Date() : null,
    ]),
  );
  return result.affectedRows;
}

export async function clearFlags(runner, transactionId) {
  await runner.query('DELETE FROM entry_flags WHERE transaction_id = ?', [transactionId]);
}

export async function readSettings(runner) {
  const [rows] = await runner.query(
    `SELECT setting_key, value FROM settings
      WHERE setting_key IN ('books_live_from', 'history_merged',
                            'large_cash_warning_above', 'fx_deviation_warning_percent',
                            'receipt_required_above')`,
  );
  const map = new Map(rows.map((row) => [row.setting_key, row.value]));
  return {
    booksLiveFrom: map.get('books_live_from') ?? '2026-07-01',
    historyMerged: map.get('history_merged') === 'true' || map.get('history_merged') === '1',
    largeCashWarningAbove: Number(map.get('large_cash_warning_above') ?? 5000000),
    fxDeviationWarningPercent: Number(map.get('fx_deviation_warning_percent') ?? 5),
    receiptRequiredAbove: Number(map.get('receipt_required_above') ?? 500000),
  };
}

// The category that posts to a given ledger code, in a given direction. Used
// by transfers, which must post to 1118 and cannot let a user pick anything
// else. Looked up by code rather than by name so a rename cannot break it.
export async function categoryForLedgerCode(runner, code, direction) {
  const [rows] = await runner.query(
    `SELECT c.id FROM categories c
       JOIN chart_of_accounts a ON a.id = c.coa_id
      WHERE a.code = ? AND c.direction = ? AND c.is_active = 1
      ORDER BY c.id LIMIT 1`,
    [code, direction],
  );
  return rows[0] ? Number(rows[0].id) : null;
}

export async function accountById(runner, id) {
  const [rows] = await runner.query(
    'SELECT id, name, type, coa_id, is_active FROM accounts WHERE id = ?',
    [id],
  );
  return rows[0] ?? null;
}

// Codes and names for a set of ledger account ids, so a journal preview can
// show "6400 Software subscriptions" rather than an id.
export async function describeLedgerAccounts(runner, coaIds) {
  const unique = [...new Set(coaIds.filter(Boolean))];
  if (unique.length === 0) return new Map();

  const [rows] = await runner.query(
    `SELECT id, code, name FROM chart_of_accounts
      WHERE id IN (${unique.map(() => '?').join(', ')})`,
    unique,
  );
  return new Map(rows.map((row) => [Number(row.id), { code: row.code, name: row.name }]));
}

// --- the ledger -------------------------------------------------------------

// Search runs here rather than in the app, because the app only ever holds a
// page of rows and searching those would quietly miss everything else.
// Decision 022.
function ledgerWhere(filters) {
  const where = ["t.status <> 'draft' OR t.created_by = ?"];
  const params = [filters.userId];

  if (filters.search) {
    where.push(`(t.description LIKE ? OR t.journal_number LIKE ? OR t.reference LIKE ?)`);
    const like = `%${filters.search}%`;
    params.push(like, like, like);
  }
  if (filters.accountId) {
    where.push('t.account_id = ?');
    params.push(filters.accountId);
  }
  if (filters.categoryId) {
    where.push('t.category_id = ?');
    params.push(filters.categoryId);
  }
  if (filters.status) {
    where.push('t.status = ?');
    params.push(filters.status);
  }
  if (filters.direction) {
    where.push('t.direction = ?');
    params.push(filters.direction);
  }
  if (filters.from) {
    where.push('t.date >= ?');
    params.push(filters.from);
  }
  if (filters.to) {
    where.push('t.date <= ?');
    params.push(filters.to);
  }

  return { clause: where.map((part) => `(${part})`).join(' AND '), params };
}

export async function listLedger(runner = getPool(), filters) {
  const { clause, params } = ledgerWhere(filters);

  const [rows] = await runner.query(
    `SELECT t.id, t.journal_number, t.date, t.direction, t.amount, t.currency,
            t.description, t.status, t.entry_type, t.reversed_by_id, t.reversal_of_id,
            a.name AS account_name, c.name AS category_name,
            u.name AS created_by_name,
            (SELECT COUNT(*) FROM entry_flags f
              WHERE f.transaction_id = t.id AND f.resolved = 0) AS flag_count
       FROM transactions t
       LEFT JOIN accounts a ON a.id = t.account_id
       LEFT JOIN categories c ON c.id = t.category_id
       LEFT JOIN users u ON u.id = t.created_by
      WHERE ${clause}
      ORDER BY t.date DESC, t.id DESC
      LIMIT ? OFFSET ?`,
    [...params, filters.pageSize, (filters.page - 1) * filters.pageSize],
  );

  const [counted] = await runner.query(
    `SELECT COUNT(*) AS total FROM transactions t WHERE ${clause}`,
    params,
  );

  return { rows, total: Number(counted[0].total) };
}

// The approval inbox. Oldest first: an entry waiting three days matters more
// than one submitted this morning.
export async function listPending(runner = getPool()) {
  const [rows] = await runner.query(
    `SELECT t.id, t.date, t.direction, t.amount, t.currency, t.description,
            t.entry_type, a.name AS account_name, c.name AS category_name,
            u.id AS created_by, u.name AS created_by_name, t.created_at,
            (SELECT COUNT(*) FROM entry_flags f
              WHERE f.transaction_id = t.id AND f.resolved = 0) AS flag_count
       FROM transactions t
       LEFT JOIN accounts a ON a.id = t.account_id
       LEFT JOIN categories c ON c.id = t.category_id
       JOIN users u ON u.id = t.created_by
      WHERE t.status = 'pending'
      ORDER BY t.created_at, t.id`,
  );
  return rows;
}

// Everything raised and not yet dealt with, for the review list.
export async function listFlags(runner = getPool(), { resolved = false, severity = null } = {}) {
  const [rows] = await runner.query(
    `SELECT f.id, f.transaction_id, f.severity, f.code, f.detail, f.resolved,
            f.acknowledged_by, f.created_at,
            t.journal_number, t.date, t.description, t.amount, t.status,
            ack.name AS acknowledged_by_name
       FROM entry_flags f
       JOIN transactions t ON t.id = f.transaction_id
       LEFT JOIN users ack ON ack.id = f.acknowledged_by
      WHERE f.resolved = ?
        AND (? IS NULL OR f.severity = ?)
      ORDER BY f.created_at DESC, f.id DESC
      LIMIT 200`,
    [resolved ? 1 : 0, severity, severity],
  );
  return rows;
}

export async function findUser(runner, id) {
  const [rows] = await runner.query(
    'SELECT id, role, approval_limit, auto_approve_own, shares_owner_login, is_active FROM users WHERE id = ?',
    [id],
  );
  return rows[0] ?? null;
}
