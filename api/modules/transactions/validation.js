// Validation in three tiers, from docs/UI-GUIDE.md.
//
//   Blocked   cannot be saved at all
//   Warned    saved once the user confirms, and the confirmation is recorded
//   Flagged   saved silently, and appears in the review list
//
// The database already refuses the structural mistakes: unbalanced lines, a
// zero amount, a posted row being edited. Those need no lookup. What is here
// is everything that needs to ask the database a question first.
//
// The rule that makes a warning worth having: it must name the record it
// matched against. "Possible duplicate" on its own gets dismissed by reflex.
// "Same amount as JV-0042 on 3 July, Office rent" gets investigated.

import { divideRounded } from '../../core/money.js';
import { businessToday } from '../../core/dates.js';

export const Blocked = Object.freeze({
  INACTIVE_ACCOUNT: 'INACTIVE_ACCOUNT',
  INACTIVE_CATEGORY: 'INACTIVE_CATEGORY',
  FUTURE_DATE: 'FUTURE_DATE',
  BEFORE_OPENING_DATE: 'BEFORE_OPENING_DATE',
  HISTORICAL_AFTER_GO_LIVE: 'HISTORICAL_AFTER_GO_LIVE',
  OPENING_WRONG_DATE: 'OPENING_WRONG_DATE',
  OPENING_ALREADY_EXISTS: 'OPENING_ALREADY_EXISTS',
  LIVE_BEFORE_GO_LIVE: 'LIVE_BEFORE_GO_LIVE',
  CASH_BELOW_ZERO: 'CASH_BELOW_ZERO',
  TAX_UNKNOWN: 'TAX_UNKNOWN',
  TAX_INACTIVE: 'TAX_INACTIVE',
  TAX_NOT_IN_EFFECT: 'TAX_NOT_IN_EFFECT',
  TAX_WRONG_DIRECTION: 'TAX_WRONG_DIRECTION',
  TAX_LARGER_THAN_BASE: 'TAX_LARGER_THAN_BASE',
  RATE_AMOUNT_MISMATCH: 'RATE_AMOUNT_MISMATCH',
});

// How far the rupees may be from foreign amount × rate before the entry is
// refused: one rupee, for the rounding a bank does. Anything further is
// almost always a typo in one of the two. Decision 059, defect F2.
const RATE_TOLERANCE_PAISA = 100n;

export const Warning = Object.freeze({
  POSSIBLE_DUPLICATE: 'POSSIBLE_DUPLICATE',
  REPEATED_DESCRIPTION: 'REPEATED_DESCRIPTION',
  UNUSUAL_AMOUNT: 'UNUSUAL_AMOUNT',
  BACKDATED: 'BACKDATED',
  BANK_BELOW_ZERO: 'BANK_BELOW_ZERO',
  LARGE_CASH: 'LARGE_CASH',
  RATE_DEVIATION: 'RATE_DEVIATION',
});

export const Flag = Object.freeze({
  THIN_DESCRIPTION: 'THIN_DESCRIPTION',
  NO_RECEIPT: 'NO_RECEIPT',
});

// Every warning code. A test that is not about validation acknowledges all of
// them, which is what the client does once the user has confirmed.
export const WARNING_CODES = Object.values(Warning);

const DAY = 24 * 60 * 60 * 1000;

function daysBetween(a, b) {
  return Math.trunc((new Date(a).getTime() - new Date(b).getTime()) / DAY);
}

function asDate(value) {
  return typeof value === 'string' ? value.slice(0, 10) : new Date(value).toISOString().slice(0, 10);
}

// Today in Pakistan, not in UTC. Between midnight and 05:00 the two differ,
// and the UTC date refused the office's own today as a future date. D9.
function today() {
  return businessToday();
}

// --- blocked ---------------------------------------------------------------

export async function collectBlocking(repo, connection, { input, amount, settings, excludeId = null }) {
  const problems = [];
  const date = asDate(input.date);

  if (date > today()) {
    problems.push({
      code: Blocked.FUTURE_DATE,
      message: 'An entry cannot be dated in the future.',
    });
  }

  const category = await repo.categoryCoaId(connection, input.categoryId);
  if (category && !category.is_active) {
    problems.push({
      code: Blocked.INACTIVE_CATEGORY,
      message: 'That category is no longer in use.',
    });
  }

  if (input.accountId) {
    const account = await repo.accountCoaId(connection, input.accountId);
    if (account && !account.is_active) {
      problems.push({
        code: Blocked.INACTIVE_ACCOUNT,
        message: 'That account is no longer in use.',
      });
    }
    if (account && date < asDate(account.opening_date)) {
      problems.push({
        code: Blocked.BEFORE_OPENING_DATE,
        message: `That account has no entries before ${asDate(account.opening_date)}.`,
      });
    }
  }

  // History is, by definition, before the books went live. The opening entry
  // is the single entry dated on the day they did. Decision 037, and the split
  // rule in UI-GUIDE corrected by decision 051.
  const liveFrom = settings.booksLiveFrom;
  const entryType = input.entryType ?? 'normal';

  if (entryType === 'historical' && date >= liveFrom) {
    problems.push({
      code: Blocked.HISTORICAL_AFTER_GO_LIVE,
      message: `A historical entry must be dated before ${liveFrom}.`,
    });
  }
  if (entryType === 'normal' && date < liveFrom) {
    problems.push({
      code: Blocked.LIVE_BEFORE_GO_LIVE,
      message: `An entry dated before ${liveFrom} is historical, not a live entry.`,
    });
  }
  if (entryType === 'opening') {
    if (date !== liveFrom) {
      problems.push({
        code: Blocked.OPENING_WRONG_DATE,
        message: `The opening entry is dated ${liveFrom} and nothing else.`,
      });
    }
    if (await repo.openingEntryExists(connection, excludeId)) {
      problems.push({
        code: Blocked.OPENING_ALREADY_EXISTS,
        message: 'There is already an opening entry.',
      });
    }
  }

  problems.push(...(await checkTaxLines(repo, connection, { input, date })));

  const mismatch = checkRateAgainstRupees(input);
  if (mismatch) problems.push(mismatch);

  // You cannot spend cash you do not have. A bank account can go overdrawn in
  // real life, so that one is a warning rather than a block.
  if (input.direction === 'out' && input.accountId) {
    const account = await repo.accountCoaId(connection, input.accountId);
    if (account && (account.type === 'cash' || account.type === 'petty_cash')) {
      const balance = await repo.ledgerBalance(connection, account.coa_id, {
        historyMerged: settings.historyMerged,
        excludeId,
      });
      if (balance - amount < 0) {
        problems.push({
          code: Blocked.CASH_BELOW_ZERO,
          message: `That leaves ${account.type === 'cash' ? 'office cash' : 'petty cash'} below zero. It holds ${formatPkr(balance)} today.`,
        });
      }
    }
  }

  return problems;
}

// Every tax line is checked against the tax it names. UI-GUIDE lists these as
// blocking; before this nothing checked them, so a sales tax could sit on a
// software subscription, or last year's rate on this year's entry. F5.
async function checkTaxLines(repo, connection, { input, date }) {
  const lines = input.taxes ?? [];
  if (lines.length === 0) return [];

  const problems = [];
  const taxes = await repo.taxesForValidation(
    connection,
    [...new Set(lines.map((line) => Number(line.taxId)))],
  );
  const direction = input.direction === 'in' ? 'in' : 'out';

  for (const line of lines) {
    const tax = taxes.get(Number(line.taxId));
    if (!tax) {
      problems.push({ code: Blocked.TAX_UNKNOWN, message: 'One of the tax lines names a tax that does not exist.' });
      continue;
    }
    const label = `${tax.name} (${tax.short_code})`;

    if (!tax.is_active) {
      problems.push({ code: Blocked.TAX_INACTIVE, message: `${label} is switched off, so it cannot be used.` });
    }

    const from = asDate(tax.effective_from);
    const to = tax.effective_to ? asDate(tax.effective_to) : null;
    if (date < from || (to && date > to)) {
      const range = to ? `from ${from} to ${to}` : `from ${from}`;
      problems.push({
        code: Blocked.TAX_NOT_IN_EFFECT,
        message: `${label} was not in force on ${date}. It applies ${range}.`,
      });
    }

    const wrongWay = (tax.applies_to === 'sales' && direction === 'out')
      || (tax.applies_to === 'purchases' && direction === 'in');
    if (wrongWay) {
      const belongs = tax.applies_to === 'sales' ? 'money coming in' : 'money going out';
      const entry = direction === 'in' ? 'money coming in' : 'money going out';
      problems.push({
        code: Blocked.TAX_WRONG_DIRECTION,
        message: `${label} is for ${belongs}, and this entry is ${entry}.`,
      });
    }

    if (Number(line.amount) > Number(line.baseAmount)) {
      problems.push({
        code: Blocked.TAX_LARGER_THAN_BASE,
        message: `${label} is ${formatPaisa(line.amount)} on a base of ${formatPaisa(line.baseAmount)}. A tax cannot be more than the amount it is charged on.`,
      });
    }
  }
  return problems;
}

// The rupees and the rate must tell the same story: 500 USD at 280 is
// PKR 140,000.00, so an entry saying 140,250.00 has a typo in one of them.
// Both minor units are hundredths, so foreign minor × rate is paisa. F2.
function checkRateAgainstRupees(input) {
  if (!input.foreignAmount || !input.fxRate) return null;
  const rate = rateInMillionths(input.fxRate);
  if (rate === null) return null;

  const expected = divideRounded(BigInt(input.foreignAmount) * rate, 1000000n);
  const gross = BigInt(input.grossAmount);
  const difference = gross > expected ? gross - expected : expected - gross;
  if (difference <= RATE_TOLERANCE_PAISA) return null;

  const foreign = `${input.currency} ${formatMinor(BigInt(input.foreignAmount))}`;
  return {
    code: Blocked.RATE_AMOUNT_MISMATCH,
    message: `${foreign} at ${Number(input.fxRate)} is ${formatPaisa(expected)}, not ${formatPaisa(gross)}. Correct the rate or the rupees.`,
  };
}

// --- warned ----------------------------------------------------------------

export async function collectWarnings(repo, connection, { input, amount, settings, excludeId = null }) {
  const warnings = [];
  const date = asDate(input.date);

  // The two legs of one transfer are the same movement seen from each side.
  // Matching one against the other would warn the person about their own
  // transfer, so legs of the same group are never compared. D6.
  const transferGroupId = input.transferGroupId ?? null;

  const duplicate = await repo.findSameAmountNearby(connection, {
    accountId: input.accountId,
    amount,
    date,
    days: 3,
    excludeId,
    transferGroupId,
  });
  if (duplicate) {
    warnings.push({
      code: Warning.POSSIBLE_DUPLICATE,
      message: `Same amount on the same account as ${describe(duplicate)}.`,
      detail: describe(duplicate),
      transactionId: Number(duplicate.id),
    });
  }

  const repeated = await repo.findSameDescription(connection, {
    description: input.description,
    amount,
    date,
    days: 30,
    excludeId,
    transferGroupId,
  });
  if (repeated) {
    warnings.push({
      code: Warning.REPEATED_DESCRIPTION,
      message: `Same description and amount as ${describe(repeated)}.`,
      detail: describe(repeated),
      transactionId: Number(repeated.id),
    });
  }

  const usual = await repo.categoryAverage(connection, {
    categoryId: input.categoryId,
    months: 6,
    excludeId,
    today: today(),
  });
  if (usual && usual.count >= 3 && amount > usual.average * 3) {
    warnings.push({
      code: Warning.UNUSUAL_AMOUNT,
      message: `More than three times the usual for this category, which averages ${formatPkr(usual.average)} over ${usual.count} entries.`,
      detail: `average ${formatPkr(usual.average)} from ${usual.count} entries`,
    });
  }

  // Historical entries are old by definition, so backdating is not a surprise.
  if ((input.entryType ?? 'normal') === 'normal' && daysBetween(today(), date) > 90) {
    warnings.push({
      code: Warning.BACKDATED,
      message: `That is ${daysBetween(today(), date)} days ago.`,
    });
  }

  if (input.direction === 'out' && input.accountId) {
    const account = await repo.accountCoaId(connection, input.accountId);

    if (account?.type === 'bank') {
      const balance = await repo.ledgerBalance(connection, account.coa_id, {
        historyMerged: settings.historyMerged,
        excludeId,
      });
      if (balance - amount < 0) {
        warnings.push({
          code: Warning.BANK_BELOW_ZERO,
          message: `That takes the account below zero. It holds ${formatPkr(balance)} today.`,
        });
      }
    }

    if ((account?.type === 'cash' || account?.type === 'petty_cash')
        && amount >= settings.largeCashWarningAbove) {
      warnings.push({
        code: Warning.LARGE_CASH,
        message: `Cash payments at or above ${formatPkr(settings.largeCashWarningAbove)} are unusual.`,
      });
    }
  }

  // The rate the bank gave last time is the only reference the books have.
  if (input.fxRate && input.currency && input.currency !== 'PKR') {
    const last = await repo.lastRateFor(connection, input.currency, excludeId);
    if (last) {
      const deviation = percentApart(input.fxRate, last.fx_rate);
      if (deviation !== null && deviation > settings.fxDeviationWarningPercent) {
        warnings.push({
          code: Warning.RATE_DEVIATION,
          message: `That rate is ${deviation}% away from ${Number(last.fx_rate)}, used on ${asDate(last.date)}.`,
          detail: `last rate ${Number(last.fx_rate)} on ${asDate(last.date)}`,
          transactionId: Number(last.id),
        });
      }
    }
  }

  return warnings;
}

// --- flagged ---------------------------------------------------------------

// `receiptMissing` is decided by the caller: true only when the entry is the
// kind that should carry a receipt (attachments/service.js, receiptExpected)
// and none is attached yet. It used to be "no receipt yet" alone, which
// flagged money in, transfers and the opening entry too. Defect D1.
export function collectFlags({ input, receiptMissing = false }) {
  const flags = [];

  if ((input.description ?? '').trim().length < 5) {
    flags.push({
      code: Flag.THIN_DESCRIPTION,
      message: 'The description is too short to tell what this was.',
    });
  }

  if (receiptMissing) {
    flags.push({
      code: Flag.NO_RECEIPT,
      message: 'No receipt attached.',
    });
  }

  return flags;
}

// --- helpers ---------------------------------------------------------------

function describe(row) {
  const number = row.journal_number ? `${row.journal_number}, ` : '';
  return `${number}${asDate(row.date)}, ${row.description}`;
}

// A rate as a whole number of millionths, read from its digits so it never
// passes through a float. "280.5" becomes 280500000. The database holds
// rates as DECIMAL(18,6), so six places is all there ever is.
function rateInMillionths(value) {
  const match = /^(\d+)(?:\.(\d+))?$/.exec(String(value ?? '').trim());
  if (!match) return null;
  const fraction = (match[2] ?? '').slice(0, 6).padEnd(6, '0');
  return BigInt(match[1]) * 1000000n + BigInt(fraction);
}

// How far one rate is from another, as a percentage of the earlier one with
// two decimals, rounded half away from zero. 300 against 280.5 is 6.95.
//
// The first version divided by 100 once too often and answered 0.07 for that
// pair, so the warning could only fire past a 500% jump. D5.
export function percentApart(current, previous) {
  const now = rateInMillionths(current);
  const before = rateInMillionths(previous);
  if (now === null || before === null || before === 0n) return null;

  const difference = now > before ? now - before : before - now;
  const hundredthsOfAPercent = divideRounded(difference * 10000n, before);
  return Number(hundredthsOfAPercent) / 100;
}

// Whole units and hundredths, with thousands separators: 14000000 is
// "140,000.00". Built from the integer, never through a float.
function formatMinor(minor) {
  const negative = minor < 0n;
  const value = negative ? -minor : minor;
  const units = value / 100n;
  const hundredths = (value % 100n).toString().padStart(2, '0');
  const grouped = units.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
  return `${negative ? '-' : ''}${grouped}.${hundredths}`;
}

function formatPaisa(minor) {
  return `PKR ${formatMinor(BigInt(minor))}`;
}

// An average can carry a fraction of a paisa, and BigInt refuses a fraction
// outright, which turned the unusual-amount warning into a 500. The fraction is
// dropped before rounding to whole rupees: it cannot change the rupee figure
// by more than one paisa. D14.
function formatPkr(minor) {
  const whole = BigInt(Math.trunc(Number(minor)));
  const rupees = divideRounded(whole, 100n);
  return `PKR ${Number(rupees).toLocaleString('en-PK')}`;
}
