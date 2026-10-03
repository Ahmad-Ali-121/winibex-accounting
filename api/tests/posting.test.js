// Every worked posting in docs/CHART-OF-ACCOUNTS.md, asserted to the exact
// journal line. If the chart document and the engine ever disagree, this file
// fails. TESTING.md requires that, and it is the reason the chart can be
// trusted as documentation rather than as a hopeful sketch.
//
// No database. The ledger codes below stand in for the ids the service
// resolves from chart_of_accounts.

import test from 'node:test';
import assert from 'node:assert/strict';

import { buildJournalLines, buildManualLines, reverseJournalLines, LedgerCode } from '../modules/transactions/posting.js';
import { MoneyError } from '../core/money.js';

// Ledger codes used as ids here, so a failure reads like the chart.
const COA = {
  bank: '1113',
  rebillable: '1123',
  advanceTax: '1141',
  receivableForeign: '1122',
  receivableLocal: '1121',
  personPayable: '2114',
  withholdingPayable: '2132',
  directorLoan: '2210',
  exportRevenue: '4110',
  absorbedAds: '5200',
  platformFee: '5400',
  partnerShare: '5500',
  outsourcing: '5100',
  salaries: '6100',
  subscriptions: '6400',
  bankCharges: '8100',
  forexFees: '8200',
  finalTax: '9100',
};

// Compares only what matters: which account, which side, how much.
function asPostings(lines) {
  return lines.map((line) => ({ coaId: line.coaId, debit: line.debit, credit: line.credit }));
}

test('1a. a $20 subscription on the company card', () => {
  // Rate 280. The bank adds s.236Y at 0.5%, a forex fee and FED on the fee.
  const lines = buildJournalLines({
    direction: 'out',
    gross: 560000,
    amount: 595300,
    settlementCoaId: COA.bank,
    categoryCoaId: COA.subscriptions,
    taxes: [{ coaId: COA.advanceTax, amount: 2800, deductedBy: 'bank' }],
    charges: [
      { coaId: COA.forexFees, amount: 28000 },
      { coaId: COA.bankCharges, amount: 4500 },
    ],
  });

  assert.deepEqual(asPostings(lines), [
    { coaId: COA.subscriptions, debit: 560000, credit: 0 },
    { coaId: COA.forexFees, debit: 28000, credit: 0 },
    { coaId: COA.bankCharges, debit: 4500, credit: 0 },
    { coaId: COA.advanceTax, debit: 2800, credit: 0 },
    { coaId: COA.bank, debit: 0, credit: 595300 },
  ]);
});

test('1b. the same subscription on Ahmad personal card', () => {
  // The 236Y is collected against Ahmad's tax number, so it is not the
  // company's credit. It is absorbed into the forex fee line and the company
  // owes Ahmad the whole 5,953.
  const lines = buildJournalLines({
    direction: 'out',
    gross: 560000,
    amount: 595300,
    settlementCoaId: COA.personPayable,
    categoryCoaId: COA.subscriptions,
    charges: [
      { coaId: COA.forexFees, amount: 30800 },
      { coaId: COA.bankCharges, amount: 4500 },
    ],
  });

  assert.deepEqual(asPostings(lines), [
    { coaId: COA.subscriptions, debit: 560000, credit: 0 },
    { coaId: COA.forexFees, debit: 30800, credit: 0 },
    { coaId: COA.bankCharges, debit: 4500, credit: 0 },
    { coaId: COA.personPayable, debit: 0, credit: 595300 },
  ]);
  assert.equal(LedgerCode.PERSON_PAYABLE, '2114');
});

test('1b continued. reimbursing Ahmad clears the payable', () => {
  const lines = buildJournalLines({
    direction: 'out',
    gross: 595300,
    amount: 595300,
    settlementCoaId: COA.bank,
    categoryCoaId: COA.personPayable,
  });

  assert.deepEqual(asPostings(lines), [
    { coaId: COA.personPayable, debit: 595300, credit: 0 },
    { coaId: COA.bank, debit: 0, credit: 595300 },
  ]);
});

test('2. a foreign client pays a $500 invoice', () => {
  // Rate 278. The bank deducts s.154A final tax at 0.25%.
  const lines = buildJournalLines({
    direction: 'in',
    gross: 13900000,
    amount: 13865250,
    settlementCoaId: COA.bank,
    categoryCoaId: COA.receivableForeign,
    taxes: [{ coaId: COA.finalTax, amount: 34750, deductedBy: 'bank' }],
  });

  assert.deepEqual(asPostings(lines), [
    { coaId: COA.bank, debit: 13865250, credit: 0 },
    { coaId: COA.finalTax, debit: 34750, credit: 0 },
    { coaId: COA.receivableForeign, debit: 0, credit: 13900000 },
  ]);
});

test('3. rebillable ad spend never touches profit', () => {
  const spend = buildJournalLines({
    direction: 'out',
    gross: 5000000,
    amount: 5000000,
    settlementCoaId: COA.bank,
    categoryCoaId: COA.absorbedAds,
    isRebillable: true,
    rebillableCoaId: COA.rebillable,
  });

  assert.deepEqual(asPostings(spend), [
    { coaId: COA.rebillable, debit: 5000000, credit: 0 },
    { coaId: COA.bank, debit: 0, credit: 5000000 },
  ]);

  // Invoicing it moves the asset to a receivable. Still no expense anywhere.
  const invoiced = buildManualLines([
    { coaId: COA.receivableLocal, debit: 5000000 },
    { coaId: COA.rebillable, credit: 5000000 },
  ]);
  assert.deepEqual(asPostings(invoiced), [
    { coaId: COA.receivableLocal, debit: 5000000, credit: 0 },
    { coaId: COA.rebillable, debit: 0, credit: 5000000 },
  ]);
});

test('4. absorbed ad spend is an ordinary cost', () => {
  const lines = buildJournalLines({
    direction: 'out',
    gross: 5000000,
    amount: 5000000,
    settlementCoaId: COA.bank,
    categoryCoaId: COA.absorbedAds,
  });

  assert.deepEqual(asPostings(lines), [
    { coaId: COA.absorbedAds, debit: 5000000, credit: 0 },
    { coaId: COA.bank, debit: 0, credit: 5000000 },
  ]);
});

test('5. an Upwork earning through Jake ID', () => {
  // Gross PKR 120,000. Upwork takes 10%, Jake takes half of what remains.
  // The sheet records only the 54,000 that arrives, which is the whole point:
  // 66,000 of real cost and the true revenue figure are invisible today.
  const lines = buildJournalLines({
    direction: 'in',
    gross: 12000000,
    amount: 5400000,
    settlementCoaId: COA.bank,
    categoryCoaId: COA.exportRevenue,
    charges: [
      { coaId: COA.platformFee, amount: 1200000 },
      { coaId: COA.partnerShare, amount: 5400000 },
    ],
  });

  assert.deepEqual(asPostings(lines), [
    { coaId: COA.bank, debit: 5400000, credit: 0 },
    { coaId: COA.platformFee, debit: 1200000, credit: 0 },
    { coaId: COA.partnerShare, debit: 5400000, credit: 0 },
    { coaId: COA.exportRevenue, debit: 0, credit: 12000000 },
  ]);
});

test('6. investor money is a liability, never income', () => {
  const lines = buildJournalLines({
    direction: 'in',
    gross: 50000000,
    amount: 50000000,
    settlementCoaId: COA.bank,
    categoryCoaId: COA.directorLoan,
  });

  assert.deepEqual(asPostings(lines), [
    { coaId: COA.bank, debit: 50000000, credit: 0 },
    { coaId: COA.directorLoan, debit: 0, credit: 50000000 },
  ]);
});

test('7. a monthly salary with nothing withheld', () => {
  const lines = buildJournalLines({
    direction: 'out',
    gross: 9000000,
    amount: 9000000,
    settlementCoaId: COA.bank,
    categoryCoaId: COA.salaries,
  });

  assert.deepEqual(asPostings(lines), [
    { coaId: COA.salaries, debit: 9000000, credit: 0 },
    { coaId: COA.bank, debit: 0, credit: 9000000 },
  ]);
});

test('paying a vendor with Section 153 withheld', () => {
  // Not in the chart document yet. TAXES.md requires it in Phase 1: the cost
  // is 100,000, 4,000 is held back for FBR, 96,000 reaches the vendor.
  const lines = buildJournalLines({
    direction: 'out',
    gross: 10000000,
    amount: 9600000,
    settlementCoaId: COA.bank,
    categoryCoaId: COA.outsourcing,
    taxes: [{ coaId: COA.withholdingPayable, amount: 400000, deductedBy: 'us' }],
  });

  assert.deepEqual(asPostings(lines), [
    { coaId: COA.outsourcing, debit: 10000000, credit: 0 },
    { coaId: COA.withholdingPayable, debit: 0, credit: 400000 },
    { coaId: COA.bank, debit: 0, credit: 9600000 },
  ]);
});

test('a reversal is exactly opposite, line for line', () => {
  const original = buildJournalLines({
    direction: 'out',
    gross: 560000,
    amount: 595300,
    settlementCoaId: COA.bank,
    categoryCoaId: COA.subscriptions,
    taxes: [{ coaId: COA.advanceTax, amount: 2800, deductedBy: 'bank' }],
    charges: [
      { coaId: COA.forexFees, amount: 28000 },
      { coaId: COA.bankCharges, amount: 4500 },
    ],
  });

  const reversal = reverseJournalLines(original);

  // Every account nets to zero across the two entries.
  const net = new Map();
  for (const line of [...original, ...reversal]) {
    net.set(line.coaId, (net.get(line.coaId) ?? 0) + line.debit - line.credit);
  }
  for (const [coaId, balance] of net) {
    assert.equal(balance, 0, `${coaId} did not net to zero`);
  }
});

test('an entry that does not reconcile is refused before any line is built', () => {
  assert.throws(
    () => buildJournalLines({
      direction: 'out',
      gross: 560000,
      amount: 500000,
      settlementCoaId: COA.bank,
      categoryCoaId: COA.subscriptions,
      charges: [{ coaId: COA.forexFees, amount: 28000 }],
    }),
    /does not reconcile/,
  );
});

test('the engine refuses what the schema also refuses', () => {
  const base = {
    direction: 'in',
    gross: 10000000,
    amount: 9600000,
    settlementCoaId: COA.bank,
    categoryCoaId: COA.exportRevenue,
  };

  assert.throws(
    () => buildJournalLines({ ...base, taxes: [{ coaId: COA.withholdingPayable, amount: 400000, deductedBy: 'us' }] }),
    /only withholds tax from someone it is paying/,
  );
  assert.throws(
    () => buildJournalLines({ ...base, direction: 'sideways' }),
    MoneyError,
  );
  assert.throws(
    () => buildJournalLines({ ...base, isRebillable: true }),
    /only money out can be rebillable/,
  );
  assert.throws(
    () => buildJournalLines({
      direction: 'out', gross: 100, amount: 100,
      settlementCoaId: COA.bank, categoryCoaId: COA.absorbedAds,
      isRebillable: true,
    }),
    /needs ledger account 1123/,
  );
  assert.throws(
    () => buildJournalLines({
      direction: 'out', gross: 100, amount: 100,
      settlementCoaId: null, categoryCoaId: COA.absorbedAds,
    }),
    /no ledger account/,
  );
});

test('a manual journal entry must balance', () => {
  // The opening entry, in miniature: bank, cash and the director loan at
  // 30 June, with 3400 taking the balancing figure.
  const lines = buildManualLines([
    { coaId: COA.bank, debit: 50000000 },
    { coaId: COA.directorLoan, credit: 50000000 },
  ]);
  assert.equal(lines.length, 2);
  assert.equal(lines[1].lineNo, 2);

  assert.throws(
    () => buildManualLines([
      { coaId: COA.bank, debit: 50000000 },
      { coaId: COA.directorLoan, credit: 49999999 },
    ]),
    /do not equal/,
  );
});

test('line numbers are sequential and start at one', () => {
  const lines = buildJournalLines({
    direction: 'out',
    gross: 560000,
    amount: 595300,
    settlementCoaId: COA.bank,
    categoryCoaId: COA.subscriptions,
    taxes: [{ coaId: COA.advanceTax, amount: 2800, deductedBy: 'bank' }],
    charges: [
      { coaId: COA.forexFees, amount: 28000 },
      { coaId: COA.bankCharges, amount: 4500 },
    ],
  });
  assert.deepEqual(lines.map((line) => line.lineNo), [1, 2, 3, 4, 5]);
});
