// All SQL for categories.

import { getPool } from '../../core/db.js';

// Two categories exist only so the transfer engine has something to point at,
// and one only for the opening entry. Showing them in the picker would invite
// someone to post to a control account by hand.
const SYSTEM_ONLY_CODES = ['1118', '3400'];

export async function list(runner = getPool(), { direction = null, includeSystem = false } = {}) {
  const [rows] = await runner.query(
    `SELECT c.id, c.name, c.main_head, c.direction, c.is_active,
            a.id AS coa_id, a.code AS coa_code, a.name AS coa_name, a.type AS coa_type
       FROM categories c
       JOIN chart_of_accounts a ON a.id = c.coa_id
      WHERE c.is_active = 1
        AND (? IS NULL OR c.direction = ?)
        AND (? = 1 OR a.code NOT IN (${SYSTEM_ONLY_CODES.map(() => '?').join(', ')}))
      ORDER BY c.main_head, c.name`,
    [direction, direction, includeSystem ? 1 : 0, ...SYSTEM_ONLY_CODES],
  );
  return rows;
}
