// Categories: what an entry is for, in the words the company uses.
//
// Each one points at a ledger account, which is what the accountant reads.
// The person entering a cost picks "Software subscriptions"; the books record
// 6400. Decision 009.

import { getPool } from '../../core/db.js';
import * as repo from './repository.js';

// The order the picker shows them in. Revenue first for money in, costs first
// for money out, with balance sheet items last in both: they are the rarest
// and the easiest to pick by mistake.
const HEAD_ORDER = ['revenue', 'cost_of_sales', 'admin', 'financial', 'tax', 'balance_sheet'];

function present(row) {
  return {
    id: Number(row.id),
    name: row.name,
    mainHead: row.main_head,
    direction: row.direction,
    ledger: {
      id: Number(row.coa_id),
      code: row.coa_code,
      name: row.coa_name,
      type: row.coa_type,
    },
  };
}

export async function listCategories({ direction = null } = {}) {
  const rows = await repo.list(getPool(), { direction });
  const categories = rows.map(present);

  const groups = new Map();
  for (const category of categories) {
    if (!groups.has(category.mainHead)) groups.set(category.mainHead, []);
    groups.get(category.mainHead).push(category);
  }

  const ordered = [...groups.entries()].sort(
    (a, b) => indexOfHead(a[0]) - indexOfHead(b[0]),
  );

  return {
    categories,
    groups: ordered.map(([mainHead, items]) => ({ mainHead, categories: items })),
  };
}

function indexOfHead(head) {
  const index = HEAD_ORDER.indexOf(head);
  return index === -1 ? HEAD_ORDER.length : index;
}
