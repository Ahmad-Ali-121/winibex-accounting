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
});

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

function today() {
  return new Date().toISOString().slice(0, 10);
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

// --- warned ----------------------------------------------------------------

export async function collectWarnings(repo, connection, { input, amount, settings, excludeId = null }) {
  const warnings = [];
  const date = asDate(input.date);

  const duplicate = await repo.findSameAmountNearby(connection, {
    accountId: input.accountId,
    amount,
    date,
    days: 3,
    excludeId,
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
      const deviation = percentApart(Number(input.fxRate), Number(last.fx_rate));
      if (deviation > settings.fxDeviationWarningPercent) {
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

export function collectFlags({ input, hasReceipt }) {
  const flags = [];

  if ((input.description ?? '').trim().length < 5) {
    flags.push({
      code: Flag.THIN_DESCRIPTION,
      message: 'The description is too short to tell what this was.',
    });
  }

  if (!hasReceipt) {
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

function percentApart(a, b) {
  if (b === 0) return 100;
  const difference = Math.abs(a - b) * 10000;
  return Number(divideRounded(BigInt(Math.trunc(difference)), BigInt(Math.trunc(b * 100)))) / 100;
}

function formatPkr(minor) {
  const rupees = divideRounded(BigInt(minor), 100n);
  return `PKR ${Number(rupees).toLocaleString('en-PK')}`;
}
