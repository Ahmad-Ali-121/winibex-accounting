// All SQL for people and their permissions. Nothing else in the feature talks
// to the database. A password hash never leaves this file in a result.

const COLUMNS = `id, name, email, role, approval_limit, auto_approve_own,
                 shares_owner_login, is_active, must_change_password, created_at`;

export async function listPickable(runner) {
  const [rows] = await runner.query(
    'SELECT id, name, role FROM users WHERE is_active = 1 ORDER BY name',
  );
  return rows;
}

export async function listAll(runner) {
  const [rows] = await runner.query(
    `SELECT ${COLUMNS} FROM users
      ORDER BY is_active DESC, role = 'owner' DESC, name`,
  );
  return rows;
}

export async function findById(runner, id) {
  const [rows] = await runner.query(`SELECT ${COLUMNS} FROM users WHERE id = ?`, [id]);
  return rows[0] ?? null;
}

export async function lockById(runner, id) {
  const [rows] = await runner.query(`SELECT ${COLUMNS} FROM users WHERE id = ? FOR UPDATE`, [id]);
  return rows[0] ?? null;
}

export async function emailTaken(runner, email) {
  const [rows] = await runner.query('SELECT id FROM users WHERE email = ?', [email]);
  return rows.length > 0;
}

export async function insert(runner, user) {
  const [result] = await runner.query(
    `INSERT INTO users (name, email, password_hash, must_change_password, role,
                        approval_limit, auto_approve_own, shares_owner_login, is_active)
     VALUES (?, ?, ?, 1, ?, ?, ?, ?, 1)`,
    [
      user.name, user.email, user.passwordHash, user.role,
      user.approvalLimit, user.autoApproveOwn ? 1 : 0, user.sharesOwnerLogin ? 1 : 0,
    ],
  );
  return Number(result.insertId);
}

export async function update(runner, id, user) {
  await runner.query(
    `UPDATE users
        SET name = ?, role = ?, approval_limit = ?, auto_approve_own = ?,
            shares_owner_login = ?, is_active = ?
      WHERE id = ?`,
    [
      user.name, user.role, user.approvalLimit, user.autoApproveOwn ? 1 : 0,
      user.sharesOwnerLogin ? 1 : 0, user.isActive ? 1 : 0, id,
    ],
  );
}

export async function setTemporaryPassword(runner, id, passwordHash) {
  await runner.query(
    'UPDATE users SET password_hash = ?, must_change_password = 1 WHERE id = ?',
    [passwordHash, id],
  );
}

// Ends every session the person has open, so a switched-off login or a reset
// password takes effect at their next refresh rather than whenever they sign
// out on their own.
export async function revokeSessions(runner, userId) {
  await runner.query(
    'UPDATE refresh_tokens SET revoked_at = UTC_TIMESTAMP() WHERE user_id = ? AND revoked_at IS NULL',
    [userId],
  );
}
