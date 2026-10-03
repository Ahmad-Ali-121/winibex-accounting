// The posting service. The half with consequences.
//
// posting.js decides what the journal lines are. This decides whether the
// entry may exist, allocates its number, writes everything inside one database
// transaction, and records who did it. If any part fails, none of it happened.
//
// Permissions follow decision 036 and the Permissions table in docs/SCHEMA.md.
// The owner login and admins can post. Staff submit and wait. Nobody approves
// their own entry under the same login.

import { randomUUID } from 'node:crypto';

import { withTransaction, getPool } from '../../core/db.js';
import { allocate } from '../../core/sequences.js';
import { writeAudit, AuditAction } from '../../core/audit.js';
import { AppError, ErrorCode, badRequest, forbidden, notFound } from '../../core/errors.js';
import { MoneyError, addMinor, reconcileAmount, pkrFromForeign } from '../../core/money.js';
import { buildJournalLines, buildManualLines, reverseJournalLines, LedgerCode } from './posting.js';
import { collectBlocking, collectWarnings, collectFlags } from './validation.js';
import { assertReceiptRules } from '../attachments/service.js';
import * as repo from './repository.js';

const POSTABLE_BY = new Set(['owner', 'admin']);

function asMoneyError(error) {
  if (error instanceof MoneyError) {
    return badRequest(ErrorCode.NOT_RECONCILED, error.message);
  }
  return error;
}

function totalOf(items) {
  return items.length === 0 ? 0 : addMinor(...items.map((item) => item.amount));
}

// --- what the caller sends --------------------------------------------------

// Taxes split by who deducted them. Tax taken from Winibex adds to a payment
// or is deducted from a receipt. Tax Winibex withheld is held back and owed to
// FBR, so it reduces the payment. Decision 052.
function splitTaxes(taxes) {
  return {
    suffered: taxes.filter((tax) => tax.deductedBy !== 'us'),
    withheld: taxes.filter((tax) => tax.deductedBy === 'us'),
  };
}

function computeTotals(input) {
  const taxes = input.taxes ?? [];
  const charges = input.charges ?? [];
  const { suffered, withheld } = splitTaxes(taxes);

  const gross = input.grossAmount ?? pkrFromForeign(input.foreignAmount, input.fxRate);

  return {
    gross,
    taxTotal: totalOf(suffered),
    chargesTotal: totalOf(charges),
    withheldTotal: totalOf(withheld),
    amount: reconcileAmount({
      direction: input.direction,
      gross,
      tax: totalOf(suffered),
      charges: totalOf(charges),
      withheld: totalOf(withheld),
    }),
  };
}

// --- validation -------------------------------------------------------------

// Blocked stops the save. Warned stops it once, and goes through when the user
// confirms, with the confirmation recorded against the entry. Flagged saves
// quietly and appears in the review list. docs/UI-GUIDE.md, decision 013.
async function runValidation(connection, { user, input, amount, acknowledged = [], excludeId = null }) {
  const settings = await repo.readSettings(connection);

  const blocked = await collectBlocking(repo, connection, { input, amount, settings, excludeId });
  if (blocked.length > 0) {
    throw new AppError(400, blocked[0].code, blocked[0].message, {
      details: { blocked },
    });
  }

  const warnings = await collectWarnings(repo, connection, { input, amount, settings, excludeId });
  const unacknowledged = warnings.filter((warning) => !acknowledged.includes(warning.code));

  if (unacknowledged.length > 0) {
    // 409 with the warnings listed. The client shows them, the user confirms,
    // and the same request comes back with acknowledged_warnings. docs/API.md.
    throw new AppError(409, ErrorCode.VALIDATION_WARNINGS, 'Check these before saving.', {
      details: { warnings: unacknowledged },
    });
  }

  const flags = collectFlags({ input, hasReceipt: false });

  return [
    ...warnings.map((warning) => ({ ...warning, severity: 'warning', acknowledgedBy: user.id })),
    ...flags.map((flag) => ({ ...flag, severity: 'flag' })),
  ];
}

// --- create -----------------------------------------------------------------

// The body of createDraft, taking a connection rather than opening one, so
// another feature can create and post inside its own transaction and a
// failure in its second half leaves no orphan payment behind. This is the
// cross-feature interface decision 016 asks for: no other module reaches into
// this one's repository.
export async function createDraftWithin(connection, { user, input, ip = null }) {
  let totals;
  try {
    totals = computeTotals(input);
  } catch (error) {
    throw asMoneyError(error);
  }

  const findings = await runValidation(connection, {
    user, input, amount: totals.amount, acknowledged: input.acknowledgedWarnings ?? [],
  });

  const id = await repo.insertTransaction(connection, {
    date: input.date,
    account_id: input.accountId ?? null,
    direction: input.direction,
    amount: totals.amount,
    currency: input.currency ?? 'PKR',
    foreign_amount: input.foreignAmount ?? null,
    fx_rate: input.fxRate ?? null,
    fx_rate_source: input.fxRateSource ?? null,
    method: input.method,
    description: input.description,
    category_id: input.categoryId,
    client_id: input.clientId ?? null,
    project_id: input.projectId ?? null,
    is_rebillable: input.isRebillable ? 1 : 0,
    fund_source: input.fundSource ?? 'operations',
    paid_by_type: input.paidByType ?? 'company',
    paid_by_user_id: input.paidByUserId ?? null,
    received_by_user_id: input.receivedByUserId ?? null,
    vendor_id: input.vendorId ?? null,
    cheque_id: input.chequeId ?? null,
    gross_amount: totals.gross,
    tax_total: totals.taxTotal,
    charges_total: totals.chargesTotal,
    withheld_total: totals.withheldTotal,
    reference: input.reference ?? null,
    transfer_group_id: input.transferGroupId ?? null,
    status: 'draft',
    entry_type: input.entryType ?? 'normal',
    created_by: user.id,
  });

  await repo.insertTaxLines(connection, id, input.taxes ?? []);
  await repo.insertChargeLines(connection, id, input.charges ?? []);
  await repo.insertFlags(connection, id, findings);

  await writeAudit(connection, {
    userId: user.id,
    ip,
    table: 'transactions',
    recordId: id,
    action: AuditAction.INSERT,
    after: { status: 'draft', amount: totals.amount, description: input.description },
  });

  return { id, ...totals };
}

export async function createDraft({ user, input, ip = null }) {
  const result = await withTransaction((connection) =>
    createDraftWithin(connection, { user, input, ip }));
  return result;
}

// A draft may be changed freely. Posted is another matter: the trigger in
// migration 004 refuses it, and so does repo.updateDraft's WHERE clause, so a
// race that slipped past the status check below still cannot write.
export async function updateDraft({ user, id, input, ip = null }) {
  const result = await withTransaction(async (connection) => {
    const row = await requireEditableDraft(connection, id, user);

    let totals;
    try {
      totals = computeTotals(input);
    } catch (error) {
      throw asMoneyError(error);
    }

    const findings = await runValidation(connection, {
      user, input, amount: totals.amount,
      acknowledged: input.acknowledgedWarnings ?? [], excludeId: id,
    });

    const changed = await repo.updateDraft(connection, id, {
      date: input.date,
      account_id: input.accountId ?? null,
      direction: input.direction,
      amount: totals.amount,
      currency: input.currency ?? 'PKR',
      foreign_amount: input.foreignAmount ?? null,
      fx_rate: input.fxRate ?? null,
      fx_rate_source: input.fxRateSource ?? null,
      method: input.method,
      description: input.description,
      category_id: input.categoryId,
      client_id: input.clientId ?? null,
      project_id: input.projectId ?? null,
      is_rebillable: input.isRebillable ? 1 : 0,
      fund_source: input.fundSource ?? 'operations',
      paid_by_type: input.paidByType ?? 'company',
      paid_by_user_id: input.paidByUserId ?? null,
      received_by_user_id: input.receivedByUserId ?? null,
      vendor_id: input.vendorId ?? null,
      cheque_id: input.chequeId ?? null,
      gross_amount: totals.gross,
      tax_total: totals.taxTotal,
      charges_total: totals.chargesTotal,
      withheld_total: totals.withheldTotal,
      reference: input.reference ?? null,
      entry_type: input.entryType ?? 'normal',
    });

    if (changed !== 1) {
      throw new AppError(409, ErrorCode.ENTRY_NOT_EDITABLE, 'Only a draft can be changed.');
    }

    // The tax and charge lines are replaced rather than patched. Working out
    // which of them the user edited would be guesswork, and a stale line left
    // behind would make the totals disagree with the lines they came from. The
    // warnings and flags go the same way: they described the old figures.
    await repo.deleteChildRows(connection, id);
    await repo.insertTaxLines(connection, id, input.taxes ?? []);
    await repo.insertChargeLines(connection, id, input.charges ?? []);
    await repo.clearFlags(connection, id);
    await repo.insertFlags(connection, id, findings);

    await writeAudit(connection, {
      userId: user.id,
      ip,
      table: 'transactions',
      recordId: id,
      action: AuditAction.UPDATE,
      before: { amount: Number(row.amount), description: row.description },
      after: { amount: totals.amount, description: input.description },
    });

    return { id, ...totals };
  });

  return result;
}

// --- lifecycle --------------------------------------------------------------

export async function submitForApproval({ user, id, ip = null }) {
  const result = await withTransaction(async (connection) => {
    const row = await requireEditableDraft(connection, id, user);

    await repo.setStatus(connection, id, 'pending');
    await writeAudit(connection, {
      userId: user.id, ip, table: 'transactions', recordId: id,
      action: AuditAction.STATUS_CHANGE,
      before: { status: row.status }, after: { status: 'pending' },
    });

    return { id, status: 'pending' };
  });

  return result;
}

export async function reject({ user, id, reason, ip = null }) {
  if (!reason) throw badRequest(ErrorCode.VALIDATION_FAILED, 'Say why it is being rejected.');

  const result = await withTransaction(async (connection) => {
    const row = await repo.lockById(connection, id);
    if (!row) throw notFound('That entry does not exist.');
    if (row.status !== 'pending') {
      throw new AppError(409, ErrorCode.INVALID_STATUS, 'Only a submitted entry can be rejected.');
    }
    assertCanApprove(user, row);

    await repo.setStatus(connection, id, 'rejected', { rejection_reason: reason });
    await writeAudit(connection, {
      userId: user.id, ip, table: 'transactions', recordId: id,
      action: AuditAction.STATUS_CHANGE,
      before: { status: row.status }, after: { status: 'rejected', reason },
    });

    return { id, status: 'rejected' };
  });

  return result;
}

// Approving is posting. There is no separate step, because an approved entry
// that is not yet in the book would be a third state nobody can see.
export async function approveWithin(connection, { user, id, ip = null }) {
  const row = await repo.lockById(connection, id);
  if (!row) throw notFound('That entry does not exist.');
  if (row.status !== 'pending' && row.status !== 'draft') {
    throw new AppError(409, ErrorCode.INVALID_STATUS, 'Only a draft or submitted entry can be posted.');
  }

  assertCanApprove(user, row);
  const method = approvalMethodFor(user, row);
  const selfApproval = await sharesOwnerLogin(connection, user, row);

  return post(connection, { row, user, ip, approvalMethod: method, possibleSelfApproval: selfApproval });
}

export async function approve({ user, id, ip = null }) {
  const result = await withTransaction((connection) =>
    approveWithin(connection, { user, id, ip }));
  return result;
}

// --- the posting itself -----------------------------------------------------

async function post(connection, { row, user, ip, approvalMethod, possibleSelfApproval }) {
  // A payment above the threshold needs its receipt before it goes in the
  // book, not afterwards. Checked here rather than at draft time, because the
  // photo is usually attached after the form is filled in.
  await assertReceiptRules(connection, {
    transactionId: Number(row.id),
    amount: Number(row.amount),
    direction: row.direction,
    entryType: row.entry_type,
    transferGroupId: row.transfer_group_id,
    categoryId: row.category_id,
  });

  const { lines, alreadyWritten } = await buildLinesFor(connection, row);

  // The number is allocated here, inside the same transaction as the insert,
  // so a failure hands it straight back and the series keeps no hole.
  // Decisions 015 and 051.
  const { formatted: journalNumber } = await allocate(connection, 'journal');

  if (!alreadyWritten) await repo.insertJournalLines(connection, row.id, lines);

  const posted = await repo.markPosted(connection, row.id, {
    journalNumber, approvedBy: user.id, approvalMethod, possibleSelfApproval,
  });
  if (posted !== 1) {
    throw new AppError(409, ErrorCode.INVALID_STATUS, 'That entry was already posted by someone else.');
  }

  await writeAudit(connection, {
    userId: user.id, ip, table: 'transactions', recordId: Number(row.id),
    action: AuditAction.STATUS_CHANGE,
    before: { status: row.status },
    after: { status: 'posted', journalNumber, approvalMethod, possibleSelfApproval },
  });

  return { id: Number(row.id), status: 'posted', journalNumber, lines, alreadyWritten };
}

async function buildLinesFor(connection, row) {
  // A manual journal entry or the opening entry has no form to derive from.
  // Its lines are supplied and stored on the draft, and all we do is prove
  // they balance.
  if (row.entry_type === 'journal' || row.entry_type === 'opening') {
    const [stored] = await connection.query(
      'SELECT coa_id AS coaId, debit, credit, memo FROM journal_lines WHERE transaction_id = ? ORDER BY line_no',
      [row.id],
    );
    if (stored.length === 0) {
      throw badRequest(ErrorCode.UNBALANCED_JOURNAL, 'A journal entry needs its lines.');
    }

    // The lines were written with the draft, because a manual entry has no
    // form to derive them from. All that is left is to prove they balance.
    // They are not rewritten: journal lines are written once and never
    // deleted, which the trigger in migration 004 enforces regardless of what
    // this code tries to do.
    buildManualLines(stored.map((line) => ({
      coaId: Number(line.coaId), debit: Number(line.debit), credit: Number(line.credit), memo: line.memo,
    })));

    return { lines: [], alreadyWritten: true };
  }

  const [taxRows] = await connection.query(
    `SELECT t.tax_amount AS amount, t.deducted_by AS deductedBy, x.coa_id AS coaId
       FROM transaction_taxes t JOIN taxes x ON x.id = t.tax_id
      WHERE t.transaction_id = ? ORDER BY t.id`,
    [row.id],
  );
  const [chargeRows] = await connection.query(
    'SELECT amount, coa_id AS coaId, note FROM transaction_charges WHERE transaction_id = ? ORDER BY id',
    [row.id],
  );

  const settlementCoaId = await settlementAccount(connection, row);
  const category = await repo.categoryCoaId(connection, row.category_id);
  if (!category) throw badRequest(ErrorCode.VALIDATION_FAILED, 'That category does not exist.');

  const rebillableCoaId = row.is_rebillable
    ? await repo.coaIdByCode(connection, LedgerCode.REBILLABLE)
    : null;

  try {
    return { alreadyWritten: false, lines: buildJournalLines({
      direction: row.direction,
      gross: Number(row.gross_amount),
      amount: Number(row.amount),
      settlementCoaId,
      categoryCoaId: Number(category.coa_id),
      isRebillable: Boolean(row.is_rebillable),
      rebillableCoaId,
      taxes: taxRows.map((tax) => ({
        coaId: Number(tax.coaId), amount: Number(tax.amount), deductedBy: tax.deductedBy,
      })),
      charges: chargeRows.map((charge) => ({
        coaId: Number(charge.coaId), amount: Number(charge.amount), note: charge.note,
      })),
    }) };
  } catch (error) {
    throw asMoneyError(error);
  }
}

// Where the money came from or went to. A person paying personally settles
// against the payable to that person, not against a company account.
async function settlementAccount(connection, row) {
  if (row.paid_by_type === 'person') {
    const coaId = await repo.coaIdByCode(connection, LedgerCode.PERSON_PAYABLE);
    if (!coaId) throw badRequest(ErrorCode.VALIDATION_FAILED, `Ledger account ${LedgerCode.PERSON_PAYABLE} is missing.`);
    return coaId;
  }

  const account = await repo.accountCoaId(connection, row.account_id);
  if (!account) throw badRequest(ErrorCode.VALIDATION_FAILED, 'That account does not exist.');
  if (!account.is_active) throw badRequest(ErrorCode.VALIDATION_FAILED, 'That account is no longer in use.');
  return Number(account.coa_id);
}

// --- reversal ---------------------------------------------------------------

// A correction is never an edit. Decision 012. The reversal carries no tax or
// charge breakdown of its own, because for money in the amount subtracts them
// and repeating the split would not reconcile. Its lines mirror the original,
// flipped, so the two together net to nothing. Decision 052.
export async function reverse({ user, id, reason, ip = null }) {
  if (!reason) throw badRequest(ErrorCode.VALIDATION_FAILED, 'Say why it is being reversed.');

  const result = await withTransaction(async (connection) => {
    const row = await repo.lockById(connection, id);
    if (!row) throw notFound('That entry does not exist.');

    // Already reversed is checked first. Its status is 'reversed' by then, so
    // the status check below would otherwise answer with the less useful
    // "only a posted entry can be reversed".
    if (row.status === 'reversed' || row.reversed_by_id) {
      throw new AppError(409, ErrorCode.ALREADY_REVERSED, 'That entry has already been reversed.');
    }
    if (row.status !== 'posted') {
      throw new AppError(409, ErrorCode.INVALID_STATUS, 'Only a posted entry can be reversed.');
    }
    if (!POSTABLE_BY.has(user.role)) {
      throw forbidden('Only the owner or an admin can reverse an entry.');
    }

    const [originalLines] = await connection.query(
      'SELECT coa_id AS coaId, debit, credit, memo FROM journal_lines WHERE transaction_id = ? ORDER BY line_no',
      [id],
    );
    const lines = reverseJournalLines(originalLines.map((line) => ({
      coaId: Number(line.coaId), debit: Number(line.debit), credit: Number(line.credit), memo: line.memo,
    })));

    const reversalId = await repo.insertTransaction(connection, {
      date: row.date,
      account_id: row.account_id,
      direction: row.direction === 'out' ? 'in' : 'out',
      amount: Number(row.amount),
      currency: row.currency,
      foreign_amount: row.foreign_amount,
      fx_rate: row.fx_rate,
      fx_rate_source: row.fx_rate_source,
      method: row.method,
      description: `Reversal of ${row.journal_number}: ${reason}`.slice(0, 255),
      category_id: row.category_id,
      client_id: row.client_id,
      project_id: row.project_id,
      is_rebillable: 0,
      fund_source: row.fund_source,
      paid_by_type: row.paid_by_type,
      paid_by_user_id: row.paid_by_user_id,
      gross_amount: Number(row.amount),
      tax_total: 0,
      charges_total: 0,
      withheld_total: 0,
      status: 'draft',
      entry_type: row.entry_type,
      created_by: user.id,
    });

    await connection.query(
      'UPDATE transactions SET reversal_of_id = ?, reversal_reason = ? WHERE id = ?',
      [id, reason, reversalId],
    );

    const { formatted: journalNumber } = await allocate(connection, 'journal');
    await repo.insertJournalLines(connection, reversalId, lines);
    await repo.markPosted(connection, reversalId, {
      journalNumber, approvedBy: user.id, approvalMethod: user.role === 'owner' ? 'owner' : 'admin',
      possibleSelfApproval: false,
    });

    const marked = await repo.markReversed(connection, id, reversalId);
    if (marked !== 1) {
      throw new AppError(409, ErrorCode.ALREADY_REVERSED, 'That entry was reversed by someone else.');
    }

    await writeAudit(connection, {
      userId: user.id, ip, table: 'transactions', recordId: Number(id),
      action: AuditAction.STATUS_CHANGE,
      before: { status: 'posted' },
      after: { status: 'reversed', reversedBy: reversalId, reason },
    });

    return { id: Number(id), reversalId, journalNumber, lines };
  });

  return result;
}

// --- permissions ------------------------------------------------------------

function assertCanApprove(user, row) {
  if (!POSTABLE_BY.has(user.role)) {
    throw forbidden('Only the owner or an admin can approve an entry.');
  }

  // Nobody approves their own entry under the same login. The owner login and
  // admins with auto_approve_own post their own entries directly instead,
  // which is recorded as approval_method = auto rather than hidden.
  const isOwnEntry = Number(row.created_by) === Number(user.id);
  if (isOwnEntry && !(user.role === 'owner' || user.autoApproveOwn)) {
    throw forbidden('Someone else has to approve an entry you created.');
  }

  if (user.role === 'admin' && user.approvalLimit !== null && user.approvalLimit !== undefined) {
    if (Number(row.amount) > Number(user.approvalLimit)) {
      throw new AppError(403, ErrorCode.APPROVAL_LIMIT_EXCEEDED, 'That entry is above your approval limit.');
    }
  }
}

function approvalMethodFor(user, row) {
  const isOwnEntry = Number(row.created_by) === Number(user.id);
  if (isOwnEntry) return 'auto';
  return user.role === 'owner' ? 'owner' : 'admin';
}

// The owner login is shared, so an approval cannot always be tied to one
// person. When it approves an entry made by someone who also uses it, the
// transaction is marked. A silent record, no review queue. Decision 036.
async function sharesOwnerLogin(connection, user, row) {
  if (user.role !== 'owner') return false;
  if (Number(row.created_by) === Number(user.id)) return false;

  const creator = await repo.findUser(connection, row.created_by);
  return Boolean(creator?.shares_owner_login);
}

async function requireEditableDraft(connection, id, user) {
  const row = await repo.lockById(connection, id);
  if (!row) throw notFound('That entry does not exist.');
  if (row.status !== 'draft') {
    throw new AppError(409, ErrorCode.ENTRY_NOT_EDITABLE, 'Only a draft can be changed.');
  }
  if (Number(row.created_by) !== Number(user.id) && !POSTABLE_BY.has(user.role)) {
    throw forbidden('That is not your draft.');
  }
  return row;
}

// --- transfers --------------------------------------------------------------

// Moving money between two company accounts is two rows sharing a group id,
// never one. SCHEMA.md says so, and the reason is that people look for a
// transfer on both accounts' ledgers, not on one.
//
// Each leg has to balance on its own, so both pass through 1118 Funds in
// transit, internal:
//
//   Out of the source        debit 1118,        credit the source account
//   Into the destination     debit the account, credit 1118
//
// 1118 nets to zero the moment both legs are posted. A transfer caught between
// them is visible rather than invisible, which is the point of having it.
//
// A bank fee on the transfer is a charge on the out leg, so the source loses
// the amount plus the fee while the destination receives the amount. That is
// what UI-GUIDE means by legs that do not match unless the difference is a fee.
export async function createTransfer({ user, input, ip = null }) {
  if (!POSTABLE_BY.has(user.role)) {
    throw forbidden('Only the owner or an admin can move money between accounts.');
  }
  if (Number(input.fromAccountId) === Number(input.toAccountId)) {
    throw new AppError(
      400,
      ErrorCode.TRANSFER_SAME_ACCOUNT,
      'A transfer needs two different accounts.',
      { field: 'toAccountId' },
    );
  }

  const result = await withTransaction(async (connection) => {
    const from = await repo.accountById(connection, input.fromAccountId);
    const to = await repo.accountById(connection, input.toAccountId);
    if (!from) throw badRequest(ErrorCode.VALIDATION_FAILED, 'The account money is leaving does not exist.');
    if (!to) throw badRequest(ErrorCode.VALIDATION_FAILED, 'The account money is going to does not exist.');

    const outCategory = await repo.categoryForLedgerCode(connection, LedgerCode.TRANSIT, 'out');
    const inCategory = await repo.categoryForLedgerCode(connection, LedgerCode.TRANSIT, 'in');
    if (!outCategory || !inCategory) {
      throw badRequest(
        ErrorCode.VALIDATION_FAILED,
        `No transfer categories post to ledger account ${LedgerCode.TRANSIT}.`,
      );
    }

    const groupId = randomUUID();
    const acknowledged = input.acknowledgedWarnings ?? [];
    const description = input.description ?? `Transfer from ${from.name} to ${to.name}`;

    const charges = [];
    if (input.fee > 0) {
      const chargeCoa = await repo.coaIdByCode(connection, LedgerCode.BANK_CHARGES);
      charges.push({ type: 'bank_charge', amount: input.fee, coaId: chargeCoa, note: 'Transfer fee' });
    }

    const outLeg = await createDraftWithin(connection, {
      user, ip,
      input: {
        date: input.date,
        direction: 'out',
        accountId: input.fromAccountId,
        method: input.method ?? 'account',
        description,
        categoryId: outCategory,
        grossAmount: input.amount,
        charges,
        reference: input.reference ?? null,
        transferGroupId: groupId,
        acknowledgedWarnings: acknowledged,
      },
    });
    const postedOut = await approveWithin(connection, { user, id: outLeg.id, ip });

    const inLeg = await createDraftWithin(connection, {
      user, ip,
      input: {
        date: input.date,
        direction: 'in',
        accountId: input.toAccountId,
        method: input.method ?? 'account',
        description,
        categoryId: inCategory,
        grossAmount: input.amount,
        reference: input.reference ?? null,
        transferGroupId: groupId,
        acknowledgedWarnings: acknowledged,
      },
    });
    const postedIn = await approveWithin(connection, { user, id: inLeg.id, ip });

    return {
      transferGroupId: groupId,
      amount: input.amount,
      fee: input.fee ?? 0,
      from: { accountId: Number(input.fromAccountId), name: from.name, transactionId: outLeg.id, journalNumber: postedOut.journalNumber },
      to: { accountId: Number(input.toAccountId), name: to.name, transactionId: inLeg.id, journalNumber: postedIn.journalNumber },
    };
  });

  return result;
}

export async function getTransfer(groupId) {
  const [rows] = await getPool().query(
    `SELECT id, journal_number, date, direction, amount, account_id, description, status
       FROM transactions WHERE transfer_group_id = ? ORDER BY direction DESC, id`,
    [groupId],
  );
  if (rows.length === 0) throw notFound('That transfer does not exist.');
  return { transferGroupId: groupId, legs: rows };
}

// --- preview ----------------------------------------------------------------

// The journal entry an entry would produce, without saving anything.
//
// UI-GUIDE requires the lines to be visible before the person commits, and
// AGENTS.md says the app never works out anything financial. So the preview
// has to come from the server, and it comes from the same buildJournalLines
// the real posting uses. A preview built by a second code path would be a
// second opinion, and the one on screen would be the one nobody checked.
export async function previewJournal({ input }) {
  const pool = getPool();

  let totals;
  try {
    totals = computeTotals(input);
  } catch (error) {
    throw asMoneyError(error);
  }

  const category = await repo.categoryCoaId(pool, input.categoryId);
  if (!category) throw badRequest(ErrorCode.VALIDATION_FAILED, 'That category does not exist.');

  const settlementCoaId = input.paidByType === 'person'
    ? await repo.coaIdByCode(pool, LedgerCode.PERSON_PAYABLE)
    : await settlementFromAccount(pool, input.accountId);

  const rebillableCoaId = input.isRebillable
    ? await repo.coaIdByCode(pool, LedgerCode.REBILLABLE)
    : null;

  const taxes = input.taxes ?? [];
  const taxCoaIds = await repo.taxCoaIds(pool, taxes.map((tax) => tax.taxId));

  let lines;
  try {
    lines = buildJournalLines({
      direction: input.direction,
      gross: totals.gross,
      amount: totals.amount,
      settlementCoaId,
      categoryCoaId: Number(category.coa_id),
      isRebillable: Boolean(input.isRebillable),
      rebillableCoaId,
      taxes: taxes.map((tax) => ({
        coaId: taxCoaIds.get(Number(tax.taxId)),
        amount: tax.amount,
        deductedBy: tax.deductedBy,
      })),
      charges: (input.charges ?? []).map((charge) => ({
        coaId: charge.coaId, amount: charge.amount, note: charge.note,
      })),
    });
  } catch (error) {
    throw asMoneyError(error);
  }

  // The codes and names come back too, because a preview showing only ids
  // tells the person nothing they can check.
  const described = await repo.describeLedgerAccounts(pool, lines.map((line) => line.coaId));

  return {
    totals: {
      gross: totals.gross,
      taxTotal: totals.taxTotal,
      chargesTotal: totals.chargesTotal,
      withheldTotal: totals.withheldTotal,
      amount: totals.amount,
    },
    lines: lines.map((line) => ({
      ...line,
      code: described.get(line.coaId)?.code ?? null,
      name: described.get(line.coaId)?.name ?? null,
    })),
  };
}

async function settlementFromAccount(runner, accountId) {
  if (!accountId) {
    throw badRequest(ErrorCode.VALIDATION_FAILED, 'Say which account the money moved on.');
  }
  const account = await repo.accountCoaId(runner, accountId);
  if (!account) throw badRequest(ErrorCode.VALIDATION_FAILED, 'That account does not exist.');
  return Number(account.coa_id);
}

// --- reading the ledger -----------------------------------------------------

const MAX_PAGE_SIZE = 100;

function summarise(row) {
  return {
    id: Number(row.id),
    journalNumber: row.journal_number ?? null,
    date: row.date,
    direction: row.direction,
    amount: { minor: Number(row.amount), currency: row.currency ?? 'PKR' },
    description: row.description,
    status: row.status,
    entryType: row.entry_type,
    accountName: row.account_name ?? null,
    categoryName: row.category_name ?? null,
    createdByName: row.created_by_name ?? null,
    flagCount: Number(row.flag_count ?? 0),
    isReversed: Boolean(row.reversed_by_id),
    isReversal: Boolean(row.reversal_of_id),
  };
}

/**
 * The ledger, searched and filtered on the server.
 *
 * A draft is private to whoever created it until they submit it. Everything
 * else is visible, because a ledger that hides rows from some people is two
 * different books.
 */
export async function listTransactions({ user, filters }) {
  const pageSize = Math.min(filters.pageSize ?? 50, MAX_PAGE_SIZE);
  const page = filters.page ?? 1;

  const { rows, total } = await repo.listLedger(getPool(), {
    ...filters,
    userId: user.id,
    page,
    pageSize,
  });

  return {
    transactions: rows.map(summarise),
    page,
    pageSize,
    total,
    hasMore: page * pageSize < total,
  };
}

export async function listApprovals({ user }) {
  const rows = await repo.listPending(getPool());

  return {
    approvals: rows.map((row) => ({
      ...summarise(row),
      createdBy: Number(row.created_by),
      submittedAt: row.created_at,
      // Nobody approves their own entry under the same login, so the inbox
      // says up front which ones this person cannot act on. Decision 036.
      isOwnEntry: Number(row.created_by) === Number(user.id),
    })),
  };
}

export async function listFlags({ resolved = false, severity = null } = {}) {
  const rows = await repo.listFlags(getPool(), { resolved, severity });

  return {
    flags: rows.map((row) => ({
      id: Number(row.id),
      transactionId: Number(row.transaction_id),
      severity: row.severity,
      code: row.code,
      detail: row.detail,
      resolved: Boolean(row.resolved),
      acknowledgedByName: row.acknowledged_by_name ?? null,
      createdAt: row.created_at,
      transaction: {
        journalNumber: row.journal_number ?? null,
        date: row.date,
        description: row.description,
        amount: { minor: Number(row.amount), currency: 'PKR' },
        status: row.status,
      },
    })),
  };
}

export async function getDetail(id) {
  const detail = await repo.findDetail(getPool(), id);
  if (!detail) throw notFound('That entry does not exist.');
  return detail;
}
