// The cheque register.
//
// A record of what was written, to whom, and whether it has cleared. The money
// itself is an ordinary transaction with method = cheque, linked here, so the
// register never becomes a second set of books.
//
// Open for the accountant: whether an uncleared cheque should sit in 1114
// Cheques in hand until it clears, rather than leaving the bank on the day it
// was written. Today the entry posts against the bank when it is recorded, and
// this register is what makes the uncleared ones visible in the meantime.

import { withTransaction, getPool } from '../../core/db.js';
import { writeAudit, AuditAction } from '../../core/audit.js';
import { AppError, ErrorCode, badRequest, forbidden, notFound } from '../../core/errors.js';
import { money } from '../../core/money.js';
import * as repo from './repository.js';

const BASE_CURRENCY = 'PKR';
const MANAGED_BY = new Set(['owner', 'admin']);

// A cheque moves forward, never back. Clearing is the end of the story, and a
// cleared cheque cannot be cancelled afterwards because the money has gone.
const NEXT = Object.freeze({
  issued: ['presented', 'bounced', 'cancelled'],
  presented: ['cleared', 'bounced'],
  cleared: [],
  bounced: ['cancelled'],
  cancelled: [],
});

function present(row) {
  return {
    id: Number(row.id),
    accountId: Number(row.account_id),
    accountName: row.account_name,
    chequeNumber: row.cheque_number,
    payee: row.payee,
    amount: money(Number(row.amount), BASE_CURRENCY),
    issueDate: row.issue_date,
    status: row.status,
    clearedOn: row.cleared_on,
    transactionId: row.transaction_id === null ? null : Number(row.transaction_id),
    journalNumber: row.journal_number ?? null,
    note: row.note,
  };
}

export async function listCheques({ accountId = null, status = null } = {}) {
  const rows = await repo.list(getPool(), { accountId, status });

  // What is still out there is the figure that matters: cheques written but
  // not yet taken by the bank.
  const outstanding = rows
    .filter((row) => row.status === 'issued' || row.status === 'presented')
    .reduce((sum, row) => sum + Number(row.amount), 0);

  return {
    cheques: rows.map(present),
    outstanding: money(outstanding, BASE_CURRENCY),
  };
}

export async function getCheque(id) {
  const row = await repo.findById(getPool(), id);
  if (!row) throw notFound('That cheque is not in the register.');
  return present(row);
}

export async function issueCheque({ user, input, ip = null }) {
  if (!MANAGED_BY.has(user.role)) {
    throw forbidden('Only the owner or an admin can issue a cheque.');
  }

  const result = await withTransaction(async (connection) => {
    const id = await repo.insert(connection, {
      accountId: input.accountId,
      chequeNumber: input.chequeNumber,
      payee: input.payee,
      amount: input.amount,
      issueDate: input.issueDate,
      transactionId: input.transactionId ?? null,
      note: input.note ?? null,
      createdBy: user.id,
    });

    await writeAudit(connection, {
      userId: user.id, ip, table: 'cheques', recordId: id,
      action: AuditAction.INSERT,
      after: { chequeNumber: input.chequeNumber, payee: input.payee, amount: input.amount },
    });

    return id;
  });

  return getCheque(result);
}

export async function changeStatus({ user, id, status, clearedOn = null, ip = null }) {
  if (!MANAGED_BY.has(user.role)) {
    throw forbidden('Only the owner or an admin can update the cheque register.');
  }

  const result = await withTransaction(async (connection) => {
    const current = await repo.findById(connection, id);
    if (!current) throw notFound('That cheque is not in the register.');

    const allowed = NEXT[current.status] ?? [];
    if (!allowed.includes(status)) {
      throw new AppError(
        409,
        ErrorCode.INVALID_STATUS,
        `A ${current.status} cheque cannot become ${status}.`,
        { details: { from: current.status, allowed } },
      );
    }

    if (status === 'cleared' && !clearedOn) {
      throw badRequest(
        ErrorCode.VALIDATION_FAILED,
        'Record the date it cleared, so the bank statement can be reconciled against it.',
        { field: 'clearedOn' },
      );
    }

    await repo.setStatus(connection, id, status, status === 'cleared' ? clearedOn : null);

    await writeAudit(connection, {
      userId: user.id, ip, table: 'cheques', recordId: Number(id),
      action: AuditAction.STATUS_CHANGE,
      before: { status: current.status },
      after: { status, clearedOn },
    });

    return Number(id);
  });

  return getCheque(result);
}

export async function linkToTransaction({ user, id, transactionId, ip = null }) {
  if (!MANAGED_BY.has(user.role)) {
    throw forbidden('Only the owner or an admin can update the cheque register.');
  }

  const result = await withTransaction(async (connection) => {
    const current = await repo.findById(connection, id);
    if (!current) throw notFound('That cheque is not in the register.');

    await repo.linkTransaction(connection, id, transactionId);
    await writeAudit(connection, {
      userId: user.id, ip, table: 'cheques', recordId: Number(id),
      action: AuditAction.UPDATE,
      before: { transactionId: current.transaction_id },
      after: { transactionId },
    });

    return Number(id);
  });

  return getCheque(result);
}
