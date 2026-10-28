// Changing taxes. The owner's alone. Decision 067.
//
// A rate is never edited in place. Pakistan's rates change every budget, and
// an entry dated before the change must keep the rate that was in force then.
// So a new rate is a new row: the old one ends the day before, the new one
// starts on the given date, and the rules that suggest it are carried over.
// Posted entries snapshot the rate they used, so nothing already in the books
// moves. Decision 018.

import { withTransaction, getPool } from '../../core/db.js';
import { writeAudit, AuditAction } from '../../core/audit.js';
import { businessToday } from '../../core/dates.js';
import { AppError, ErrorCode, badRequest, forbidden, notFound } from '../../core/errors.js';
import * as repo from './repository.js';

function assertOwner(user) {
  if (user.role !== 'owner') throw forbidden('Only the owner can change taxes.');
}

// A DATE column may come back as text or as a Date at midnight UTC.
function toDay(value) {
  if (value === null || value === undefined) return null;
  if (value instanceof Date) return value.toISOString().slice(0, 10);
  return String(value).slice(0, 10);
}

function dayBefore(date) {
  const value = new Date(`${date}T00:00:00Z`);
  value.setUTCDate(value.getUTCDate() - 1);
  return value.toISOString().slice(0, 10);
}

function fitsDirection(appliesTo, direction) {
  if (appliesTo === 'both') return true;
  return direction === 'in' ? appliesTo === 'sales' : appliesTo === 'purchases';
}

function standing(row, today) {
  if (!row.is_active) return 'switched_off';
  const from = toDay(row.effective_from);
  const to = toDay(row.effective_to);
  if (from > today) return 'not_yet';
  if (to !== null && to < today) return 'ended';
  return 'in_force';
}

function presentRule(rule) {
  return {
    id: Number(rule.id),
    direction: rule.direction,
    currencyIsForeign: rule.currency_is_foreign === null ? null : Boolean(rule.currency_is_foreign),
    accountType: rule.account_type,
    categoryId: rule.category_id === null ? null : Number(rule.category_id),
    categoryName: rule.category_name ?? null,
    priority: Number(rule.priority),
    isActive: Boolean(rule.is_active),
  };
}

function presentTax(row, rules, today) {
  return {
    id: Number(row.id),
    name: row.name,
    shortCode: row.short_code,
    authority: row.authority,
    lawReference: row.law_reference,
    kind: row.kind,
    appliesTo: row.applies_to,
    computation: row.computation,
    rateAtl: String(row.rate_atl),
    rateNonAtl: String(row.rate_non_atl),
    statusBasis: row.status_basis,
    returnSection: row.return_section,
    isAdjustable: Boolean(row.is_adjustable),
    ledger: { id: Number(row.coa_id), code: row.coa_code, name: row.coa_name },
    effectiveFrom: toDay(row.effective_from),
    effectiveTo: toDay(row.effective_to),
    isActive: Boolean(row.is_active),
    standing: standing(row, today),
    isCurrent: row.effective_to === null && Boolean(row.is_active),
    notes: row.notes,
    rules: rules.filter((rule) => Number(rule.tax_id) === Number(row.id)).map(presentRule),
  };
}

/** Everything the taxes screen shows, and the ledger accounts a tax may post to. */
export async function listAll() {
  const pool = getPool();
  const today = businessToday();
  const [rows, rules, ledgers] = await Promise.all([
    repo.listAll(pool), repo.listRules(pool), repo.taxLedgers(pool),
  ]);
  return {
    today,
    taxes: rows.map((row) => presentTax(row, rules, today)),
    ledgers: ledgers.map((row) => ({ id: Number(row.id), code: row.code, name: row.name, type: row.type })),
  };
}

async function taxView(id) {
  const all = await listAll();
  return all.taxes.find((tax) => tax.id === Number(id));
}

/** A tax that did not exist before, such as one the accountant names. */
export async function createTax({ user, input, ip = null }) {
  assertOwner(user);

  const id = await withTransaction(async (connection) => {
    const ledger = await repo.ledgerByCode(connection, input.ledgerCode);
    if (!ledger || Number(ledger.is_header) === 1 || Number(ledger.is_active) !== 1) {
      throw badRequest(ErrorCode.VALIDATION_FAILED, `There is no ledger account ${input.ledgerCode} a tax can post to.`, {
        field: 'ledgerCode',
      });
    }

    const [existing] = await connection.query(
      'SELECT id FROM taxes WHERE short_code = ? AND effective_to IS NULL AND is_active = 1',
      [input.shortCode],
    );
    if (existing.length > 0) {
      throw new AppError(
        409,
        ErrorCode.ALREADY_EXISTS,
        `${input.shortCode} already exists. To change its rate, use "New rate from a date" on it.`,
        { field: 'shortCode' },
      );
    }

    const taxId = await repo.insertTax(connection, {
      name: input.name,
      short_code: input.shortCode,
      authority: input.authority,
      law_reference: input.lawReference ?? null,
      kind: input.kind,
      applies_to: input.appliesTo,
      computation: input.computation,
      rate_atl: input.rateAtl,
      rate_non_atl: input.rateNonAtl,
      status_basis: input.statusBasis,
      return_section: input.returnSection ?? null,
      is_inclusive: false,
      is_adjustable: Boolean(input.isAdjustable),
      coa_id: Number(ledger.id),
      effective_from: input.effectiveFrom,
      notes: input.notes ?? null,
    });

    await writeAudit(connection, {
      userId: user.id, ip, table: 'taxes', recordId: taxId, action: AuditAction.INSERT,
      after: {
        shortCode: input.shortCode, rateAtl: input.rateAtl, rateNonAtl: input.rateNonAtl,
        effectiveFrom: input.effectiveFrom,
      },
    });
    return taxId;
  });

  return taxView(id);
}

/**
 * A new rate from a date. The old row ends the day before; a copy with the
 * new rates starts on the date; its rules come with it. One transaction.
 */
export async function newRate({ user, id, input, ip = null }) {
  assertOwner(user);

  const newId = await withTransaction(async (connection) => {
    const old = await repo.lockTax(connection, id);
    if (!old) throw notFound('That tax does not exist.');
    if (old.effective_to !== null || !old.is_active) {
      throw new AppError(
        409,
        ErrorCode.INVALID_STATUS,
        'This rate has already been replaced or switched off. Change the newest one instead.',
      );
    }
    const from = toDay(old.effective_from);
    if (input.effectiveFrom <= from) {
      throw badRequest(ErrorCode.VALIDATION_FAILED, `The new rate must start after ${from}, when this one started.`, {
        field: 'effectiveFrom',
      });
    }

    const lastDay = dayBefore(input.effectiveFrom);
    if ((await repo.endTax(connection, id, lastDay)) !== 1) {
      throw new AppError(409, ErrorCode.INVALID_STATUS, 'Someone else changed this tax a moment ago. Look again.');
    }

    const taxId = await repo.insertTax(connection, {
      ...old,
      rate_atl: input.rateAtl,
      rate_non_atl: input.rateNonAtl,
      effective_from: input.effectiveFrom,
      notes: input.note ?? old.notes,
    });

    for (const rule of await repo.activeRulesFor(connection, id)) {
      await repo.insertRule(connection, { ...rule, tax_id: taxId });
    }

    await writeAudit(connection, {
      userId: user.id, ip, table: 'taxes', recordId: Number(id), action: AuditAction.UPDATE,
      before: { effectiveTo: null, rateAtl: String(old.rate_atl), rateNonAtl: String(old.rate_non_atl) },
      after: { effectiveTo: lastDay, replacedBy: taxId, rateAtl: input.rateAtl, rateNonAtl: input.rateNonAtl },
    });
    return taxId;
  });

  return taxView(newId);
}

/** A tax that no longer applies at all, from the day after [lastDay]. */
export async function endTax({ user, id, lastDay, ip = null }) {
  assertOwner(user);

  await withTransaction(async (connection) => {
    const tax = await repo.lockTax(connection, id);
    if (!tax) throw notFound('That tax does not exist.');
    if (tax.effective_to !== null) {
      throw new AppError(409, ErrorCode.INVALID_STATUS, `This tax already ended on ${toDay(tax.effective_to)}.`);
    }
    if (lastDay < toDay(tax.effective_from)) {
      throw badRequest(ErrorCode.VALIDATION_FAILED, `It cannot end before it started, on ${toDay(tax.effective_from)}.`, {
        field: 'lastDay',
      });
    }
    await repo.endTax(connection, id, lastDay);
    await writeAudit(connection, {
      userId: user.id, ip, table: 'taxes', recordId: Number(id), action: AuditAction.UPDATE,
      before: { effectiveTo: null }, after: { effectiveTo: lastDay },
    });
  });

  return taxView(id);
}

/** When the entry form suggests this tax. */
export async function addRule({ user, taxId, input, ip = null }) {
  assertOwner(user);

  await withTransaction(async (connection) => {
    const tax = await repo.lockTax(connection, taxId);
    if (!tax) throw notFound('That tax does not exist.');
    if (!fitsDirection(tax.applies_to, input.direction)) {
      const its = tax.applies_to === 'sales' ? 'coming in' : 'going out';
      throw badRequest(ErrorCode.VALIDATION_FAILED, `${tax.short_code} is for money ${its}, so it cannot be suggested the other way.`, {
        field: 'direction',
      });
    }
    if (input.categoryId) {
      const category = await repo.categoryDirection(connection, input.categoryId);
      if (!category) throw badRequest(ErrorCode.VALIDATION_FAILED, 'That category does not exist.', { field: 'categoryId' });
      if (category.direction !== input.direction) {
        throw badRequest(ErrorCode.VALIDATION_FAILED, `${category.name} is not a money ${input.direction === 'in' ? 'in' : 'out'} category.`, {
          field: 'categoryId',
        });
      }
    }

    const ruleId = await repo.insertRule(connection, {
      name: `${tax.short_code}, money ${input.direction}`,
      tax_id: Number(taxId),
      direction: input.direction,
      currency_is_foreign: input.currencyIsForeign === null || input.currencyIsForeign === undefined
        ? null
        : (input.currencyIsForeign ? 1 : 0),
      account_type: input.accountType ?? null,
      category_id: input.categoryId ?? null,
      priority: input.priority ?? 100,
    });
    await writeAudit(connection, {
      userId: user.id, ip, table: 'tax_rules', recordId: ruleId, action: AuditAction.INSERT,
      after: { taxId: Number(taxId), ...input },
    });
  });

  return taxView(taxId);
}

/** A rule is switched off, never deleted. */
export async function setRuleActive({ user, ruleId, isActive, ip = null }) {
  assertOwner(user);

  const taxId = await withTransaction(async (connection) => {
    const rule = await repo.findRule(connection, ruleId);
    if (!rule) throw notFound('That rule does not exist.');
    await repo.setRuleActive(connection, ruleId, isActive);
    await writeAudit(connection, {
      userId: user.id, ip, table: 'tax_rules', recordId: Number(ruleId), action: AuditAction.UPDATE,
      before: { isActive: Boolean(rule.is_active) }, after: { isActive },
    });
    return Number(rule.tax_id);
  });

  return taxView(taxId);
}
