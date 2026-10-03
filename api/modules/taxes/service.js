// The tax engine.
//
// Taxes are rows with effective dates, never constants in code, because
// Pakistan rates change every budget. Decision 018. This decides what the
// entry form suggests; the user confirms it, and what the bank actually
// deducted wins over any suggestion. docs/TAXES.md, principle 4.
//
// The part worth understanding is whose ATL status picks the rate.
//
//   A bank or a client deducting from Winibex    Winibex's status applies
//   Winibex deducting from a vendor or employee  the payee's status applies
//
// Every tax carries both rates. Reading Winibex's status for all of them, as
// the external review proposed, would quietly give a non-filer vendor the
// filer rate and leave Winibex owing FBR the difference. Decision 030.

import { getPool } from '../../core/db.js';
import { notFound } from '../../core/errors.js';
import { money, percentOf } from '../../core/money.js';
import * as repo from './repository.js';

const BASE_CURRENCY = 'PKR';

function present(tax) {
  return {
    id: Number(tax.id),
    name: tax.name,
    shortCode: tax.short_code,
    authority: tax.authority,
    lawReference: tax.law_reference,
    kind: tax.kind,
    rateAtl: String(tax.rate_atl),
    rateNonAtl: String(tax.rate_non_atl),
    statusBasis: tax.status_basis,
    isAdjustable: Boolean(tax.is_adjustable),
    coaId: Number(tax.coa_id),
    effectiveFrom: tax.effective_from,
    effectiveTo: tax.effective_to,
    notes: tax.notes,
  };
}

export async function listTaxes({ date = today() } = {}) {
  const rows = await repo.listInEffect(getPool(), date);
  return { taxes: rows.map(present), asAt: date };
}

export async function getTax(id) {
  const tax = await repo.findById(getPool(), id);
  if (!tax) throw notFound('That tax does not exist.');
  return present(tax);
}

// Which party's status decides this tax's rate, and what that status is.
async function resolveStatus(runner, tax, { direction, vendorId }) {
  if (tax.status_basis === 'company') {
    return {
      party: 'company',
      status: await repo.companyAtlStatus(runner),
      warning: null,
    };
  }

  // Winibex is doing the deducting, so the payee's status decides.
  const party = direction === 'out' ? 'vendor' : 'client';
  const vendor = await repo.vendorAtlStatus(runner, vendorId);

  if (!vendor || vendor.atl_status === 'unknown') {
    // An unknown payee gets the non-filer rate, which is the higher one, plus
    // a warning. Guessing low leaves Winibex owing FBR the difference.
    return {
      party,
      status: 'non_atl',
      warning: vendor
        ? `${vendor.name} has no confirmed filer status, so the non-filer rate is used.`
        : 'No payee recorded, so the non-filer rate is used.',
    };
  }

  return {
    party,
    status: vendor.atl_status,
    warning: staleCheck(vendor)
      ? `${vendor.name}'s filer status was last checked on ${String(vendor.atl_checked_on).slice(0, 10)}.`
      : null,
  };
}

function staleCheck(vendor) {
  if (!vendor.atl_checked_on) return true;
  const days = (Date.now() - new Date(vendor.atl_checked_on).getTime()) / (24 * 60 * 60 * 1000);
  return days > 30;
}

// Tax Winibex withholds is held back from the payment. Tax anyone else deducts
// is taken from Winibex. The posting engine reads this to decide whether the
// line is a debit or a credit, so it is not cosmetic.
function deductedBy(tax, { direction, currencyIsForeign }) {
  if (tax.status_basis === 'counterparty') return 'us';
  if (direction === 'in') return currencyIsForeign ? 'bank' : 'customer';
  return 'bank';
}

/**
 * What the form should suggest for a situation. The user may edit, remove or
 * add lines afterwards, and the figure the bank actually took wins.
 */
export async function suggestFor({
  date = today(),
  direction,
  baseAmount,
  currency = BASE_CURRENCY,
  accountType = null,
  categoryId = null,
  clientCountry = null,
  vendorId = null,
}) {
  const pool = getPool();
  const currencyIsForeign = currency !== BASE_CURRENCY;

  const rules = await repo.matchingRules(pool, {
    date, direction, currencyIsForeign, accountType, categoryId, clientCountry,
  });

  const suggestions = [];
  const seen = new Set();

  for (const rule of rules) {
    // Two rules can point at the same tax. Suggesting it twice would double it.
    if (seen.has(Number(rule.tax_id))) continue;
    seen.add(Number(rule.tax_id));

    const { party, status, warning } = await resolveStatus(pool, rule, { direction, vendorId });
    const rate = status === 'atl' ? rule.rate_atl : rule.rate_non_atl;
    const amount = rule.computation === 'percent'
      ? percentOf(baseAmount, String(rate))
      : Number(rate);

    suggestions.push({
      taxId: Number(rule.tax_id),
      name: rule.name,
      shortCode: rule.short_code,
      lawReference: rule.law_reference,
      kind: rule.kind,
      coaId: Number(rule.coa_id),
      baseAmount: money(baseAmount, BASE_CURRENCY),
      rateApplied: String(rate),
      atlStatusUsed: status,
      atlParty: party,
      amount: money(amount, BASE_CURRENCY),
      deductedBy: deductedBy(rule, { direction, currencyIsForeign }),
      isAdjustable: Boolean(rule.is_adjustable),
      warning,
    });
  }

  return { date, suggestions };
}

function today() {
  return new Date().toISOString().slice(0, 10);
}
