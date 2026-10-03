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
