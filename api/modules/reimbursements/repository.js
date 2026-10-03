// All SQL for what the company owes its people, and for clearing it.

import { getPool } from '../../core/db.js';

// What a person is owed is never stored. It is their personally paid posted
// entries, less what has been paid back. Decision 020, and the same reasoning
// as decision 008: a stored balance drifts.
//
// Direction carries the sign. A reversal of a personally paid entry is an `in`
// row against the same person, so it subtracts, and the pair nets to nothing.
const OWED = `
  SELECT t.paid_by_user_id AS user_id,
         COALESCE(SUM(CASE WHEN t.direction = 'out' THEN t.amount ELSE -t.amount END), 0) AS paid
    FROM transactions t
   WHERE t.paid_by_type = 'person'
     AND t.paid_by_user_id IS NOT NULL
     AND t.status IN ('posted', 'reversed')
     AND (? = 1 OR t.entry_type <> 'historical')
   GROUP BY t.paid_by_user_id`;

const REPAID = `
  SELECT r.person_user_id AS user_id, COALESCE(SUM(r.amount), 0) AS repaid
    FROM reimbursements r
    JOIN transactions t ON t.id = r.transaction_id
   WHERE t.status IN ('posted', 'reversed')
   GROUP BY r.person_user_id`;

export async function owedToEveryone(runner = getPool(), { historyMerged }) {
  const [rows] = await runner.query(
    `SELECT u.id, u.name, u.email,
            COALESCE(paid.paid, 0) AS paid,
            COALESCE(back.repaid, 0) AS repaid,
            COALESCE(paid.paid, 0) - COALESCE(back.repaid, 0) AS owed
       FROM users u
       LEFT JOIN (${OWED}) paid ON paid.user_id = u.id
       LEFT JOIN (${REPAID}) back ON back.user_id = u.id
      WHERE COALESCE(paid.paid, 0) <> 0 OR COALESCE(back.repaid, 0) <> 0
      ORDER BY u.name`,
    [historyMerged ? 1 : 0],
  );
  return rows;
}

export async function owedTo(runner = getPool(), userId, { historyMerged }) {
  const rows = await owedToEveryone(runner, { historyMerged });
  const found = rows.find((row) => Number(row.id) === Number(userId));
  return found ? Number(found.owed) : 0;
}

// The entries behind that figure, so a reimbursement can name what it covers
// rather than being a round number nobody can trace.
export async function outstandingFor(runner = getPool(), userId, { historyMerged }) {
  const [rows] = await runner.query(
    `SELECT t.id, t.journal_number, t.date, t.description, t.amount,
            COALESCE(SUM(i.amount), 0) AS covered
       FROM transactions t
       LEFT JOIN reimbursement_items i ON i.covered_transaction_id = t.id
      WHERE t.paid_by_type = 'person'
        AND t.paid_by_user_id = ?
        AND t.direction = 'out'
        AND t.status = 'posted'
        AND (? = 1 OR t.entry_type <> 'historical')
      GROUP BY t.id, t.journal_number, t.date, t.description, t.amount
     HAVING covered < t.amount
      ORDER BY t.date, t.id`,
    [userId, historyMerged ? 1 : 0],
  );
  return rows;
}

export async function insertReimbursement(runner, { personUserId, transactionId, amount, note, createdBy }) {
  const [result] = await runner.query(
    `INSERT INTO reimbursements (person_user_id, transaction_id, amount, note, created_by)
     VALUES (?, ?, ?, ?, ?)`,
    [personUserId, transactionId, amount, note, createdBy],
  );
  return Number(result.insertId);
}

export async function insertItems(runner, reimbursementId, items) {
  if (items.length === 0) return 0;
  const [result] = await runner.query(
    `INSERT INTO reimbursement_items (reimbursement_id, covered_transaction_id, amount)
     VALUES ${items.map(() => '(?, ?, ?)').join(', ')}`,
    items.flatMap((item) => [reimbursementId, item.transactionId, item.amount]),
  );
  return result.affectedRows;
}

// A reimbursement debits what the company owes, so it needs the category that
// posts to 2114. Looking it up by ledger code rather than by name means a
// rename in the UI cannot break posting.
export async function categoryForLedgerCode(runner = getPool(), code) {
  const [rows] = await runner.query(
    `SELECT c.id FROM categories c
       JOIN chart_of_accounts a ON a.id = c.coa_id
      WHERE a.code = ? AND c.is_active = 1
      ORDER BY c.id LIMIT 1`,
    [code],
  );
  return rows[0] ? Number(rows[0].id) : null;
}

export async function readSetting(runner = getPool(), key) {
  const [rows] = await runner.query('SELECT value FROM settings WHERE setting_key = ?', [key]);
  return rows[0]?.value ?? null;
}
