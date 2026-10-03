// All SQL for accounts.
//
// A balance is never stored. It is the sum of posted journal lines on the
// account's ledger code, computed on request. Decision 008: a stored balance
// is how the spreadsheet drifted, and a column would invite the same drift.

import { getPool } from '../../core/db.js';

// Two rules live in this subquery.
//
// A reversed entry still counts. Its journal lines stay in the book and the
// reversing entry's lines offset them, so the pair nets to nothing on every
// account. Dropping the original would subtract its effect once and add the
// reversal's again, which moves the balance by twice the amount in the wrong
// direction. Decision 012: both rows stay visible, neither is erased.
//
// Historical entries are excluded while history_merged is false, because the
// opening entry already contains their effect. Counting both would double
// every balance. Decision 037.
const BALANCE_SUBQUERY = `
  (SELECT COALESCE(SUM(j.debit - j.credit), 0)
     FROM journal_lines j
     JOIN transactions t ON t.id = j.transaction_id
    WHERE j.coa_id = a.coa_id
      AND t.status IN ('posted', 'reversed')
      AND (? = 1 OR t.entry_type <> 'historical'))`;

export async function listWithBalances(runner = getPool(), { historyMerged }) {
  const [rows] = await runner.query(
    `SELECT a.id, a.name, a.type, a.is_active, a.opening_date, a.owner_user_id,
            c.id AS coa_id, c.code AS coa_code, c.name AS coa_name, c.normal_balance,
            ${BALANCE_SUBQUERY} AS net_debit
       FROM accounts a
       JOIN chart_of_accounts c ON c.id = a.coa_id
      ORDER BY a.name`,
    [historyMerged ? 1 : 0],
  );
  return rows;
}

export async function findWithBalance(runner = getPool(), id, { historyMerged }) {
  const [rows] = await runner.query(
    `SELECT a.id, a.name, a.type, a.is_active, a.opening_date, a.owner_user_id,
            c.id AS coa_id, c.code AS coa_code, c.name AS coa_name, c.normal_balance,
            ${BALANCE_SUBQUERY} AS net_debit
       FROM accounts a
       JOIN chart_of_accounts c ON c.id = a.coa_id
      WHERE a.id = ?`,
    [historyMerged ? 1 : 0, id],
  );
  return rows[0] ?? null;
}

// The same figure arrived at the other way: from the transactions themselves
// rather than from their journal lines. Only meaningful for entries that name
// an account, so the opening entry and manual journal entries are excluded.
// The two must agree, and a test asserts it after every operation.
export async function balanceFromTransactions(runner = getPool(), accountId, { historyMerged }) {
  const [rows] = await runner.query(
    `SELECT COALESCE(SUM(CASE WHEN direction = 'in' THEN amount ELSE -amount END), 0) AS balance
       FROM transactions
      WHERE account_id = ?
        AND status IN ('posted', 'reversed')
        AND entry_type IN ('normal', 'historical')
        AND (? = 1 OR entry_type <> 'historical')`,
    [accountId, historyMerged ? 1 : 0],
  );
  return Number(rows[0].balance);
}

// What the dashboard shows: cash held, money in and out this month, and what
// is waiting. All computed, never stored.
export async function dashboardTotals(runner = getPool(), { historyMerged, monthStart }) {
  const historyFilter = historyMerged ? '1=1' : "t.entry_type <> 'historical'";

  const [cash] = await runner.query(
    `SELECT COALESCE(SUM(j.debit - j.credit), 0) AS net
       FROM journal_lines j
       JOIN transactions t ON t.id = j.transaction_id
       JOIN chart_of_accounts c ON c.id = j.coa_id
       JOIN accounts a ON a.coa_id = c.coa_id
      WHERE t.status IN ('posted','reversed') AND ${historyFilter}`,
  );

  const [month] = await runner.query(
    `SELECT
        COALESCE(SUM(CASE WHEN t.direction='in'  THEN t.amount ELSE 0 END),0) AS money_in,
        COALESCE(SUM(CASE WHEN t.direction='out' THEN t.amount ELSE 0 END),0) AS money_out
       FROM transactions t
      WHERE t.status IN ('posted','reversed')
        AND t.entry_type = 'normal'
        AND t.date >= ?`,
    [monthStart],
  );

  const [pending] = await runner.query(
    `SELECT COUNT(*) AS n FROM transactions WHERE status = 'pending'`,
  );
  const [flags] = await runner.query(
    `SELECT COUNT(*) AS n FROM entry_flags WHERE resolved = 0`,
  );

  return {
    cashNet: Number(cash[0].net),
    moneyIn: Number(month[0].money_in),
    moneyOut: Number(month[0].money_out),
    pendingCount: Number(pending[0].n),
    openFlagCount: Number(flags[0].n),
  };
}

export async function readSetting(runner = getPool(), key) {
  const [rows] = await runner.query('SELECT value, value_type FROM settings WHERE setting_key = ?', [key]);
  return rows[0] ?? null;
}
