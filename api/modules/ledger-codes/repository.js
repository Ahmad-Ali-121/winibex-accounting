// All SQL for the ledger codes screen and its bulk import. Decision 068, 069.

import { getPool } from '../../core/db.js';

export async function listCodes(runner = getPool()) {
  const [rows] = await runner.query(
    `SELECT id, code, name, type, normal_balance, parent_id, is_header, is_system,
            allow_manual_posting, is_active
       FROM chart_of_accounts
      ORDER BY code`,
  );
  return rows;
}

export async function listCategories(runner = getPool()) {
  const [rows] = await runner.query(
    'SELECT id, name, direction, coa_id, is_active FROM categories ORDER BY name',
  );
  return rows;
}

export async function lockCode(runner, id) {
  const [rows] = await runner.query(
    `SELECT id, code, name, type, normal_balance, parent_id, is_header, is_system, is_active
       FROM chart_of_accounts WHERE id = ? FOR UPDATE`,
    [id],
  );
  return rows[0] ?? null;
}

/** Locks the whole chart for an import, so nothing changes under it. */
export async function lockAll(runner) {
  await runner.query('SELECT id FROM chart_of_accounts FOR UPDATE');
}

export async function insertCode(runner, row) {
  const [result] = await runner.query(
    `INSERT INTO chart_of_accounts
       (code, name, type, normal_balance, parent_id, is_header, is_system, allow_manual_posting, is_active)
     VALUES (?, ?, ?, ?, ?, ?, 0, ?, ?)`,
    [
      row.code, row.name, row.type, row.normal_balance, row.parent_id,
      row.is_header ? 1 : 0, row.is_header ? 0 : 1, row.is_active === false ? 0 : 1,
    ],
  );
  return Number(result.insertId);
}

/**
 * A category for the entry form, pointing at a code. Its main head is copied
 * from the categories already in the same class, so 6960 is grouped with the
 * other administrative expenses in the picker. Returns null when the class
 * has no category to copy from.
 */
export async function insertCategoryLike(runner, { name, direction, coaId, code }) {
  const [heads] = await runner.query(
    `SELECT c.main_head, COUNT(*) AS uses
       FROM categories c JOIN chart_of_accounts a ON a.id = c.coa_id
      WHERE LEFT(a.code, 1) = LEFT(?, 1) AND c.direction = ?
      GROUP BY c.main_head ORDER BY uses DESC LIMIT 1`,
    [code, direction],
  );
  if (heads.length === 0) return null;

  const [result] = await runner.query(
    'INSERT INTO categories (name, main_head, direction, coa_id, is_active) VALUES (?, ?, ?, ?, 1)',
    [name, heads[0].main_head, direction, coaId],
  );
  return Number(result.insertId);
}

export async function rename(runner, id, name) {
  const [result] = await runner.query('UPDATE chart_of_accounts SET name = ? WHERE id = ?', [name, id]);
  return result.affectedRows;
}

export async function setParent(runner, id, parentId) {
  const [result] = await runner.query('UPDATE chart_of_accounts SET parent_id = ? WHERE id = ?', [parentId, id]);
  return result.affectedRows;
}

/** Categories still named as the code was keep matching it. */
export async function renameMatchingCategories(runner, coaId, oldName, newName) {
  const [result] = await runner.query(
    'UPDATE categories SET name = ? WHERE coa_id = ? AND name = ?',
    [newName, coaId, oldName],
  );
  return result.affectedRows;
}

export async function setActive(runner, id, isActive) {
  const [result] = await runner.query(
    'UPDATE chart_of_accounts SET is_active = ? WHERE id = ?',
    [isActive ? 1 : 0, id],
  );
  return result.affectedRows;
}

export async function setCategoriesActive(runner, coaId, isActive) {
  const [result] = await runner.query(
    'UPDATE categories SET is_active = ? WHERE coa_id = ?',
    [isActive ? 1 : 0, coaId],
  );
  return result.affectedRows;
}

/** Debits less credits over every journal line on the code, in paisa. */
export async function netDebit(runner, coaId) {
  const [rows] = await runner.query(
    `SELECT COALESCE(SUM(debit), 0) - COALESCE(SUM(credit), 0) AS net
       FROM journal_lines WHERE coa_id = ?`,
    [coaId],
  );
  return BigInt(String(rows[0].net));
}

export async function activeAccountsUsing(runner, coaId) {
  const [rows] = await runner.query(
    'SELECT name FROM accounts WHERE coa_id = ? AND is_active = 1 ORDER BY name',
    [coaId],
  );
  return rows.map((row) => row.name);
}

export async function currentTaxesUsing(runner, coaId) {
  const [rows] = await runner.query(
    `SELECT short_code FROM taxes
      WHERE coa_id = ? AND is_active = 1 AND effective_to IS NULL ORDER BY short_code`,
    [coaId],
  );
  return rows.map((row) => row.short_code);
}
