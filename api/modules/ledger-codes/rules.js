// The rules every change to the chart of accounts follows, from the screen
// or from an imported file. Decisions 068 and 069.

import { divideRounded } from '../../core/money.js';
import * as repo from './repository.js';

// The first digit decides the kind of account and its normal side.
// CHART-OF-ACCOUNTS.md, "Conventions".
const CLASS_TYPE = {
  1: 'asset',
  2: 'liability',
  3: 'equity',
  4: 'income',
  5: 'expense',
  6: 'expense',
  7: 'expense',
  8: 'expense',
  9: 'expense',
};

export const CODE_SHAPE = /^[1-9]\d{3}$/;

export function typeFor(code) {
  return CLASS_TYPE[code[0]];
}

export function normalFor(type) {
  return type === 'asset' || type === 'expense' ? 'debit' : 'credit';
}

/** Income and expense codes can be picked on the entry form; nothing else. */
export function canJoinEntryForm(type, isHeader) {
  return !isHeader && (type === 'income' || type === 'expense');
}

export function directionFor(type) {
  return type === 'income' ? 'in' : 'out';
}

export function formatPkr(minor) {
  const rupees = divideRounded(minor < 0n ? -minor : minor, 100n);
  return `PKR ${Number(rupees).toLocaleString('en-PK')}`;
}

/** The chart as it stands, with each code's categories, for checking changes. */
export async function loadChart(runner) {
  const rows = await repo.listCodes(runner);
  const categories = await repo.listCategories(runner);
  const byCode = new Map();
  const byId = new Map();
  for (const row of rows) {
    const entry = {
      id: Number(row.id),
      code: row.code,
      name: row.name,
      type: row.type,
      normalBalance: row.normal_balance,
      parentId: row.parent_id === null ? null : Number(row.parent_id),
      isHeader: Boolean(row.is_header),
      isSystem: Boolean(row.is_system),
      isActive: Boolean(row.is_active),
      categories: categories
        .filter((category) => Number(category.coa_id) === Number(row.id))
        .map((category) => ({
          id: Number(category.id),
          name: category.name,
          direction: category.direction,
          isActive: Boolean(category.is_active),
        })),
    };
    entry.onEntryForm = entry.categories.some((category) => category.isActive);
    byCode.set(entry.code, entry);
    byId.set(entry.id, entry);
  }
  return { byCode, byId, list: [...byCode.values()] };
}

export function parentCodeOf(chart, entry) {
  return entry.parentId === null ? null : chart.byId.get(entry.parentId)?.code ?? null;
}

/**
 * The heading a code sits under. Named: it must be a heading that is on, in
 * the same class, and not the code itself. Not named: the nearest heading
 * before the code in its class, or none. [extraHeadings] are headings about
 * to be added by the same import. Returns { code } or { reason }.
 */
export function resolveParent(chart, code, parentCode, extraHeadings = new Set()) {
  if (parentCode) {
    if (!CODE_SHAPE.test(parentCode)) {
      return { reason: `The heading "${parentCode}" is not a four-digit code.` };
    }
    if (parentCode === code) return { reason: 'A code cannot sit under itself.' };
    if (parentCode > code) {
      return { reason: `A heading comes before the codes under it, so ${parentCode} cannot hold ${code}.` };
    }
    if (parentCode[0] !== code[0]) {
      return { reason: `${code} and heading ${parentCode} start with different digits, so they are different kinds of account.` };
    }
    const existing = chart.byCode.get(parentCode);
    if (existing) {
      if (!existing.isHeader) return { reason: `${parentCode} is a code, not a heading. Codes can only sit under headings.` };
      if (!existing.isActive) return { reason: `Heading ${parentCode} is switched off.` };
      return { code: parentCode };
    }
    if (extraHeadings.has(parentCode)) return { code: parentCode };
    return { reason: `There is no heading ${parentCode}.` };
  }

  let best = null;
  const candidates = [
    ...chart.list.filter((entry) => entry.isHeader && entry.isActive).map((entry) => entry.code),
    ...extraHeadings,
  ];
  for (const candidate of candidates) {
    if (candidate[0] === code[0] && candidate < code && (best === null || candidate > best)) best = candidate;
  }
  return { code: best };
}

/** True when [parentCode] is [entry] itself or sits somewhere under it. */
export function wouldLoop(chart, entry, parentCode) {
  let current = chart.byCode.get(parentCode);
  const seen = new Set();
  while (current && !seen.has(current.id)) {
    if (current.id === entry.id) return true;
    seen.add(current.id);
    current = current.parentId === null ? null : chart.byId.get(current.parentId);
  }
  return false;
}

/** Another code that is on with this name, ignoring case and spaces. */
export function nameTakenBy(chart, name, exceptCode = null) {
  const wanted = name.trim().toLowerCase();
  return chart.list.find(
    (entry) => entry.isActive && entry.code !== exceptCode && entry.name.trim().toLowerCase() === wanted,
  ) ?? null;
}

/**
 * Why a code cannot be switched off, or null if it can. [alsoOff] are codes
 * the same import switches off, so a heading can go with everything under it.
 */
export async function switchOffBlocker(runner, chart, entry, alsoOff = new Set()) {
  if (entry.isSystem) return `${entry.code} is built in, so it stays on.`;
  if (entry.isHeader) {
    const under = chart.list.filter(
      (child) => child.parentId === entry.id && child.isActive && !alsoOff.has(child.code),
    );
    if (under.length > 0) {
      return `Heading ${entry.code} still has ${under.map((child) => child.code).join(', ')} under it. Switch those off or move them first.`;
    }
    return null;
  }
  const net = await repo.netDebit(runner, entry.id);
  if (net !== 0n) {
    return `${entry.code} still holds ${formatPkr(net)}. It can be switched off once it is back at zero.`;
  }
  const accounts = await repo.activeAccountsUsing(runner, entry.id);
  if (accounts.length > 0) return `${entry.code} is the ledger code of ${accounts.join(', ')}, so it stays on.`;
  const taxes = await repo.currentTaxesUsing(runner, entry.id);
  if (taxes.length > 0) return `${taxes.join(', ')} posts to ${entry.code}. End that tax first.`;
  return null;
}
