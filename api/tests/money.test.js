// Money arithmetic. No database, so these run in milliseconds and are the
// first thing to look at when a figure comes out wrong.

import test from 'node:test';
import assert from 'node:assert/strict';

import {
  MoneyError, money, parseMoney, assertMinor, addMinor, subtractMinor,
  divideRounded, decimalToScaled, scaledToDecimal,
  pkrFromForeign, rateFromPkr, percentOf,
  reconcileAmount, assertReconciled, assertBalanced,
} from '../core/money.js';

test('minor units must be whole numbers', () => {
  assert.equal(assertMinor(595300), 595300);
  assert.equal(assertMinor(0), 0);
  assert.equal(assertMinor(-100), -100);
  assert.throws(() => assertMinor(5953.5), MoneyError);
  assert.throws(() => assertMinor('5953.5'), MoneyError);
  assert.throws(() => assertMinor(null), MoneyError);
  assert.throws(() => assertMinor(undefined), MoneyError);
  assert.throws(() => assertMinor(Number.NaN), MoneyError);
});

test('a BIGINT arriving as text is accepted, and one too large is refused', () => {
  assert.equal(assertMinor('9007199254740991'), 9007199254740991);
  assert.throws(() => assertMinor('9007199254740993'), /exactly/);
});

test('money carries a three letter currency', () => {
  assert.deepEqual(money(595300), { minor: 595300, currency: 'PKR' });
  assert.deepEqual(money(2000, 'USD'), { minor: 2000, currency: 'USD' });
  assert.throws(() => money(100, 'rupees'), MoneyError);
});

test('parseMoney refuses a float in a money field', () => {
  assert.deepEqual(parseMoney({ minor: 595300, currency: 'PKR' }), { minor: 595300, currency: 'PKR' });
  assert.throws(() => parseMoney({ minor: 5953.5, currency: 'PKR' }), MoneyError);
  assert.throws(() => parseMoney(595300), MoneyError);
});

test('adding and subtracting stay exact', () => {
  assert.equal(addMinor(560000, 2800, 32500), 595300);
  assert.equal(subtractMinor(560000, 2800, 32500), 524700);
  // The float version of this is 0.30000000000000004.
  assert.equal(addMinor(10, 20), 30);
});

test('rounding is half away from zero', () => {
  assert.equal(divideRounded(5n, 2n), 3n);
  assert.equal(divideRounded(-5n, 2n), -3n);
  assert.equal(divideRounded(4n, 2n), 2n);
  assert.equal(divideRounded(1n, 3n), 0n);
  assert.equal(divideRounded(2n, 3n), 1n);
  assert.throws(() => divideRounded(1n, 0n), MoneyError);
});

test('decimal strings from the database become scaled integers', () => {
  assert.equal(decimalToScaled('280.000000', 6n), 280000000n);
  assert.equal(decimalToScaled('280', 6n), 280000000n);
  assert.equal(decimalToScaled('0.25', 4n), 2500n);
  assert.equal(decimalToScaled('-1.5', 4n), -15000n);
  assert.throws(() => decimalToScaled('0.1234567', 6n), /decimal places/);
  assert.throws(() => decimalToScaled('two eighty', 6n), MoneyError);
  assert.equal(scaledToDecimal(280000000n, 6n), '280.000000');
});

test('the Claude subscription from the chart of accounts', () => {
  // $20.00 at 280. Worked example 1a.
  const gross = pkrFromForeign(2000, '280.000000');
  assert.equal(gross, 560000, 'PKR 5,600');

  // Section 236Y at 0.5% on a company card.
  const tax = percentOf(gross, '0.5');
  assert.equal(tax, 2800, 'PKR 28.00');

  const charges = addMinor(28000, 4500);
  assert.equal(reconcileAmount({ direction: 'out', gross, tax, charges }), 595300);
});

test('the foreign client payment from the chart of accounts', () => {
  // $500.00 at 278, Section 154A at 0.25%. Worked example 2.
  const gross = pkrFromForeign(50000, '278');
  assert.equal(gross, 13900000, 'PKR 139,000');

  const tax = percentOf(gross, '0.25');
  assert.equal(tax, 34750, 'PKR 347.50');

  assert.equal(reconcileAmount({ direction: 'in', gross, tax }), 13865250, 'PKR 138,652.50');
});

test('a rate the user did not type is derived from the PKR actually received', () => {
  assert.equal(rateFromPkr(2000, 560000), '280.000000');
  assert.equal(rateFromPkr(50000, 13900000), '278.000000');
  // And it round trips.
  assert.equal(pkrFromForeign(2000, rateFromPkr(2000, 560000)), 560000);
});

test('conversion refuses a rate of zero or below', () => {
  assert.throws(() => pkrFromForeign(2000, '0'), /above zero/);
  assert.throws(() => pkrFromForeign(2000, '-280'), /above zero/);
  assert.throws(() => rateFromPkr(0, 560000), /above zero/);
});

test('a large figure stays exact where a float would not', () => {
  // PKR 90,071,992,547,409.91 in paisa, one below the safe integer limit.
  assert.equal(addMinor(9007199254740990, 1), 9007199254740991);
  assert.throws(() => addMinor(9007199254740991, 1), /exactly/);
});

test('reconciliation matches the rule the database enforces', () => {
  assert.equal(assertReconciled({ direction: 'out', amount: 595300, gross: 560000, tax: 2800, charges: 32500 }), 595300);
  assert.equal(assertReconciled({ direction: 'in', amount: 524700, gross: 560000, tax: 2800, charges: 32500 }), 524700);

  assert.throws(
    () => assertReconciled({ direction: 'in', amount: 595300, gross: 560000, tax: 2800, charges: 32500 }),
    /does not reconcile/,
  );
  assert.throws(() => reconcileAmount({ direction: 'sideways', gross: 1 }), MoneyError);
});

test('a journal entry must balance', () => {
  const lines = [
    { coaId: 1, debit: 560000, credit: 0 },
    { coaId: 2, debit: 32500, credit: 0 },
    { coaId: 3, debit: 2800, credit: 0 },
    { coaId: 4, debit: 0, credit: 595300 },
  ];
  assert.equal(assertBalanced(lines), 595300);

  assert.throws(() => assertBalanced([...lines.slice(0, 3), { coaId: 4, debit: 0, credit: 595299 }]), /do not equal/);
  assert.throws(() => assertBalanced([]), /must have journal lines/);
  assert.throws(() => assertBalanced([{ debit: 100, credit: 100 }]), /not both/);
  assert.throws(() => assertBalanced([{ debit: 0, credit: 0 }]), /zero on both sides/);
  assert.throws(() => assertBalanced([{ debit: -100, credit: 0 }]), /negative/);
});

test('the Upwork split from the chart of accounts', () => {
  // Worked example 5. Gross PKR 120,000, fee 10%, Jake takes half the rest.
  const gross = 12000000;
  const platformFee = percentOf(gross, '10');
  assert.equal(platformFee, 1200000, 'PKR 12,000');

  const afterFee = subtractMinor(gross, platformFee);
  const partnerShare = percentOf(afterFee, '50');
  assert.equal(partnerShare, 5400000, 'PKR 54,000');

  const net = subtractMinor(afterFee, partnerShare);
  assert.equal(net, 5400000, 'PKR 54,000 reaches Winibex');

  assert.equal(assertBalanced([
    { debit: net, credit: 0 },
    { debit: platformFee, credit: 0 },
    { debit: partnerShare, credit: 0 },
    { debit: 0, credit: gross },
  ]), gross);
});

test('a half paisa rounds away from zero, consistently in both directions', () => {
  // 1% of 150 paisa is 1.5 paisa.
  assert.equal(percentOf(150, '1'), 2);
  assert.equal(percentOf(-150, '1'), -2);
});

test('tax Winibex withholds reduces the payment rather than adding to it', () => {
  // Paying a vendor PKR 100,000 with Section 153 at 4%. 96,000 reaches them,
  // 4,000 is owed to FBR.
  const gross = 10000000;
  const withheld = percentOf(gross, '4');
  assert.equal(withheld, 400000, 'PKR 4,000');

  assert.equal(reconcileAmount({ direction: 'out', gross, withheld }), 9600000, 'PKR 96,000');
  assert.equal(
    assertReconciled({ direction: 'out', amount: 9600000, gross, withheld }),
    9600000,
  );

  assert.throws(
    () => assertReconciled({ direction: 'out', amount: 10400000, gross, withheld }),
    /does not reconcile/,
  );
});

test('a payment can both suffer tax and withhold it', () => {
  // Contrived, but the arithmetic must hold: cost 100,000, 325 of bank charges
  // added, 4,000 withheld from the payee.
  assert.equal(
    reconcileAmount({ direction: 'out', gross: 10000000, charges: 32500, withheld: 400000 }),
    9632500,
  );
});

test('Winibex cannot withhold tax on money it receives', () => {
  assert.throws(
    () => reconcileAmount({ direction: 'in', gross: 10000000, withheld: 400000 }),
    /only withholds tax from someone it is paying/,
  );
});
