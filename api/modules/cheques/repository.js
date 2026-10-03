// All SQL for the cheque register.

import { getPool } from '../../core/db.js';

const COLUMNS = `
  c.id, c.account_id, c.cheque_number, c.payee, c.amount, c.issue_date,
  c.status, c.cleared_on, c.transaction_id, c.note, c.created_by, c.created_at`;

export async function list(runner = getPool(), { accountId = null, status = null } = {}) {
  const [rows] = await runner.query(
    `SELECT ${COLUMNS}, a.name AS account_name, t.journal_number
       FROM cheques c
       JOIN accounts a ON a.id = c.account_id
       LEFT JOIN transactions t ON t.id = c.transaction_id
      WHERE (? IS NULL OR c.account_id = ?)
        AND (? IS NULL OR c.status = ?)
      ORDER BY c.issue_date DESC, c.id DESC`,
    [accountId, accountId, status, status],
  );
  return rows;
}

export async function findById(runner = getPool(), id) {
  const [rows] = await runner.query(
    `SELECT ${COLUMNS}, a.name AS account_name, t.journal_number
       FROM cheques c
       JOIN accounts a ON a.id = c.account_id
       LEFT JOIN transactions t ON t.id = c.transaction_id
      WHERE c.id = ?`,
    [id],
  );
  return rows[0] ?? null;
}

export async function insert(runner, cheque) {
  const [result] = await runner.query(
    `INSERT INTO cheques
       (account_id, cheque_number, payee, amount, issue_date, transaction_id, note, created_by)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      cheque.accountId, cheque.chequeNumber, cheque.payee, cheque.amount,
      cheque.issueDate, cheque.transactionId, cheque.note, cheque.createdBy,
    ],
  );
  return Number(result.insertId);
}

export async function setStatus(runner, id, status, clearedOn = null) {
  const [result] = await runner.query(
    'UPDATE cheques SET status = ?, cleared_on = ? WHERE id = ?',
    [status, clearedOn, id],
  );
  return result.affectedRows;
}

export async function linkTransaction(runner, id, transactionId) {
  const [result] = await runner.query(
    'UPDATE cheques SET transaction_id = ? WHERE id = ?',
    [transactionId, id],
  );
  return result.affectedRows;
}
