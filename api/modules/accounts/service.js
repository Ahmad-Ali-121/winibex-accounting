// Accounts and their balances.
//
// The app never adds these up itself. It shows what this returns. Anything
// computed on a client can be tampered with, and two places that both know how
// to calculate a balance will eventually disagree.

import { getPool } from '../../core/db.js';
import { notFound } from '../../core/errors.js';
import { money } from '../../core/money.js';
import * as repo from './repository.js';

const BASE_CURRENCY = 'PKR';

export async function isHistoryMerged(runner = getPool()) {
  const setting = await repo.readSetting(runner, 'history_merged');
  if (!setting) return false;
  return setting.value === 'true' || setting.value === '1';
}

// A ledger code has a normal side. For a bank account, an asset, debits
// increase it. For a liability or income account, credits do. Reporting a raw
// debit total would show a credit-normal account with the sign flipped.
function balanceOf(row) {
  const netDebit = Number(row.net_debit);
  return row.normal_balance === 'debit' ? netDebit : -netDebit;
}

function present(row) {
  return {
    id: Number(row.id),
    name: row.name,
    type: row.type,
    isActive: Boolean(row.is_active),
    openingDate: row.opening_date,
    ownerUserId: row.owner_user_id === null ? null : Number(row.owner_user_id),
    ledger: {
      id: Number(row.coa_id),
      code: row.coa_code,
      name: row.coa_name,
      normalBalance: row.normal_balance,
    },
    balance: money(balanceOf(row), BASE_CURRENCY),
  };
}

export async function listAccounts({ includeInactive = false } = {}) {
  const pool = getPool();
  const historyMerged = await isHistoryMerged(pool);
  const rows = await repo.listWithBalances(pool, { historyMerged });

  const accounts = rows
    .filter((row) => includeInactive || row.is_active)
    .map(present);

  // Cash the company actually holds. Pass-through accounts are included
  // because the money in them is the company's, sitting in someone's personal
  // account in transit.
  const total = accounts.reduce((sum, account) => sum + account.balance.minor, 0);

  return {
    accounts,
    total: money(total, BASE_CURRENCY),
    historyMerged,
  };
}

// --- petty cash -------------------------------------------------------------

// An imprest float is a fixed amount of cash the office is meant to hold. When
// it drops below that, the difference is what should be drawn to restore it.
// The float is a setting, not a constant, so it can change without a release.
export async function pettyCashStatus() {
  const pool = getPool();

  const [rows] = await pool.query(
    `SELECT value FROM settings WHERE setting_key = 'petty_cash_imprest'`,
  );
  const imprest = rows[0]?.value === undefined || rows[0]?.value === null || rows[0].value === ''
    ? null
    : Number(rows[0].value);

  const historyMerged = await isHistoryMerged(pool);
  const all = await repo.listWithBalances(pool, { historyMerged });
  const petty = all.filter((row) => row.type === 'petty_cash').map(present);

  return {
    imprest: imprest === null ? null : money(imprest, BASE_CURRENCY),
    accounts: petty.map((account) => {
      const shortfall = imprest === null ? 0 : Math.max(imprest - account.balance.minor, 0);
      return {
        ...account,
        belowFloat: imprest !== null && account.balance.minor < imprest,
        suggestedTopUp: money(shortfall, BASE_CURRENCY),
      };
    }),
  };
}

export async function getAccount(id) {
  const pool = getPool();
  const historyMerged = await isHistoryMerged(pool);
  const row = await repo.findWithBalance(pool, id, { historyMerged });
  if (!row) throw notFound('That account does not exist.');
  return present(row);
}

export async function dashboard() {
  const pool = getPool();
  const historyMerged = await isHistoryMerged(pool);

  const now = new Date();
  const monthStart = `${now.getUTCFullYear()}-${String(now.getUTCMonth() + 1).padStart(2, '0')}-01`;

  const totals = await repo.dashboardTotals(pool, { historyMerged, monthStart });

  return {
    cashHeld: money(totals.cashNet, BASE_CURRENCY),
    monthIn: money(totals.moneyIn, BASE_CURRENCY),
    monthOut: money(totals.moneyOut, BASE_CURRENCY),
    monthNet: money(totals.moneyIn - totals.moneyOut, BASE_CURRENCY),
    pendingCount: totals.pendingCount,
    openFlagCount: totals.openFlagCount,
    historyMerged,
  };
}

// Exposed for the invariant test: the balance from journal lines and the
// balance from transactions must be the same number.
export async function balanceFromTransactions(accountId) {
  const pool = getPool();
  const historyMerged = await isHistoryMerged(pool);
  return repo.balanceFromTransactions(pool, accountId, { historyMerged });
}
