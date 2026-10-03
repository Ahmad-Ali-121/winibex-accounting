// The posting engine, pure half.
//
// Give it a described entry and it returns the journal lines that entry must
// produce. No database, no connection, no clock, nothing async. That is
// deliberate: these rules are the part that cannot be wrong, and a pure
// function can be tested exhaustively in milliseconds against every worked
// example in docs/CHART-OF-ACCOUNTS.md.
//
// The service layer resolves names to ledger account ids and then writes what
// comes back. It does not decide any of this.
//
// Three shapes, all balanced:
//
//   Money out       debit the cost, debit what was added on top,
//                   credit what paid for it, credit what was held back
//   Money in        debit what received it, debit what was taken from it,
//                   credit the income or the receivable it settles
//   Manual journal  the caller supplies the lines; we only prove they balance

import { MoneyError, addMinor, assertBalanced, assertReconciled } from '../../core/money.js';

// Ledger codes the engine needs by name. They are system accounts in
// docs/CHART-OF-ACCOUNTS.md and cannot be renamed or deactivated, which is why
// naming them here is safe. The service turns each into an id.
export const LedgerCode = Object.freeze({
  REBILLABLE: '1123',       // Rebillable expenses recoverable
  TRANSIT: '1118',          // Funds in transit, internal. Both legs of a transfer
  PERSON_PAYABLE: '2114',   // Payable to employees, reimbursements
  BANK_CHARGES: '8100',     // Bank charges and FED
});

function line(coaId, side, amount, memo = null) {
  if (!coaId) throw new MoneyError(`a journal line has no ledger account: ${memo ?? side}`);
  return side === 'debit'
    ? { coaId, debit: amount, credit: 0, memo }
    : { coaId, debit: 0, credit: amount, memo };
}

// Tax taken from Winibex is a cost or a deduction, and is debited.
// Tax Winibex withheld is money owed to FBR, and is credited.
function isWithheld(tax) {
  return tax.deductedBy === 'us';
}

function totalOf(items) {
  return items.length === 0 ? 0 : addMinor(...items.map((item) => item.amount));
}

/**
 * entry:
 *   direction        'in' | 'out'
 *   gross            paisa, before tax and charges
 *   amount           paisa, the net effect on the settlement account
 *   settlementCoaId  the bank, cash or petty cash account's ledger code id,
 *                    or 2114 when a person paid personally
 *   categoryCoaId    where the cost or the income belongs
 *   isRebillable     true puts the cost in 1123 instead, so profit is untouched
 *   rebillableCoaId  1123, required when isRebillable
 *   taxes            [{ coaId, amount, deductedBy }]
 *   charges          [{ coaId, amount }]
 */
export function buildJournalLines(entry) {
  const {
    direction,
    gross,
    amount,
    settlementCoaId,
    categoryCoaId,
    isRebillable = false,
    rebillableCoaId = null,
    taxes = [],
    charges = [],
  } = entry;

  if (direction !== 'in' && direction !== 'out') {
    throw new MoneyError(`direction must be in or out, got ${String(direction)}`);
  }
  if (isRebillable && direction !== 'out') {
    throw new MoneyError('only money out can be rebillable');
  }

  const suffered = taxes.filter((tax) => !isWithheld(tax));
  const withheld = taxes.filter(isWithheld);

  if (direction === 'in' && withheld.length > 0) {
    throw new MoneyError('Winibex only withholds tax from someone it is paying');
  }

  // Proves the four money figures agree before a single line is built.
  assertReconciled({
    direction,
    amount,
    gross,
    tax: totalOf(suffered),
    charges: totalOf(charges),
    withheld: totalOf(withheld),
  });

  // Rebillable spend is an asset until it is invoiced, so it never reaches an
  // expense account and never touches profit. Decision 019.
  const costCoaId = isRebillable ? rebillableCoaId : categoryCoaId;
  if (isRebillable && !rebillableCoaId) {
    throw new MoneyError('rebillable spend needs ledger account 1123');
  }

  const lines = [];

  if (direction === 'out') {
    lines.push(line(costCoaId, 'debit', gross, isRebillable ? 'Rebillable to the client' : null));
    for (const charge of charges) lines.push(line(charge.coaId, 'debit', charge.amount, charge.note ?? null));
    for (const tax of suffered) lines.push(line(tax.coaId, 'debit', tax.amount, tax.note ?? null));
    for (const tax of withheld) lines.push(line(tax.coaId, 'credit', tax.amount, tax.note ?? 'Withheld, owed to FBR'));
    lines.push(line(settlementCoaId, 'credit', amount));
  } else {
    lines.push(line(settlementCoaId, 'debit', amount));
    for (const tax of suffered) lines.push(line(tax.coaId, 'debit', tax.amount, tax.note ?? null));
    for (const charge of charges) lines.push(line(charge.coaId, 'debit', charge.amount, charge.note ?? null));
    lines.push(line(categoryCoaId, 'credit', gross));
  }

  const numbered = lines.map((item, index) => ({ ...item, lineNo: index + 1 }));
  assertBalanced(numbered);
  return numbered;
}

// A manual journal entry, the opening entry, depreciation, FX revaluation.
// There is no form to derive these from, so the caller supplies the lines and
// the engine's job is to refuse anything that does not balance.
export function buildManualLines(lines) {
  const numbered = lines.map((item, index) => ({
    coaId: item.coaId,
    debit: item.debit ?? 0,
    credit: item.credit ?? 0,
    memo: item.memo ?? null,
    lineNo: index + 1,
  }));
  assertBalanced(numbered);
  return numbered;
}

// A reversal is exactly opposite, line for line, so the two entries together
// net to nothing on every account. Never recalculated from the form, because a
// rate or a tax rule may have changed since the original was posted.
export function reverseJournalLines(lines) {
  const flipped = lines.map((item, index) => ({
    coaId: item.coaId,
    debit: item.credit ?? 0,
    credit: item.debit ?? 0,
    memo: item.memo ?? null,
    lineNo: index + 1,
  }));
  assertBalanced(flipped);
  return flipped;
}
