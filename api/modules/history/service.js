// The opening entry, and merging history into the live books.
//
// Decision 037. The books go live on 1 July 2026 with one entry holding every
// account's real balance at 30 June. Everything from March 2025 is entered
// afterwards as history, and is excluded from live balances until it has been
// proved to reconcile with that opening entry. Then the opening entry is
// reversed and history counts from that moment.
//
// The reason it works this way: no row is ever edited to switch history in.
// Inclusion is decided by one setting, and reversing the opening entry is an
// ordinary reversal, so there is nothing special for a later reader to untangle.

import { withTransaction, getPool } from '../../core/db.js';
import { writeAudit, AuditAction } from '../../core/audit.js';
import { AppError, ErrorCode, badRequest, forbidden } from '../../core/errors.js';
import { money, addMinor } from '../../core/money.js';
import { buildManualLines } from '../transactions/posting.js';
import * as transactions from '../transactions/service.js';
import * as repo from './repository.js';

const BASE_CURRENCY = 'PKR';
const EQUITY_CODE = '3400';   // Opening balance equity

export async function settings(runner = getPool()) {
  const liveFrom = await repo.readSetting(runner, 'books_live_from');
  const merged = await repo.readSetting(runner, 'history_merged');
  return {
    booksLiveFrom: liveFrom ?? '2026-07-01',
    historyMerged: merged === 'true' || merged === '1',
  };
}

// The day before the books went live is the date history closes on.
function dayBefore(date) {
  const value = new Date(`${date}T00:00:00Z`);
  value.setUTCDate(value.getUTCDate() - 1);
  return value.toISOString().slice(0, 10);
}

/**
 * Post the opening entry.
 *
 * input.balances: [{ code, amount }] where amount is the real balance at
 * 30 June in paisa, positive on the account's own normal side. A bank holding
 * 500,000 is { code: '1113', amount: 50000000 }. A director loan owed is
 * { code: '2210', amount: 50000000 }, because a liability's normal side is
 * credit. The balancing figure goes to 3400 and nobody supplies it.
 */
export async function createOpeningEntry({ user, input, ip = null }) {
  if (user.role !== 'owner') {
    throw forbidden('Only the owner can post the opening entry.');
  }
  if (!input.balances || input.balances.length === 0) {
    throw badRequest(ErrorCode.VALIDATION_FAILED, 'The opening entry needs the balances it is opening with.');
  }

  const result = await withTransaction(async (connection) => {
    const { booksLiveFrom } = await settings(connection);

    const existing = await repo.findOpeningEntry(connection);
    if (existing) {
      throw new AppError(
        409,
        'OPENING_ALREADY_EXISTS',
        `There is already an opening entry, ${existing.journal_number ?? `draft ${existing.id}`}.`,
      );
    }

    const codes = input.balances.map((balance) => String(balance.code));
    const ledger = await repo.coaByCodes(connection, codes);
    const byCode = new Map(ledger.map((row) => [row.code, row]));

    const lines = [];
    for (const balance of input.balances) {
      const account = byCode.get(String(balance.code));
      if (!account) {
        throw badRequest(ErrorCode.VALIDATION_FAILED, `There is no ledger account ${balance.code}.`);
      }
      if (account.is_header) {
        throw badRequest(ErrorCode.VALIDATION_FAILED, `${balance.code} is a heading and cannot hold a balance.`);
      }
      if (balance.amount === 0) continue;

      // An amount is given on the account's own normal side, which is how a
      // person reads a balance. The posting side follows from that.
      const onNormalSide = balance.amount > 0;
      const size = Math.abs(balance.amount);
      const debitSide = account.normal_balance === 'debit' ? onNormalSide : !onNormalSide;

      lines.push({
        coaId: Number(account.id),
        debit: debitSide ? size : 0,
        credit: debitSide ? 0 : size,
        memo: `Balance at ${dayBefore(booksLiveFrom)}`,
      });
    }

    if (lines.length === 0) {
      throw badRequest(ErrorCode.VALIDATION_FAILED, 'Every balance given was zero.');
    }

    // Whatever is left over is equity. Nobody supplies it, because it is a
    // consequence of the balances rather than a figure anyone knows.
    const debits = addMinor(...lines.map((line) => line.debit));
    const credits = addMinor(...lines.map((line) => line.credit));
    const equity = await repo.coaByCode(connection, EQUITY_CODE);
    if (!equity) {
      throw badRequest(ErrorCode.VALIDATION_FAILED, `Ledger account ${EQUITY_CODE} is missing.`);
    }

    const difference = debits - credits;
    if (difference !== 0) {
      lines.push({
        coaId: Number(equity.id),
        debit: difference < 0 ? -difference : 0,
        credit: difference > 0 ? difference : 0,
        memo: 'Opening balance equity, the balancing figure',
      });
    }

    const balanced = buildManualLines(lines);
    const total = addMinor(...balanced.map((line) => line.debit));

    const categoryId = await repo.categoryForLedgerCode(connection, EQUITY_CODE, 'in');
    if (!categoryId) {
      throw badRequest(
        ErrorCode.VALIDATION_FAILED,
        `No category posts to ledger account ${EQUITY_CODE}, so the opening entry cannot be recorded.`,
      );
    }

    const draft = await transactions.createDraftWithin(connection, {
      user,
      ip,
      input: {
        date: booksLiveFrom,
        direction: 'in',
        accountId: null,
        method: 'account',
        description: input.description ?? `Opening balances at ${dayBefore(booksLiveFrom)}`,
        categoryId,
        grossAmount: total,
        entryType: 'opening',
        acknowledgedWarnings: input.acknowledgedWarnings ?? [],
      },
    });

    // The lines are written before posting, because a manual entry has no form
    // to derive them from. approveWithin reads them, proves they balance, and
    // writes them back as the posted journal.
    await repo.insertJournalLines(connection, draft.id, balanced);
    const posted = await transactions.approveWithin(connection, { user, id: draft.id, ip });

    await writeAudit(connection, {
      userId: user.id, ip, table: 'transactions', recordId: draft.id,
      action: AuditAction.STATUS_CHANGE,
      after: { openingEntry: true, total, date: booksLiveFrom },
    });

    return {
      transactionId: draft.id,
      journalNumber: posted.journalNumber,
      date: booksLiveFrom,
      total: money(total, BASE_CURRENCY),
      lines: balanced.length,
    };
  });

  return result;
}

/**
 * Compare history against the opening entry, account by account.
 *
 * A difference means history is still missing or wrong. The merge is refused
 * while any of them is non-zero, which is the whole point: history goes in
 * when it reconciles, not when someone decides it is probably close enough.
 */
export async function mergeCheck() {
  const pool = getPool();
  const { booksLiveFrom, historyMerged } = await settings(pool);
  const closingDate = dayBefore(booksLiveFrom);

  const opening = await repo.openingByLedger(pool);
  const history = await repo.historyByLedger(pool, { upTo: closingDate });

  const byCode = new Map();
  for (const row of opening) {
    byCode.set(row.code, {
      code: row.code, name: row.name, type: row.type, opening: Number(row.net), history: 0,
    });
  }
  for (const row of history) {
    const existing = byCode.get(row.code)
      ?? { code: row.code, name: row.name, type: row.type, opening: 0, history: 0 };
    existing.history = Number(row.net);
    byCode.set(row.code, existing);
  }

  // Only positions are compared. An opening entry carries what the company
  // held and owed on 30 June, not what it earned or spent getting there: last
  // year's income and expense are absorbed into equity, so an income account
  // would always differ and the merge could never happen.
  //
  // 3400 is excluded for the same kind of reason. It is the balancing figure
  // of the opening entry and has no history behind it at all.
  const POSITIONS = new Set(['asset', 'liability', 'equity']);

  const rows = [...byCode.values()]
    .filter((row) => row.code !== EQUITY_CODE && POSITIONS.has(row.type))
    .map((row) => ({
      code: row.code,
      name: row.name,
      fromHistory: money(row.history, BASE_CURRENCY),
      fromOpeningEntry: money(row.opening, BASE_CURRENCY),
      difference: money(row.history - row.opening, BASE_CURRENCY),
    }))
    .sort((a, b) => a.code.localeCompare(b.code));

  const differences = rows.filter((row) => row.difference.minor !== 0);

  return {
    booksLiveFrom,
    closingDate,
    historyMerged,
    historicalEntries: await repo.countHistorical(pool),
    accounts: rows,
    differences,
    canMerge: !historyMerged && differences.length === 0 && rows.length > 0,
  };
}

/**
 * Merge history in.
 *
 * Reverses the opening entry and flips the setting. Nothing is edited: the
 * historical rows were always there, and from now on they count.
 */
export async function merge({ user, ip = null }) {
  if (user.role !== 'owner') {
    throw forbidden('Only the owner can merge history.');
  }

  const check = await mergeCheck();
  if (check.historyMerged) {
    throw new AppError(409, ErrorCode.INVALID_STATUS, 'History has already been merged.');
  }
  if (check.differences.length > 0) {
    throw new AppError(
      409,
      'HISTORY_DOES_NOT_RECONCILE',
      `${check.differences.length} account${check.differences.length === 1 ? '' : 's'} still differ from the opening entry.`,
      { details: { differences: check.differences } },
    );
  }

  const opening = await repo.findOpeningEntry(getPool());
  if (!opening) {
    throw badRequest(ErrorCode.VALIDATION_FAILED, 'There is no opening entry to reverse.');
  }

  const reversal = await transactions.reverse({
    user, id: Number(opening.id), reason: 'history merged', ip,
  });

  await withTransaction(async (connection) => {
    await repo.writeSetting(connection, 'history_merged', 'true', user.id);
    await writeAudit(connection, {
      userId: user.id, ip, table: 'settings', recordId: null,
      action: AuditAction.SETTING_CHANGE,
      before: { history_merged: 'false' },
      after: { history_merged: 'true', openingEntryReversedBy: reversal.reversalId },
    });
  });

  return {
    merged: true,
    openingEntryId: Number(opening.id),
    reversalId: reversal.reversalId,
    reversalJournalNumber: reversal.journalNumber,
  };
}
