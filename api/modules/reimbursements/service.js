// What the company owes its people, and paying it back.
//
// When Ahmad buys a subscription on his own card, the company owes him.
// Decision 020: the entry credits a payable to that person, and the amount
// owed is computed from those entries, never stored. Worked example 1b in
// docs/CHART-OF-ACCOUNTS.md is the posting; this is everything around it.
//
// The payment back is an ordinary transaction, posted through the transactions
// service, so it gets a journal number, journal lines and an audit entry like
// anything else. The reimbursement rows only record which costs it cleared.

import { withTransaction, getPool } from '../../core/db.js';
import { AppError, ErrorCode, badRequest, forbidden, notFound } from '../../core/errors.js';
import { money, addMinor } from '../../core/money.js';
import { LedgerCode } from '../transactions/posting.js';
import * as transactions from '../transactions/service.js';
import * as repo from './repository.js';

const BASE_CURRENCY = 'PKR';
const POSTABLE_BY = new Set(['owner', 'admin']);

async function historyMerged(runner) {
  const value = await repo.readSetting(runner, 'history_merged');
  return value === 'true' || value === '1';
}

export async function listBalances() {
  const pool = getPool();
  const rows = await repo.owedToEveryone(pool, { historyMerged: await historyMerged(pool) });

  return {
    people: rows.map((row) => ({
      userId: Number(row.id),
      name: row.name,
      paidPersonally: money(Number(row.paid), BASE_CURRENCY),
      reimbursed: money(Number(row.repaid), BASE_CURRENCY),
      owed: money(Number(row.owed), BASE_CURRENCY),
    })),
    total: money(rows.reduce((sum, row) => sum + Number(row.owed), 0), BASE_CURRENCY),
  };
}

// The costs behind the figure, so a reimbursement can say what it covers.
export async function outstandingFor(userId) {
  const pool = getPool();
  const rows = await repo.outstandingFor(pool, userId, { historyMerged: await historyMerged(pool) });

  return {
    userId: Number(userId),
    items: rows.map((row) => ({
      transactionId: Number(row.id),
      journalNumber: row.journal_number,
      date: row.date,
      description: row.description,
      amount: money(Number(row.amount), BASE_CURRENCY),
      alreadyCovered: money(Number(row.covered), BASE_CURRENCY),
      remaining: money(Number(row.amount) - Number(row.covered), BASE_CURRENCY),
    })),
    owed: money(await repo.owedTo(pool, userId, { historyMerged: await historyMerged(pool) }), BASE_CURRENCY),
  };
}

/**
 * Pay someone back.
 *
 * input: { personUserId, accountId, date, method, items: [{ transactionId, amount }],
 *          reference, note, acknowledgedWarnings }
 *
 * Everything happens in one database transaction: the payment is created and
 * posted, and the reimbursement rows are written against it. If the second
 * half fails there is no payment left behind claiming to have cleared costs it
 * never cleared.
 */
export async function createReimbursement({ user, input, ip = null }) {
  if (!POSTABLE_BY.has(user.role)) {
    throw forbidden('Only the owner or an admin can pay someone back.');
  }
  if (!input.items || input.items.length === 0) {
    throw badRequest(ErrorCode.VALIDATION_FAILED, 'Say which costs this is paying back.');
  }

  const result = await withTransaction(async (connection) => {
    const merged = await historyMerged(connection);
    const owed = await repo.owedTo(connection, input.personUserId, { historyMerged: merged });
    const amount = addMinor(...input.items.map((item) => item.amount));

    if (amount <= 0) {
      throw badRequest(ErrorCode.VALIDATION_FAILED, 'A reimbursement must be above zero.');
    }

    // Paying back more than is owed would leave the payable overdrawn: the
    // company would be showing that its own employee owes it money, which is
    // not what happened. UI-GUIDE lists this as a blocking rule.
    if (amount > owed) {
      throw new AppError(
        400,
        ErrorCode.REIMBURSEMENT_EXCEEDS_OWED,
        `That is more than is owed. The outstanding amount is ${formatPkr(owed)}.`,
        { details: { owed, requested: amount } },
      );
    }

    const outstanding = await repo.outstandingFor(connection, input.personUserId, { historyMerged: merged });
    const remaining = new Map(
      outstanding.map((row) => [Number(row.id), Number(row.amount) - Number(row.covered)]),
    );

    for (const item of input.items) {
      const left = remaining.get(Number(item.transactionId));
      if (left === undefined) {
        throw badRequest(
          ErrorCode.VALIDATION_FAILED,
          `Entry ${item.transactionId} is not an outstanding cost for this person.`,
        );
      }
      if (item.amount > left) {
        throw badRequest(
          ErrorCode.VALIDATION_FAILED,
          `Entry ${item.transactionId} has only ${formatPkr(left)} left to pay back.`,
        );
      }
    }

    const categoryId = await repo.categoryForLedgerCode(connection, LedgerCode.PERSON_PAYABLE);
    if (!categoryId) {
      throw badRequest(
        ErrorCode.VALIDATION_FAILED,
        `No category posts to ledger account ${LedgerCode.PERSON_PAYABLE}, so a reimbursement cannot be recorded.`,
      );
    }

    // Money leaves a company account and clears the payable. Debit 2114,
    // credit the bank, which is exactly what the posting engine produces when
    // the category points at 2114.
    const draft = await transactions.createDraftWithin(connection, {
      user,
      ip,
      input: {
        date: input.date,
        direction: 'out',
        accountId: input.accountId,
        method: input.method ?? 'account',
        description: input.note ?? 'Reimbursement',
        categoryId,
        grossAmount: amount,
        reference: input.reference ?? null,
        receivedByUserId: input.personUserId,
        acknowledgedWarnings: input.acknowledgedWarnings ?? [],
      },
    });

    const posted = await transactions.approveWithin(connection, { user, id: draft.id, ip });

    const reimbursementId = await repo.insertReimbursement(connection, {
      personUserId: input.personUserId,
      transactionId: draft.id,
      amount,
      note: input.note ?? null,
      createdBy: user.id,
    });
    await repo.insertItems(connection, reimbursementId, input.items);

    return {
      id: reimbursementId,
      transactionId: draft.id,
      journalNumber: posted.journalNumber,
      amount: money(amount, BASE_CURRENCY),
      owedBefore: money(owed, BASE_CURRENCY),
      owedAfter: money(owed - amount, BASE_CURRENCY),
    };
  });

  return result;
}

export async function getBalanceFor(userId) {
  const pool = getPool();
  const rows = await repo.owedToEveryone(pool, { historyMerged: await historyMerged(pool) });
  const found = rows.find((row) => Number(row.id) === Number(userId));
  if (!found) throw notFound('Nothing has been paid personally by that person.');

  return {
    userId: Number(found.id),
    name: found.name,
    owed: money(Number(found.owed), BASE_CURRENCY),
  };
}

function formatPkr(minor) {
  return `PKR ${(minor / 100).toLocaleString('en-PK', { minimumFractionDigits: 2 })}`;
}
