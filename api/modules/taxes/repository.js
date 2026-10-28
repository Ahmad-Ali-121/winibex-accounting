// All SQL for taxes and tax rules.

import { getPool } from '../../core/db.js';

const TAX_COLUMNS = `
  id, name, short_code, authority, law_reference, kind, applies_to, computation,
  rate_atl, rate_non_atl, status_basis, return_section, is_inclusive,
  is_adjustable, coa_id, effective_from, effective_to, is_active, notes`;

// A tax applies on a date, not in general. Pakistan rates change every budget,
// and an entry dated before a change must use the rate that was in force then.
export async function listInEffect(runner = getPool(), date) {
  const [rows] = await runner.query(
    `SELECT ${TAX_COLUMNS} FROM taxes
      WHERE is_active = 1
        AND effective_from <= ?
        AND (effective_to IS NULL OR effective_to >= ?)
      ORDER BY short_code`,
    [date, date],
  );
  return rows;
}

export async function findById(runner = getPool(), id) {
  const [rows] = await runner.query(`SELECT ${TAX_COLUMNS} FROM taxes WHERE id = ?`, [id]);
  return rows[0] ?? null;
}

// The rules that decide what the entry form suggests. A NULL in a matching
// column means the rule does not care about that, so it stays matched.
export async function matchingRules(runner = getPool(), { date, direction, currencyIsForeign, accountType, categoryId, clientCountry }) {
  const [rows] = await runner.query(
    `SELECT r.id, r.name, r.tax_id, r.priority, ${TAX_COLUMNS.replace(/\n\s*/g, ' ').split(', ').map((c) => `t.${c.trim()}`).join(', ')}
       FROM tax_rules r
       JOIN taxes t ON t.id = r.tax_id
      WHERE r.is_active = 1
        AND t.is_active = 1
        AND t.effective_from <= ?
        AND (t.effective_to IS NULL OR t.effective_to >= ?)
        AND r.direction = ?
        AND (r.currency_is_foreign IS NULL OR r.currency_is_foreign = ?)
        AND (r.account_type IS NULL OR r.account_type = ?)
        AND (r.category_id IS NULL OR r.category_id = ?)
        AND (r.client_country IS NULL OR r.client_country = ?)
      ORDER BY r.priority, r.id`,
    [date, date, direction, currencyIsForeign ? 1 : 0, accountType ?? null, categoryId ?? null, clientCountry ?? null],
  );
  return rows;
}

export async function companyAtlStatus(runner = getPool()) {
  const [rows] = await runner.query(
    `SELECT value FROM settings WHERE setting_key = 'atl_status'`,
  );
  return rows[0]?.value === 'active' ? 'atl' : 'non_atl';
}

export async function vendorAtlStatus(runner = getPool(), vendorId) {
  if (!vendorId) return null;
  const [rows] = await runner.query(
    'SELECT atl_status, atl_checked_on, name FROM vendors WHERE id = ?',
    [vendorId],
  );
  return rows[0] ?? null;
}

// --- the taxes screen, decision 067 ------------------------------------------

// Every tax, in force or not, newest start date first within a code, with the
// ledger account it posts to.
export async function listAll(runner = getPool()) {
  const [rows] = await runner.query(
    `SELECT t.id, t.name, t.short_code, t.authority, t.law_reference, t.kind, t.applies_to,
            t.computation, t.rate_atl, t.rate_non_atl, t.status_basis, t.return_section,
            t.is_inclusive, t.is_adjustable, t.coa_id, t.effective_from, t.effective_to,
            t.is_active, t.notes, a.code AS coa_code, a.name AS coa_name
       FROM taxes t
       JOIN chart_of_accounts a ON a.id = t.coa_id
      ORDER BY t.short_code, t.effective_from DESC`,
  );
  return rows;
}

export async function listRules(runner = getPool()) {
  const [rows] = await runner.query(
    `SELECT r.id, r.tax_id, r.direction, r.currency_is_foreign, r.account_type, r.category_id,
            r.priority, r.is_active, c.name AS category_name, ca.code AS category_code
       FROM tax_rules r
       LEFT JOIN categories c ON c.id = r.category_id
       LEFT JOIN chart_of_accounts ca ON ca.id = c.coa_id
      ORDER BY r.priority, r.id`,
  );
  return rows;
}

export async function lockTax(runner, id) {
  const [rows] = await runner.query(`SELECT ${TAX_COLUMNS} FROM taxes WHERE id = ? FOR UPDATE`, [id]);
  return rows[0] ?? null;
}

// The ledger accounts a tax may post to: anything that can hold a balance or
// a cost, never a heading.
export async function taxLedgers(runner = getPool()) {
  const [rows] = await runner.query(
    `SELECT id, code, name, type FROM chart_of_accounts
      WHERE is_header = 0 AND is_active = 1 AND type IN ('asset', 'liability', 'expense')
      ORDER BY code`,
  );
  return rows;
}

export async function ledgerByCode(runner, code) {
  const [rows] = await runner.query(
    'SELECT id, code, type, is_header, is_active FROM chart_of_accounts WHERE code = ?',
    [code],
  );
  return rows[0] ?? null;
}

export async function insertTax(runner, tax) {
  const [result] = await runner.query(
    `INSERT INTO taxes
       (name, short_code, authority, law_reference, kind, applies_to, computation,
        rate_atl, rate_non_atl, status_basis, return_section, is_inclusive, is_adjustable,
        coa_id, effective_from, effective_to, is_active, notes)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL, 1, ?)`,
    [
      tax.name, tax.short_code, tax.authority, tax.law_reference, tax.kind, tax.applies_to,
      tax.computation, tax.rate_atl, tax.rate_non_atl, tax.status_basis, tax.return_section,
      tax.is_inclusive ? 1 : 0, tax.is_adjustable ? 1 : 0, tax.coa_id, tax.effective_from, tax.notes,
    ],
  );
  return Number(result.insertId);
}

export async function endTax(runner, id, lastDay) {
  const [result] = await runner.query(
    'UPDATE taxes SET effective_to = ? WHERE id = ? AND effective_to IS NULL',
    [lastDay, id],
  );
  return result.affectedRows;
}

export async function activeRulesFor(runner, taxId) {
  const [rows] = await runner.query(
    `SELECT name, direction, currency_is_foreign, account_type, category_id, client_country, priority
       FROM tax_rules WHERE tax_id = ? AND is_active = 1`,
    [taxId],
  );
  return rows;
}

export async function insertRule(runner, rule) {
  const [result] = await runner.query(
    `INSERT INTO tax_rules
       (name, tax_id, direction, currency_is_foreign, account_type, category_id, client_country, priority)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      rule.name, rule.tax_id, rule.direction, rule.currency_is_foreign, rule.account_type,
      rule.category_id, rule.client_country ?? null, rule.priority ?? 100,
    ],
  );
  return Number(result.insertId);
}

export async function findRule(runner, id) {
  const [rows] = await runner.query('SELECT id, tax_id, is_active FROM tax_rules WHERE id = ?', [id]);
  return rows[0] ?? null;
}

export async function setRuleActive(runner, id, isActive) {
  await runner.query('UPDATE tax_rules SET is_active = ? WHERE id = ?', [isActive ? 1 : 0, id]);
}

export async function categoryDirection(runner, id) {
  const [rows] = await runner.query('SELECT direction, name FROM categories WHERE id = ?', [id]);
  return rows[0] ?? null;
}

// --- bulk import, decision 069 ---------------------------------------------------

/** The words of a tax that do not change what it charges, changed in place. */
export async function updateTaxText(runner, id, text) {
  await runner.query(
    'UPDATE taxes SET name = ?, law_reference = ?, return_section = ?, notes = ? WHERE id = ?',
    [text.name, text.law_reference, text.return_section, text.notes, id],
  );
}

/** The category on the entry form filed under a ledger code, for one direction. */
export async function categoryByLedgerCode(runner, code, direction) {
  const [rows] = await runner.query(
    `SELECT c.id, c.name FROM categories c JOIN chart_of_accounts a ON a.id = c.coa_id
      WHERE a.code = ? AND c.direction = ? AND c.is_active = 1
      ORDER BY c.id LIMIT 1`,
    [code, direction],
  );
  return rows[0] ?? null;
}

export async function lockAllTaxes(runner) {
  await runner.query('SELECT id FROM taxes FOR UPDATE');
}
