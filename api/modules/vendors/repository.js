// All SQL for vendors: anyone Winibex pays who is not an employee.

import { getPool } from '../../core/db.js';

const COLUMNS = `
  id, name, kind, ntn, cnic, strn, atl_status, atl_checked_on, default_tax_id,
  country, email, phone, notes, is_active, created_by, created_at, updated_at`;

export async function list(runner = getPool(), { search = null, includeInactive = false } = {}) {
  const [rows] = await runner.query(
    `SELECT ${COLUMNS} FROM vendors
      WHERE (? = 1 OR is_active = 1)
        AND (? IS NULL OR name LIKE CONCAT('%', ?, '%') OR ntn = ? OR cnic = ?)
      ORDER BY name`,
    [includeInactive ? 1 : 0, search, search, search, search],
  );
  return rows;
}

export async function findById(runner = getPool(), id) {
  const [rows] = await runner.query(`SELECT ${COLUMNS} FROM vendors WHERE id = ?`, [id]);
  return rows[0] ?? null;
}

export async function insert(runner, vendor) {
  const [result] = await runner.query(
    `INSERT INTO vendors
       (name, kind, ntn, cnic, strn, atl_status, atl_checked_on, default_tax_id,
        country, email, phone, notes, created_by)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      vendor.name, vendor.kind, vendor.ntn, vendor.cnic, vendor.strn,
      vendor.atlStatus, vendor.atlCheckedOn, vendor.defaultTaxId,
      vendor.country, vendor.email, vendor.phone, vendor.notes, vendor.createdBy,
    ],
  );
  return Number(result.insertId);
}

const UPDATABLE = {
  name: 'name',
  kind: 'kind',
  ntn: 'ntn',
  cnic: 'cnic',
  strn: 'strn',
  atlStatus: 'atl_status',
  atlCheckedOn: 'atl_checked_on',
  defaultTaxId: 'default_tax_id',
  country: 'country',
  email: 'email',
  phone: 'phone',
  notes: 'notes',
  isActive: 'is_active',
};

export async function update(runner, id, changes) {
  // undefined means "not being changed". Passing it through would reach the
  // driver as a bind parameter it refuses, which surfaces as a 500 on a
  // request that was perfectly valid.
  const entries = Object.entries(changes)
    .filter(([key, value]) => UPDATABLE[key] && value !== undefined);
  if (entries.length === 0) return 0;

  const [result] = await runner.query(
    `UPDATE vendors SET ${entries.map(([key]) => `${UPDATABLE[key]} = ?`).join(', ')} WHERE id = ?`,
    [...entries.map(([, value]) => value), id],
  );
  return result.affectedRows;
}

// A vendor is never deleted while any payment points at them, so withholding
// statements filed years ago still name a real payee. Decision 007.
export async function isReferenced(runner = getPool(), id) {
  const [rows] = await runner.query('SELECT id FROM transactions WHERE vendor_id = ? LIMIT 1', [id]);
  return rows.length > 0;
}
