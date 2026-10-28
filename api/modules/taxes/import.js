// Taxes in bulk: a template, an export, and an import that says what it will
// do before it does it. Owner only. Decision 069.
//
// One row is one tax with one rule for when the entry form suggests it. Rows
// that share a short code are the same tax with more than one rule, and must
// agree on everything else.
//
// A rate is still never edited in place (decision 067). A row whose rates
// differ from the tax in force, with a later start date, starts a new rate
// from that date and ends the current one the day before. With the same or
// an earlier date it is skipped, with the reason. Names, the law section,
// the return section and notes are only words, and are changed in place.
// Taxes that are not in the file are left as they are.

import { withTransaction, getPool } from '../../core/db.js';
import { writeAudit, AuditAction } from '../../core/audit.js';
import { businessToday } from '../../core/dates.js';
import { readTable, toCsv, yesNo } from '../../core/csv.js';
import { badRequest, ErrorCode, forbidden } from '../../core/errors.js';
import * as repo from './repository.js';

function assertOwner(user) {
  if (user.role !== 'owner') throw forbidden('Only the owner can change taxes.');
}

const HEADINGS = [
  'Short code (a short name for the tax, such as 153-IT; rows with the same short code are one tax)',
  'Name',
  'Kind (withholding, final, advance, sales tax, FED or other)',
  'Authority (FBR, PRA, SRB, ICT, bank or other)',
  'Law section (optional, such as ITO 2001 s.153)',
  'Applies to (money in, money out or both)',
  'Worked out as (percent or fixed amount)',
  'Rate for a filer (a number: 4 means 4%)',
  'Rate for a non-filer (a number)',
  'Whose filer status sets the rate (ours or the payee\'s)',
  'Can we claim it back (yes or no)',
  'Posts to ledger code (such as 2132)',
  'Starts on (YYYY-MM-DD; a date after the current rate started begins a new rate from that day)',
  'Suggest on (money in, money out or never)',
  'Currency (any, foreign only or rupees only)',
  'Account type (any, bank, cash, petty cash, cheque or pass-through)',
  'Only for category code (a ledger code such as 5100; empty means any category)',
  'Return section (optional)',
  'Notes (optional)',
];

const EXAMPLE = [
  'e.g. 153-IT', 'e.g. Withholding on services', 'e.g. withholding', 'e.g. FBR', 'e.g. ITO 2001 s.153',
  'e.g. money out', 'e.g. percent', 'e.g. 4', 'e.g. 8', 'e.g. the payee\'s', 'e.g. no', 'e.g. 2132',
  'e.g. 2026-07-01', 'e.g. money out', 'e.g. rupees only', 'e.g. any', 'e.g. 5100', 'e.g. 153(1)(b)',
  'e.g. Example only. Use the rates your accountant gives you.',
];

const COLUMNS = {
  'short code': 'shortCode',
  name: 'name',
  kind: 'kind',
  authority: 'authority',
  'law section': 'lawReference',
  'applies to': 'appliesTo',
  'worked out as': 'computation',
  'rate for a filer': 'rateAtl',
  'rate for a non-filer': 'rateNonAtl',
  'whose filer status sets the rate': 'statusBasis',
  'can we claim it back': 'isAdjustable',
  'posts to ledger code': 'ledgerCode',
  'starts on': 'effectiveFrom',
  'suggest on': 'suggestOn',
  currency: 'currency',
  'account type': 'accountType',
  'only for category code': 'categoryCode',
  'return section': 'returnSection',
  notes: 'notes',
};

const REQUIRED = [
  'shortCode', 'name', 'kind', 'authority', 'appliesTo', 'computation', 'rateAtl', 'rateNonAtl',
  'statusBasis', 'isAdjustable', 'ledgerCode', 'effectiveFrom', 'suggestOn',
];

const LABEL = {
  shortCode: 'Short code', name: 'Name', kind: 'Kind', authority: 'Authority', appliesTo: 'Applies to',
  computation: 'Worked out as', rateAtl: 'Rate for a filer', rateNonAtl: 'Rate for a non-filer',
  statusBasis: 'Whose filer status sets the rate', isAdjustable: 'Can we claim it back',
  ledgerCode: 'Posts to ledger code', effectiveFrom: 'Starts on', suggestOn: 'Suggest on',
  lawReference: 'Law section', returnSection: 'Return section', notes: 'Notes',
};

// Plain words to the values the database keeps, and back.
const KIND = { withholding: 'withholding', final: 'final', advance: 'advance', 'sales tax': 'sales_tax', sales_tax: 'sales_tax', fed: 'fed', other: 'other' };
const KIND_WORD = { withholding: 'withholding', final: 'final', advance: 'advance', sales_tax: 'sales tax', fed: 'FED', other: 'other' };
const AUTHORITY = { fbr: 'fbr', pra: 'pra', srb: 'srb', ict: 'ict', bank: 'bank', other: 'other' };
const AUTHORITY_WORD = { fbr: 'FBR', pra: 'PRA', srb: 'SRB', ict: 'ICT', bank: 'bank', other: 'other' };
const APPLIES = { 'money in': 'sales', in: 'sales', sales: 'sales', 'money out': 'purchases', out: 'purchases', purchases: 'purchases', both: 'both' };
const APPLIES_WORD = { sales: 'money in', purchases: 'money out', both: 'both' };
const COMPUTATION = { percent: 'percent', '%': 'percent', 'fixed amount': 'fixed', fixed: 'fixed' };
const COMPUTATION_WORD = { percent: 'percent', fixed: 'fixed amount' };
const BASIS = { ours: 'company', our: 'company', company: 'company', "the payee's": 'counterparty', "payee's": 'counterparty', payee: 'counterparty', counterparty: 'counterparty' };
const BASIS_WORD = { company: 'ours', counterparty: "the payee's" };
const SUGGEST = { 'money in': 'in', in: 'in', 'money out': 'out', out: 'out', never: null };
const CURRENCY = { any: null, '': null, 'foreign only': 1, foreign: 1, 'rupees only': 0, rupees: 0, pkr: 0 };
const ACCOUNT = { any: null, '': null, bank: 'bank', cash: 'cash', 'petty cash': 'petty_cash', petty_cash: 'petty_cash', cheque: 'cheque', 'pass-through': 'pass_through', 'pass through': 'pass_through', pass_through: 'pass_through' };
const ACCOUNT_WORD = { bank: 'bank', cash: 'cash', petty_cash: 'petty cash', cheque: 'cheque', pass_through: 'pass-through' };

const RATE = /^\d+(\.\d{1,4})?$/;

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

function isDate(text) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(text)) return false;
  const value = new Date(`${text}T00:00:00Z`);
  return !Number.isNaN(value.getTime()) && value.toISOString().slice(0, 10) === text;
}

/** "4.0000" and "4" are the same rate. */
function plainRate(rate) {
  const text = String(rate);
  if (!text.includes('.')) return text;
  return text.replace(/0+$/, '').replace(/\.$/, '');
}

const blank = (value) => (value === null || value === undefined || String(value).trim() === '' ? null : String(value).trim());

function ruleWords(rule) {
  return [
    rule.direction === 'in' ? 'money in' : 'money out',
    rule.currency_is_foreign === null ? 'any currency' : Number(rule.currency_is_foreign) === 1 ? 'foreign only' : 'rupees only',
    rule.account_type === null ? 'any account' : ACCOUNT_WORD[rule.account_type],
    rule.category_code ? `category ${rule.category_code}` : 'any category',
  ].join(', ');
}

function ruleKey(rule) {
  return [
    rule.direction,
    rule.currency_is_foreign === null ? '-' : Number(rule.currency_is_foreign),
    rule.account_type ?? '-',
    rule.category_code ?? '-',
  ].join('|');
}

function fits(appliesTo, direction) {
  return appliesTo === 'both' || (direction === 'in' ? appliesTo === 'sales' : appliesTo === 'purchases');
}

/** One row of the file, checked and turned into database values. */
async function readRow(runner, record) {
  for (const field of REQUIRED) {
    if (!blank(record[field])) return { reason: `${LABEL[field]} is empty.` };
  }
  const word = (field) => String(record[field] ?? '').trim().toLowerCase();
  const pick = (map, field, allowed) => {
    const value = map[word(field)];
    return value === undefined ? { reason: `${LABEL[field]} must be ${allowed}, not "${record[field]}".` } : { value };
  };

  const kind = pick(KIND, 'kind', 'withholding, final, advance, sales tax, FED or other');
  const authority = pick(AUTHORITY, 'authority', 'FBR, PRA, SRB, ICT, bank or other');
  const appliesTo = pick(APPLIES, 'appliesTo', 'money in, money out or both');
  const computation = pick(COMPUTATION, 'computation', 'percent or fixed amount');
  const basis = pick(BASIS, 'statusBasis', "ours or the payee's");
  const suggest = pick(SUGGEST, 'suggestOn', 'money in, money out or never');
  const currency = pick(CURRENCY, 'currency', 'any, foreign only or rupees only');
  const account = pick(ACCOUNT, 'accountType', 'any, bank, cash, petty cash, cheque or pass-through');
  for (const result of [kind, authority, appliesTo, computation, basis, suggest, currency, account]) {
    if (result.reason) return result;
  }

  const shortCode = String(record.shortCode).trim();
  if (shortCode.length > 20) return { reason: 'Keep the short code to 20 letters or fewer.' };
  if (String(record.name).trim().length > 150) return { reason: 'Keep the name under 150 letters.' };
  for (const field of ['rateAtl', 'rateNonAtl']) {
    if (!RATE.test(String(record[field]).trim())) {
      return { reason: `${LABEL[field]} must be a number with up to four decimals, not "${record[field]}".` };
    }
  }
  const adjustable = yesNo(record.isAdjustable);
  if (adjustable === null || adjustable === undefined) {
    return { reason: `Can we claim it back must be yes or no, not "${record.isAdjustable}".` };
  }
  const effectiveFrom = String(record.effectiveFrom).trim();
  if (!isDate(effectiveFrom)) return { reason: `Starts on must be a date like 2026-07-01, not "${record.effectiveFrom}".` };

  const ledgerCode = String(record.ledgerCode).trim();
  const ledger = await repo.ledgerByCode(runner, ledgerCode);
  if (!ledger || Number(ledger.is_header) === 1 || Number(ledger.is_active) !== 1) {
    return { reason: `There is no ledger code ${ledgerCode} a tax can post to.` };
  }

  let rule = null;
  if (suggest.value !== null) {
    if (!fits(appliesTo.value, suggest.value)) {
      return { reason: `This tax applies to ${APPLIES_WORD[appliesTo.value]}, so it cannot be suggested on money ${suggest.value}.` };
    }
    let categoryId = null;
    const categoryCode = blank(record.categoryCode);
    if (categoryCode) {
      const category = await repo.categoryByLedgerCode(runner, categoryCode, suggest.value);
      if (!category) {
        return { reason: `No money-${suggest.value} category on the entry form is filed under ${categoryCode}.` };
      }
      categoryId = Number(category.id);
    }
    rule = {
      direction: suggest.value,
      currency_is_foreign: currency.value,
      account_type: account.value,
      category_id: categoryId,
      category_code: categoryCode,
    };
  }

  return {
    tax: {
      short_code: shortCode,
      name: String(record.name).trim(),
      kind: kind.value,
      authority: authority.value,
      law_reference: blank(record.lawReference),
      applies_to: appliesTo.value,
      computation: computation.value,
      rate_atl: String(record.rateAtl).trim(),
      rate_non_atl: String(record.rateNonAtl).trim(),
      status_basis: basis.value,
      is_adjustable: adjustable,
      coa_id: Number(ledger.id),
      ledger_code: ledgerCode,
      effective_from: effectiveFrom,
      return_section: blank(record.returnSection),
      notes: blank(record.notes),
    },
    rule,
  };
}

const CHARGE_FIELDS = ['kind', 'authority', 'applies_to', 'computation', 'rate_atl', 'rate_non_atl', 'status_basis', 'is_adjustable', 'coa_id'];
const TEXT_FIELDS = ['name', 'law_reference', 'return_section', 'notes'];

function same(field, a, b) {
  if (field === 'rate_atl' || field === 'rate_non_atl') return plainRate(a) === plainRate(b);
  if (field === 'is_adjustable') return Boolean(Number(a)) === Boolean(b);
  if (field === 'coa_id') return Number(a) === Number(b);
  return (blank(a) ?? '') === (blank(b) ?? '');
}

function ratesWords(tax) {
  const unit = tax.computation === 'percent' ? '%' : '';
  return `${plainRate(tax.rate_atl)}${unit} for a filer, ${plainRate(tax.rate_non_atl)}${unit} for a non-filer`;
}

async function planImport(runner, csv) {
  const { missing, records } = readTable(csv, COLUMNS, REQUIRED);
  if (missing.length > 0) {
    throw badRequest(
      ErrorCode.VALIDATION_FAILED,
      `This file has no "${missing.map((field) => LABEL[field]).join('", "')}" column. Start from the template, which has every column.`,
      { field: 'csv' },
    );
  }
  if (records.length === 0) {
    throw badRequest(ErrorCode.VALIDATION_FAILED, 'This file has no rows to import under its headings.', { field: 'csv' });
  }

  const [all, rules] = await Promise.all([repo.listAll(runner), repo.listRules(runner)]);
  const current = new Map();
  for (const row of all) {
    if (row.effective_to === null && Number(row.is_active) === 1) current.set(String(row.short_code).toUpperCase(), row);
  }

  // Group the rows by tax, keeping the order of first appearance.
  const groups = new Map();
  const entries = [];
  for (const record of records) {
    const key = String(record.shortCode ?? '').trim().toUpperCase();
    const read = await readRow(runner, record);
    if (read.reason || key === '') {
      entries.push({
        row: record.line, rows: [record.line], code: String(record.shortCode ?? ''), name: String(record.name ?? ''),
        action: 'skip', changes: [], reason: read.reason ?? `${LABEL.shortCode} is empty.`,
      });
      continue;
    }
    if (!groups.has(key)) groups.set(key, { rows: [], reads: [] });
    groups.get(key).rows.push(record.line);
    groups.get(key).reads.push(read);
  }

  for (const [key, group] of groups) {
    const first = group.reads[0].tax;
    const entry = { row: group.rows[0], rows: group.rows, code: first.short_code, name: first.name, changes: [] };
    entries.push(entry);
    const skip = (reason) => Object.assign(entry, { action: 'skip', reason, changes: [] });

    const mustMatch = [...CHARGE_FIELDS, ...TEXT_FIELDS, 'effective_from'];
    let disagreement = null;
    group.reads.slice(1).forEach((read, index) => {
      if (disagreement) return;
      const field = mustMatch.find((name) => !same(name, first[name], read.tax[name]));
      if (field) disagreement = { field, row: group.rows[index + 1] };
    });
    if (disagreement) {
      skip(`Rows ${group.rows[0]} and ${disagreement.row} are both ${first.short_code} but do not agree on everything except when it is suggested. Make them match, or give them different short codes.`);
      continue;
    }

    const wantedRules = new Map();
    for (const read of group.reads) if (read.rule) wantedRules.set(ruleKey(read.rule), read.rule);

    const existing = current.get(key);
    if (!existing) {
      entry.action = 'add';
      entry.changes = [
        'New tax',
        ratesWords(first),
        `From ${first.effective_from}`,
        ...(wantedRules.size === 0
          ? ['Never suggested on the entry form']
          : [...wantedRules.values()].map((rule) => `Suggested on: ${ruleWords(rule)}`)),
      ];
      entry.plan = { kind: 'add', tax: first, rules: [...wantedRules.values()] };
      continue;
    }

    const existingRules = rules.filter((rule) => Number(rule.tax_id) === Number(existing.id) && Number(rule.is_active) === 1);
    const chargeChanged = CHARGE_FIELDS.some((field) => !same(field, existing[field], first[field]));
    const from = toDay(existing.effective_from);

    if (chargeChanged) {
      if (first.effective_from <= from) {
        skip(`${first.short_code} would charge differently, and rates are never changed in place. Give a start date after ${from}; the current rate then ends the day before.`);
        continue;
      }
      entry.action = 'update';
      entry.changes = [
        `New rate from ${first.effective_from}: ${ratesWords(first)}`,
        `The current rate (${ratesWords(existing)}) ends on ${dayBefore(first.effective_from)}`,
        ...(wantedRules.size === 0
          ? ['Never suggested on the entry form']
          : [...wantedRules.values()].map((rule) => `Suggested on: ${ruleWords(rule)}`)),
      ];
      entry.plan = { kind: 'new-rate', id: Number(existing.id), tax: first, rules: [...wantedRules.values()] };
      continue;
    }

    const textChanges = TEXT_FIELDS.filter((field) => !same(field, existing[field], first[field]));
    const haveKeys = new Map(existingRules.map((rule) => [ruleKey(rule), rule]));
    const addRules = [...wantedRules.entries()].filter(([ruleKeyValue]) => !haveKeys.has(ruleKeyValue)).map(([, rule]) => rule);
    const dropRules = existingRules.filter((rule) => !wantedRules.has(ruleKey(rule)));

    entry.changes = [
      ...textChanges.map((field) => `${LABEL[{ name: 'name', law_reference: 'lawReference', return_section: 'returnSection', notes: 'notes' }[field]]}: ${blank(existing[field]) ?? '(empty)'} to ${blank(first[field]) ?? '(empty)'}`),
      ...addRules.map((rule) => `Also suggested on: ${ruleWords(rule)}`),
      ...dropRules.map((rule) => `No longer suggested on: ${ruleWords(rule)}`),
    ];
    entry.action = entry.changes.length > 0 ? 'update' : 'unchanged';
    if (entry.action === 'update') {
      entry.plan = { kind: 'edit', id: Number(existing.id), tax: first, textChanged: textChanges.length > 0, addRules, dropRules };
    }
  }

  entries.sort((a, b) => a.row - b.row);
  const count = (action) => entries.filter((entry) => entry.action === action).length;
  return {
    summary: { add: count('add'), update: count('update'), unchanged: count('unchanged'), skip: count('skip') },
    entries,
  };
}

function publicPlan(plan) {
  return {
    summary: plan.summary,
    rows: plan.entries.map(({ row, rows, code, name, action, changes, reason }) => ({
      row, rows, code, name, action, changes, reason: reason ?? null,
    })),
  };
}

async function insertRules(connection, taxId, shortCode, rules) {
  for (const rule of rules) {
    await repo.insertRule(connection, {
      name: `${shortCode}, money ${rule.direction}`,
      tax_id: taxId,
      direction: rule.direction,
      currency_is_foreign: rule.currency_is_foreign,
      account_type: rule.account_type,
      category_id: rule.category_id,
      priority: 100,
    });
  }
}

async function applyPlan(connection, plan, user, ip) {
  const audit = (table, recordId, action, after) => writeAudit(connection, {
    userId: user.id, ip, table, recordId, action, after: { ...after, by: 'import' },
  });

  for (const entry of plan.entries.filter((item) => item.plan)) {
    const { kind, tax } = entry.plan;
    if (kind === 'add' || kind === 'new-rate') {
      if (kind === 'new-rate') {
        await repo.endTax(connection, entry.plan.id, dayBefore(tax.effective_from));
        await audit('taxes', entry.plan.id, AuditAction.UPDATE, { effectiveTo: dayBefore(tax.effective_from) });
      }
      const taxId = await repo.insertTax(connection, { ...tax, is_inclusive: false });
      await insertRules(connection, taxId, tax.short_code, entry.plan.rules);
      await audit('taxes', taxId, AuditAction.INSERT, {
        shortCode: tax.short_code, rateAtl: tax.rate_atl, rateNonAtl: tax.rate_non_atl, effectiveFrom: tax.effective_from,
      });
      continue;
    }

    if (entry.plan.textChanged) await repo.updateTaxText(connection, entry.plan.id, tax);
    await insertRules(connection, entry.plan.id, tax.short_code, entry.plan.addRules);
    for (const rule of entry.plan.dropRules) await repo.setRuleActive(connection, rule.id, false);
    await audit('taxes', entry.plan.id, AuditAction.UPDATE, { changes: entry.changes });
  }
}

/** An empty file to fill in: the headings and one example row. */
export function templateCsv({ user }) {
  assertOwner(user);
  return { filename: 'taxes-template.csv', csv: toCsv([HEADINGS, EXAMPLE]) };
}

/** Every tax in force or starting later, one row per rule. */
export async function exportCsv({ user }) {
  assertOwner(user);
  const pool = getPool();
  const [all, rules] = await Promise.all([repo.listAll(pool), repo.listRules(pool)]);
  const rows = [];
  for (const tax of all.filter((row) => row.effective_to === null && Number(row.is_active) === 1)) {
    const base = [
      tax.short_code, tax.name, KIND_WORD[tax.kind], AUTHORITY_WORD[tax.authority], tax.law_reference ?? '',
      APPLIES_WORD[tax.applies_to], COMPUTATION_WORD[tax.computation], plainRate(tax.rate_atl),
      plainRate(tax.rate_non_atl), BASIS_WORD[tax.status_basis], Number(tax.is_adjustable) === 1 ? 'yes' : 'no',
      tax.coa_code, toDay(tax.effective_from),
    ];
    const tail = [tax.return_section ?? '', tax.notes ?? ''];
    const own = rules.filter((rule) => Number(rule.tax_id) === Number(tax.id) && Number(rule.is_active) === 1);
    if (own.length === 0) rows.push([...base, 'never', '', '', '', ...tail]);
    for (const rule of own) {
      rows.push([
        ...base,
        rule.direction === 'in' ? 'money in' : 'money out',
        rule.currency_is_foreign === null ? 'any' : Number(rule.currency_is_foreign) === 1 ? 'foreign only' : 'rupees only',
        rule.account_type === null ? 'any' : ACCOUNT_WORD[rule.account_type],
        rule.category_code ?? '',
        ...tail,
      ]);
    }
  }
  return { filename: `taxes-${businessToday()}.csv`, csv: toCsv([HEADINGS, EXAMPLE, ...rows]) };
}

/**
 * Reads a file of taxes. Without [apply], says what would change and saves
 * nothing. With it, saves every tax that can be saved, all together.
 */
export async function importTaxes({ user, csv, apply, ip = null }) {
  assertOwner(user);
  if (!apply) return { applied: false, ...publicPlan(await planImport(getPool(), csv)) };

  const plan = await withTransaction(async (connection) => {
    await repo.lockAllTaxes(connection);
    const result = await planImport(connection, csv);
    await applyPlan(connection, result, user, ip);
    return result;
  });
  return { applied: true, ...publicPlan(plan) };
}
