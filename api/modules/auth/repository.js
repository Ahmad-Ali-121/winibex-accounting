// All SQL for authentication. No business rules here, and no SQL anywhere else
// in this module.

import { getPool } from '../../core/db.js';
import { toSqlDateTime } from '../../core/tokens.js';

const USER_COLUMNS = `
  id, name, email, password_hash, must_change_password, role,
  approval_limit, auto_approve_own, shares_owner_login, is_active
`;

export async function findUserByEmail(email) {
  const [rows] = await getPool().query(
    `SELECT ${USER_COLUMNS} FROM users WHERE email = ?`,
    [email],
  );
  return rows[0] ?? null;
}

export async function findUserById(id) {
  const [rows] = await getPool().query(
    `SELECT ${USER_COLUMNS} FROM users WHERE id = ?`,
    [id],
  );
  return rows[0] ?? null;
}

export async function insertRefreshToken({
  userId,
  tokenHash,
  familyId,
  expiresAt,
  ip,
  userAgent,
}) {
  const [result] = await getPool().query(
    `INSERT INTO refresh_tokens (user_id, token_hash, family_id, expires_at, ip, user_agent)
     VALUES (?, ?, ?, ?, ?, ?)`,
    [userId, tokenHash, familyId, toSqlDateTime(expiresAt), ip ?? null, userAgent ?? null],
  );
  return result.insertId;
}

export async function findRefreshTokenByHash(tokenHash) {
  const [rows] = await getPool().query(
    `SELECT id, user_id, token_hash, family_id, expires_at, revoked_at, replaced_by_id
     FROM refresh_tokens WHERE token_hash = ?`,
    [tokenHash],
  );
  return rows[0] ?? null;
}

export async function markReplaced(oldId, newId) {
  await getPool().query(
    'UPDATE refresh_tokens SET revoked_at = UTC_TIMESTAMP(), replaced_by_id = ? WHERE id = ?',
    [newId, oldId],
  );
}

// Revoking the family, not just the token, is the whole point. If an old token
// is presented it means a copy exists somewhere, and we cannot tell which side
// is the attacker, so both are cut off.
export async function revokeFamily(familyId) {
  const [result] = await getPool().query(
    'UPDATE refresh_tokens SET revoked_at = UTC_TIMESTAMP() WHERE family_id = ? AND revoked_at IS NULL',
    [familyId],
  );
  return result.affectedRows;
}

export async function countActiveInFamily(familyId) {
  const [rows] = await getPool().query(
    `SELECT COUNT(*) AS total FROM refresh_tokens
     WHERE family_id = ? AND revoked_at IS NULL`,
    [familyId],
  );
  return Number(rows[0].total);
}
