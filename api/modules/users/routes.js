import { Router } from 'express';

import { requireAuth } from '../../core/auth.js';
import { getPool } from '../../core/db.js';

export const userRoutes = Router();

// Who can be named on an entry: the person who paid a cost personally, the
// person money was received by, the person being reimbursed.
//
// Deliberately thin. No email, no approval limit, no password fields, because
// a picker needs a name and nothing else, and anything extra here would be
// handed to every signed-in user.
userRoutes.get('/users', requireAuth, async (req, res) => {
  const [rows] = await getPool().query(
    `SELECT id, name, role FROM users WHERE is_active = 1 ORDER BY name`,
  );

  res.json({
    users: rows.map((row) => ({
      id: Number(row.id),
      name: row.name,
      role: row.role,
    })),
  });
});
