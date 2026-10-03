// All SQL for the opening entry and the history merge.

import { getPool } from '../../core/db.js';

export async function readSetting(runner = getPool(), key) {
  const [rows] = await runner.query('SELECT value FROM settings WHERE setting_key = ?', [key]);
  return rows[0]?.value ?? null;
}

export async function writeSetting(runner, key, value, userId) {
  await runner.query(
    'UPDATE settings SET value = ?, updated_by = ? WHERE setting_key = ?',
    [value, userId, key],
  );
}

export async function findOpeningEntry(runner = getPool()) {
  const [rows] = await runner.query(
    `SELECT id, journal_number, date, status, reversed_by_id
       FROM transactions WHERE entry_type = 'opening' AND status <> 'rejected'
      ORDER BY id LIMIT 1`,
  );
  return rows[0] ?? null;
}

export async function coaByCode(runner = getPool(), code) {
  const [rows] = await runner.query(
    `SELECT id, code, name, type, normal_balance, is_header
       FROM chart_of_accounts WHERE code = ?`,
    [code],
  );
  return rows[0] ?? null;
}

export async function coaByCodes(runner = getPool(), codes) {
  if (codes.length === 0) return [];
  const [rows] = await runner.query(
    `SELECT id, code, name, type, normal_balance, is_header FROM chart_of_accounts
      WHERE code IN (${codes.map(() => '?').join(', ')})`,
    codes,
  );
  return rows;
}

// What the opening entry says each ledger account held at 30 June 2026.
export async function openingByLedger(runner = getPool()) {
  const [rows] = await runner.query(
    `SELECT j.coa_id, a.code, a.name, a.type, COALESCE(SUM(j.debit - j.credit), 0) AS net
       FROM journal_lines j
       JOIN transactions t ON t.id = j.transaction_id
       JOIN chart_of_accounts a ON a.id = j.coa_id
      WHERE t.entry_type = 'opening' AND t.status IN ('posted', 'reversed')
      GROUP BY j.coa_id, a.code, a.name, a.type`,
  );
  return rows;
}

// What the historical entries actually add up to, account by account.
export async function historyByLedger(runner = getPool(), { upTo }) {
  const [rows] = await runner.query(
    `SELECT j.coa_id, a.code, a.name, a.type, COALESCE(SUM(j.debit - j.credit), 0) AS net
       FROM journal_lines j
       JOIN transactions t ON t.id = j.transaction_id
       JOIN chart_of_accounts a ON a.id = j.coa_id
      WHERE t.entry_type = 'historical'
        AND t.status IN ('posted', 'reversed')
        AND t.date <= ?
      GROUP BY j.coa_id, a.code, a.name, a.type`,
    [upTo],
  );
  return rows;
}

export async function countHistorical(runner = getPool()) {
  const [rows] = await runner.query(
    `SELECT COUNT(*) AS n FROM transactions
      WHERE entry_type = 'historical' AND status = 'posted'`,
  );
  return Number(rows[0].n);
}

export async function categoryForLedgerCode(runner = getPool(), code, direction) {
  const [rows] = await runner.query(
    `SELECT c.id FROM categories c
       JOIN chart_of_accounts a ON a.id = c.coa_id
      WHERE a.code = ? AND c.direction = ? AND c.is_active = 1
      ORDER BY c.id LIMIT 1`,
    [code, direction],
  );
  return rows[0] ? Number(rows[0].id) : null;
}

export async function insertJournalLines(runner, transactionId, lines) {
  const [result] = await runner.query(
    `INSERT INTO journal_lines (transaction_id, coa_id, debit, credit, line_no, memo)
     VALUES ${lines.map(() => '(?, ?, ?, ?, ?, ?)').join(', ')}`,
    lines.flatMap((line, index) => [
      transactionId, line.coaId, line.debit, line.credit, index + 1, line.memo ?? null,
    ]),
  );
  return result.affectedRows;
}
