// The audit log.
//
// Append only. Nothing updates or deletes a row here, and no job purges the
// table, because the Companies Act 2017 requires ten years of books.
//
// It takes a connection rather than using the pool, so the audit row is part
// of the same transaction as the change it describes. An audit entry that
// survives a rolled-back write would be a record of something that never
// happened, which is worse than no record at all.

import { AppError, ErrorCode } from './errors.js';
import { toJsonColumn, fromJsonColumn } from './json.js';

export const AuditAction = Object.freeze({
  INSERT: 'insert',
  UPDATE: 'update',
  STATUS_CHANGE: 'status_change',
  LOGIN: 'login',
  LOGIN_FAILED: 'login_failed',
  LOGOUT: 'logout',
  PERMISSION_CHANGE: 'permission_change',
  SETTING_CHANGE: 'setting_change',
});

export async function writeAudit(connection, entry) {
  const {
    userId = null,
    table,
    recordId = null,
    action,
    before = null,
    after = null,
    ip = null,
  } = entry;

  if (!table) throw new Error('writeAudit needs a table name');
  if (!action) throw new Error('writeAudit needs an action');
  if (action.length > 30) throw new Error(`Audit action too long: ${action}`);

  await connection.query(
    `INSERT INTO audit_log (user_id, table_name, record_id, action, before_json, after_json, ip)
     VALUES (?, ?, ?, ?, ?, ?, ?)`,
    [userId, table, recordId, action, toJsonColumn(before), toJsonColumn(after), ip],
  );
}

// Reads back with the JSON columns parsed. Whether the driver already did that
// depends on its version, so fromJsonColumn copes with both.
export async function readAuditFor(connection, table, recordId) {
  const [rows] = await connection.query(
    `SELECT id, user_id, table_name, record_id, action, before_json, after_json, ip, created_at
     FROM audit_log
     WHERE table_name = ? AND record_id = ?
     ORDER BY id`,
    [table, recordId],
  );

  return rows.map((row) => ({
    ...row,
    before_json: fromJsonColumn(row.before_json),
    after_json: fromJsonColumn(row.after_json),
  }));
}

// Convenience for the common case: record a change and keep both sides.
export async function auditChange(connection, { req, table, recordId, action, before, after }) {
  await writeAudit(connection, {
    userId: req?.user?.id ?? null,
    ip: req?.ip ?? null,
    table,
    recordId,
    action,
    before,
    after,
  });
}

export function requireAuditableUser(req) {
  if (!req?.user?.id) {
    throw new AppError(401, ErrorCode.NOT_AUTHENTICATED, 'Sign in to continue.');
  }
  return req.user.id;
}
