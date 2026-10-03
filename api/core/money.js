// Money.
//
// Every amount in this system is a whole number of minor units: paisa for PKR,
// cents for USD. Never a decimal, never a float. 0.1 + 0.2 is not 0.3 in
// JavaScript, and a books of account that drifts by a paisa a day is not a
// books of account. ESLint blocks Math.round and parseFloat for this reason,
// so nothing here uses them.
//
// Arithmetic that could overflow runs in BigInt and comes back as a safe
// integer. Exchange rates and tax rates arrive from the database as decimal
// strings and are turned into scaled integers rather than parsed as numbers.
//
// Rates: DECIMAL(18,6), six decimal places. Tax rates: DECIMAL(9,4), four.

const RATE_SCALE = 6n;
const PERCENT_SCALE = 4n;
const PERCENT_DIVISOR = 100n;

const DECIMAL_PATTERN = /^-?\d+(\.\d+)?$/;
const CURRENCY_PATTERN = /^[A-Z]{3}$/;

export class MoneyError extends Error {
  constructor(message) {
    super(message);
    this.name = 'MoneyError';
  }
}

// --- minor units ------------------------------------------------------------

export function assertMinor(value, label = 'amount') {
  if (typeof value === 'bigint') {
    if (value > BigInt(Number.MAX_SAFE_INTEGER) || value < -BigInt(Number.MAX_SAFE_INTEGER)) {
      throw new MoneyError(`${label} is outside the range JavaScript can hold exactly`);
    }
    return Number(value);
  }
  if (typeof value === 'string' && /^-?\d+$/.test(value)) {
    return assertMinor(BigInt(value), label);
  }
  if (typeof value !== 'number' || !Number.isInteger(value)) {
    throw new MoneyError(`${label} must be a whole number of minor units, got ${String(value)}`);
  }
  if (!Number.isSafeInteger(value)) {
    throw new MoneyError(`${label} is outside the range JavaScript can hold exactly`);
  }
  return value;
}

export function money(minor, currency = 'PKR') {
  if (!CURRENCY_PATTERN.test(currency)) {
    throw new MoneyError(`currency must be a three letter code, got ${String(currency)}`);
  }
  return { minor: assertMinor(minor), currency };
}

// The shape every money field takes in JSON, per docs/API.md.
export function parseMoney(value, label = 'amount') {
  if (value === null || typeof value !== 'object') {
    throw new MoneyError(`${label} must be an object like { minor, currency }`);
  }
  return money(assertMinor(value.minor, `${label}.minor`), value.currency);
}

export function addMinor(...values) {
  const total = values.reduce((sum, value) => sum + BigInt(assertMinor(value)), 0n);
  return assertMinor(total);
}

export function subtractMinor(from, ...values) {
  const total = values.reduce(
    (left, value) => left - BigInt(assertMinor(value)),
    BigInt(assertMinor(from)),
  );
  return assertMinor(total);
}

// --- rounding ---------------------------------------------------------------

// Half away from zero: 0.5 rounds to 1, -0.5 rounds to -1. The rule a person
// doing this by hand would use, and the one that keeps a reversal exactly
// equal and opposite to what it reverses.
export function divideRounded(numerator, denominator) {
  if (denominator === 0n) throw new MoneyError('cannot divide by zero');

  const negative = (numerator < 0n) !== (denominator < 0n);
  const absNumerator = numerator < 0n ? -numerator : numerator;
  const absDenominator = denominator < 0n ? -denominator : denominator;

  let quotient = absNumerator / absDenominator;
  const remainder = absNumerator % absDenominator;
  if (remainder * 2n >= absDenominator) quotient += 1n;

  return negative ? -quotient : quotient;
}

// --- decimals from the database --------------------------------------------

// '280.000000' becomes 280000000n at scale 6. No parseFloat anywhere near it.
export function decimalToScaled(value, scale, label = 'rate') {
  const text = typeof value === 'number' ? String(value) : value;
  if (typeof text !== 'string' || !DECIMAL_PATTERN.test(text)) {
    throw new MoneyError(`${label} must be a decimal number, got ${String(value)}`);
  }

  const negative = text.startsWith('-');
  const [whole, fraction = ''] = (negative ? text.slice(1) : text).split('.');
  if (BigInt(fraction.length) > scale) {
    throw new MoneyError(`${label} has more than ${scale} decimal places`);
  }

  const padded = fraction.padEnd(Number(scale), '0');
  const scaled = BigInt(whole + padded);
  return negative ? -scaled : scaled;
}

export function scaledToDecimal(scaled, scale) {
  const negative = scaled < 0n;
  const digits = (negative ? -scaled : scaled).toString().padStart(Number(scale) + 1, '0');
  const cut = digits.length - Number(scale);
  return `${negative ? '-' : ''}${digits.slice(0, cut)}.${digits.slice(cut)}`;
}

// --- conversion -------------------------------------------------------------

// Both currencies hold two decimal places, so cents times rate gives paisa
// directly. $20.00 at 280 is 2000 * 280 = 560000 paisa, which is PKR 5,600.
export function pkrFromForeign(foreignMinor, rate) {
  const scaledRate = decimalToScaled(rate, RATE_SCALE);
  if (scaledRate <= 0n) throw new MoneyError('rate must be above zero');

  const product = BigInt(assertMinor(foreignMinor, 'foreign amount')) * scaledRate;
  return assertMinor(divideRounded(product, 10n ** RATE_SCALE));
}

// The user may enter the PKR figure instead and the rate is derived from it.
// Decision 017. Returned as a decimal string so it stores exactly.
export function rateFromPkr(foreignMinor, pkrMinor) {
  const foreign = BigInt(assertMinor(foreignMinor, 'foreign amount'));
  if (foreign <= 0n) throw new MoneyError('foreign amount must be above zero');

  const pkr = BigInt(assertMinor(pkrMinor, 'PKR amount'));
  return scaledToDecimal(divideRounded(pkr * 10n ** RATE_SCALE, foreign), RATE_SCALE);
}

// --- tax and percentages ----------------------------------------------------

// 0.25% of PKR 139,000 is PKR 347.50, which is 34750 paisa.
export function percentOf(baseMinor, ratePercent) {
  const scaledRate = decimalToScaled(ratePercent, PERCENT_SCALE, 'rate');
  if (scaledRate < 0n) throw new MoneyError('rate cannot be negative');

  const product = BigInt(assertMinor(baseMinor, 'base amount')) * scaledRate;
  return assertMinor(divideRounded(product, 10n ** PERCENT_SCALE * PERCENT_DIVISOR));
}

// --- reconciliation ---------------------------------------------------------

// The rule the database also enforces, in SCHEMA.md under Money and currency.
//
// `tax` is tax taken FROM Winibex: the bank's s.236Y on a card payment, a
// client's s.153 on a local receipt. It is a cost on top of what is paid, or a
// deduction from what is received.
//
// `withheld` is tax Winibex deducts from a payee under s.153 or s.149. That
// money never leaves the company as payment. It is held back and owed to FBR,
// so it reduces the payment and creates a liability. Only ever on money out.
export function reconcileAmount({ direction, gross, tax = 0, charges = 0, withheld = 0 }) {
  if (direction !== 'in' && direction !== 'out') {
    throw new MoneyError(`direction must be in or out, got ${String(direction)}`);
  }
  if (direction === 'in' && assertMinor(withheld, 'withheld') !== 0) {
    throw new MoneyError('Winibex only withholds tax from someone it is paying');
  }
  return direction === 'out'
    ? subtractMinor(addMinor(gross, tax, charges), withheld)
    : subtractMinor(gross, tax, charges);
}

export function assertReconciled({ direction, amount, gross, tax = 0, charges = 0, withheld = 0 }) {
  const expected = reconcileAmount({ direction, gross, tax, charges, withheld });
  if (assertMinor(amount) !== expected) {
    throw new MoneyError(
      `amount ${amount} does not reconcile with gross ${gross}, tax ${tax}, charges ${charges} and withheld ${withheld}: expected ${expected}`,
    );
  }
  return expected;
}

// --- journal lines ----------------------------------------------------------

export function assertBalanced(lines) {
  let debits = 0n;
  let credits = 0n;

  for (const line of lines) {
    const debit = BigInt(assertMinor(line.debit ?? 0, 'debit'));
    const credit = BigInt(assertMinor(line.credit ?? 0, 'credit'));

    if (debit < 0n || credit < 0n) throw new MoneyError('a journal line cannot be negative');
    if (debit > 0n && credit > 0n) throw new MoneyError('a journal line is a debit or a credit, not both');
    if (debit === 0n && credit === 0n) throw new MoneyError('a journal line cannot be zero on both sides');

    debits += debit;
    credits += credit;
  }

  if (lines.length === 0) throw new MoneyError('an entry must have journal lines');
  if (debits !== credits) {
    throw new MoneyError(`debits ${debits} do not equal credits ${credits}`);
  }
  return assertMinor(debits);
}
