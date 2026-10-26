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
//
// "In" and "Out" are money that entered or left the company's own accounts,
// decision 057 (D11). Four rules turn that into SQL:
//
//   - only rows on a company account count, so a cost paid on someone's
//     personal card is left out; paying them back is counted, because that is
//     when the money leaves
//   - a transfer between two company accounts moves nothing in or out, so its
//     legs count only for the bank fee on the out leg, which did leave
//   - a reversal cancels its original on the original's side: reversing money
//     in lowers In rather than adding to Out
//   - the opening entry and history are not this month's trading
//
// With these rules, cash held at the start of the month plus In minus Out is
// cash held now. A test asserts exactly that.
export async function dashboardTotals(runner = getPool(), { historyMerged, monthStart, monthEnd }) {
  const historyFilter = historyMerged ? '1=1' : "t.entry_type <> 'historical'";

  // Cash the company holds: the sum over every account's ledger code. The join
  // is accounts.coa_id = journal_lines.coa_id directly; chart_of_accounts is
  // not needed here and its key is `id`, not `coa_id`.
  const [cash] = await runner.query(
    `SELECT COALESCE(SUM(j.debit - j.credit), 0) AS net
       FROM journal_lines j
       JOIN transactions t ON t.id = j.transaction_id
       JOIN accounts a ON a.coa_id = j.coa_id
      WHERE t.status IN ('posted','reversed') AND ${historyFilter}`,
  );

  // For each row: which side it belongs to (its own direction, or for a
  // reversal its original's), its factor (+1, or -1 for a reversal), and how much
  // of it actually crossed the company's boundary (the amount, or for a
  // transfer leg only its charges). A reversal carries no breakdown of its own,
  // decision 052, so the original's charges are read.
  const [month] = await runner.query(
    `SELECT
        COALESCE(SUM(CASE WHEN m.side = 'in'  THEN m.factor * m.counted ELSE 0 END), 0) AS money_in,
        COALESCE(SUM(CASE WHEN m.side = 'out' THEN m.factor * m.counted ELSE 0 END), 0) AS money_out
       FROM (
         SELECT
           CASE WHEN o.id IS NULL THEN t.direction ELSE o.direction END AS side,
           CASE WHEN o.id IS NULL THEN 1 ELSE -1 END AS factor,
           CASE
             WHEN (CASE WHEN o.id IS NULL THEN t.transfer_group_id ELSE o.transfer_group_id END) IS NULL
               THEN t.amount
             ELSE (CASE WHEN o.id IS NULL THEN t.charges_total ELSE o.charges_total END)
           END AS counted
           FROM transactions t
           LEFT JOIN transactions o ON o.id = t.reversal_of_id
          WHERE t.status IN ('posted', 'reversed')
            AND t.entry_type = 'normal'
            AND t.account_id IS NOT NULL
            AND t.date >= ?
            AND t.date < ?
       ) AS m`,
    [monthStart, monthEnd],
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
