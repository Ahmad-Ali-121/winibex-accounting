// Ledger codes: the chart of accounts, as the owner manages it. Decisions 068
// and 069.
//
// Migration 002 puts the whole chart back on any fresh database, so nothing
// here is needed after a reset. This is for the codes and headings the
// accountant adds later, one at a time on the screen or many at once from a
// file.
//
// The rules, in plain words:
//   - only the owner changes the chart
//   - a code is four digits; its first digit says what kind it is
//   - a heading groups codes and other headings; nothing posts to it
//   - nothing is ever deleted: a code is switched off, and every entry that
//     used it keeps it
//   - built-in codes keep their name, heading and switch, because posting,
//     transfers, tax and the opening entry depend on them
//   - a code with money on it, or used by a company account or a tax, stays on
//   - a heading stays on while anything under it is on

import { withTransaction, getPool } from '../../core/db.js';
import { writeAudit, AuditAction } from '../../core/audit.js';
import { businessToday } from '../../core/dates.js';
import { readTable, toCsv, yesNo } from '../../core/csv.js';
import { AppError, ErrorCode, badRequest, forbidden, notFound } from '../../core/errors.js';
import * as repo from './repository.js';
import {
  CODE_SHAPE, typeFor, normalFor, canJoinEntryForm, directionFor, loadChart, parentCodeOf,
  resolveParent, wouldLoop, nameTakenBy, switchOffBlocker,
} from './rules.js';

function assertOwner(user) {
  if (user.role !== 'owner') throw forbidden('Only the owner can change ledger codes.');
}

function present(chart, entry) {
  return {
    id: entry.id,
    code: entry.code,
    name: entry.name,
    type: entry.type,
    normalBalance: entry.normalBalance,
    parentId: entry.parentId,
    parentCode: parentCodeOf(chart, entry),
    isHeader: entry.isHeader,
    isSystem: entry.isSystem,
    isActive: entry.isActive,
    onEntryForm: entry.onEntryForm,
    categories: entry.categories,
  };
}

/** The whole chart, headings included, in code order. */
export async function listCodes({ user }) {
  assertOwner(user);
  const chart = await loadChart(getPool());
  return { codes: chart.list.map((entry) => present(chart, entry)) };
}

async function codeView(id) {
  const chart = await loadChart(getPool());
  const entry = chart.byId.get(Number(id));
  return entry ? present(chart, entry) : null;
}

const refuse = (message, field) => badRequest(ErrorCode.VALIDATION_FAILED, message, field ? { field } : undefined);
const conflict = (message) => new AppError(409, ErrorCode.INVALID_STATUS, message);

/**
 * A new code or heading. A code goes under the heading named, or the nearest
 * one before it. An income or expense code can also join the entry form.
 */
export async function createCode({ user, input, ip = null }) {
  assertOwner(user);

  const id = await withTransaction(async (connection) => {
    await repo.lockAll(connection);
    const chart = await loadChart(connection);
    const isHeader = input.kind === 'heading';

    const taken = chart.byCode.get(input.code);
    if (taken) throw refuse(`${input.code} is already used, for ${taken.name}.`, 'code');
    const clash = nameTakenBy(chart, input.name);
    if (clash) throw refuse(`${clash.code} is already called ${clash.name}. Use that one, or pick another name.`, 'name');
    const parent = resolveParent(chart, input.code, input.parentCode ?? null);
    if (parent.reason) throw refuse(parent.reason, 'parentCode');

    const type = typeFor(input.code);
    const coaId = await repo.insertCode(connection, {
      code: input.code,
      name: input.name,
      type,
      normal_balance: normalFor(type),
      parent_id: parent.code ? chart.byCode.get(parent.code).id : null,
      is_header: isHeader,
    });

    let categoryId = null;
    if (input.addToEntryForm && canJoinEntryForm(type, isHeader)) {
      categoryId = await repo.insertCategoryLike(connection, {
        name: input.name, direction: directionFor(type), coaId, code: input.code,
      });
    }

    await writeAudit(connection, {
      userId: user.id, ip, table: 'chart_of_accounts', recordId: coaId, action: AuditAction.INSERT,
      after: { code: input.code, name: input.name, type, isHeader, parentCode: parent.code, categoryId },
    });
    return coaId;
  });

  return codeView(id);
}

/** A new name, or a new heading to sit under. The code itself never changes. */
export async function updateCode({ user, id, input, ip = null }) {
  assertOwner(user);

  await withTransaction(async (connection) => {
    await repo.lockAll(connection);
    const chart = await loadChart(connection);
    const entry = chart.byId.get(Number(id));
    if (!entry) throw notFound('That ledger code does not exist.');
    if (entry.isSystem) throw conflict(`${entry.code} is built in, so its name and heading stay as they are.`);

    const before = { name: entry.name, parentCode: parentCodeOf(chart, entry) };
    const after = { ...before };

    if (input.name !== undefined && input.name !== entry.name) {
      const clash = nameTakenBy(chart, input.name, entry.code);
      if (clash) throw refuse(`${clash.code} is already called ${clash.name}. Use that one, or pick another name.`, 'name');
      await repo.rename(connection, entry.id, input.name);
      await repo.renameMatchingCategories(connection, entry.id, entry.name, input.name);
      after.name = input.name;
    }

    if (input.parentCode && input.parentCode !== before.parentCode) {
      const parent = resolveParent(chart, entry.code, input.parentCode);
      if (parent.reason) throw refuse(parent.reason, 'parentCode');
      if (entry.isHeader && wouldLoop(chart, entry, parent.code)) {
        throw refuse(`Heading ${parent.code} sits under ${entry.code}, so ${entry.code} cannot go under it.`, 'parentCode');
      }
      await repo.setParent(connection, entry.id, chart.byCode.get(parent.code).id);
      after.parentCode = parent.code;
    }

    if (after.name === before.name && after.parentCode === before.parentCode) return;
    await writeAudit(connection, {
      userId: user.id, ip, table: 'chart_of_accounts', recordId: entry.id, action: AuditAction.UPDATE,
      before, after,
    });
  });

  return codeView(id);
}

/**
 * Switch a code or heading off or back on. Off also takes a code's
 * categories off the entry form; on brings them back.
 */
export async function setCodeActive({ user, id, isActive, ip = null }) {
  assertOwner(user);

  await withTransaction(async (connection) => {
    await repo.lockAll(connection);
    const chart = await loadChart(connection);
    const entry = chart.byId.get(Number(id));
    if (!entry) throw notFound('That ledger code does not exist.');
    if (entry.isSystem) throw conflict(`${entry.code} is built in, so it stays on.`);
    if (entry.isActive === isActive) {
      throw conflict(isActive ? `${entry.code} is already on.` : `${entry.code} is already switched off.`);
    }
    if (!isActive) {
      const blocker = await switchOffBlocker(connection, chart, entry);
      if (blocker) throw conflict(blocker);
    }

    await repo.setActive(connection, entry.id, isActive);
    await repo.setCategoriesActive(connection, entry.id, isActive);
    await writeAudit(connection, {
      userId: user.id, ip, table: 'chart_of_accounts', recordId: entry.id, action: AuditAction.UPDATE,
      before: { isActive: !isActive }, after: { isActive },
    });
  });

  return codeView(id);
}

// --- bulk import and export, decision 069 -----------------------------------

const HEADINGS = [
  'Code (4 digits; the first digit is the kind: 1 asset, 2 liability, 3 equity, 4 income, 5 to 9 expense)',
  'Name',
  'Type (code or heading)',
  'Sits under heading (the heading\'s code; leave empty for the nearest heading before it)',
  'Show on entry form (yes or no; only income and expense codes can be)',
  'Switched on (yes or no)',
];

const EXAMPLE = ['e.g. 6960', 'e.g. Courier charges', 'e.g. code', 'e.g. 6000', 'e.g. yes', 'e.g. yes'];

const COLUMNS = {
  code: 'code',
  name: 'name',
  type: 'type',
  'sits under heading': 'parent',
  'show on entry form': 'entryForm',
  'switched on': 'active',
};

/** An empty file to fill in: the headings and one example row. */
export function templateCsv({ user }) {
  assertOwner(user);
  return { filename: 'ledger-codes-template.csv', csv: toCsv([HEADINGS, EXAMPLE]) };
}

/** Every code and heading, in the same columns the import reads. */
export async function exportCsv({ user }) {
  assertOwner(user);
  const chart = await loadChart(getPool());
  const rows = chart.list.map((entry) => [
    entry.code,
    entry.name,
    entry.isHeader ? 'heading' : 'code',
    parentCodeOf(chart, entry) ?? '',
    canJoinEntryForm(entry.type, entry.isHeader) ? (entry.onEntryForm ? 'yes' : 'no') : '',
    entry.isActive ? 'yes' : 'no',
  ]);
  return { filename: `ledger-codes-${businessToday()}.csv`, csv: toCsv([HEADINGS, EXAMPLE, ...rows]) };
}

function readRows(csv) {
  const { missing, records } = readTable(csv, COLUMNS, ['code', 'name']);
  if (missing.length > 0) {
    throw refuse(`This file has no "${missing.join('" or "')}" column. Start from the template, which has every column.`, 'csv');
  }
  if (records.length === 0) throw refuse('This file has no rows to import under its headings.', 'csv');
  return records;
}

/**
 * What a file would change: each row added, changed, left as it is, or
 * skipped with the reason. Nothing is saved here.
 */
async function planImport(runner, chart, csv) {
  const records = readRows(csv);
  const entries = [];
  const firstRow = new Map();

  for (const record of records) {
    const entry = { row: record.line, code: record.code ?? '', name: record.name ?? '', changes: [] };
    const skip = (reason) => entries.push({ ...entry, action: 'skip', reason });

    if (!CODE_SHAPE.test(entry.code)) {
      skip(`"${entry.code}" is not a code. Use four digits that do not start with 0.`);
      continue;
    }
    if (firstRow.has(entry.code)) {
      skip(`${entry.code} is already on row ${firstRow.get(entry.code)} of this file.`);
      continue;
    }
    firstRow.set(entry.code, entry.row);

    const typeWord = String(record.type ?? '').toLowerCase();
    let kind = null;
    if (['heading', 'header'].includes(typeWord)) kind = 'heading';
    else if (['code', 'account'].includes(typeWord)) kind = 'code';
    else if (typeWord !== '') {
      skip(`Type must be "code" or "heading", not "${record.type}".`);
      continue;
    }
    const entryForm = yesNo(record.entryForm);
    if (entryForm === undefined) {
      skip(`"Show on entry form" must be yes or no, not "${record.entryForm}".`);
      continue;
    }
    const active = yesNo(record.active);
    if (active === undefined) {
      skip(`"Switched on" must be yes or no, not "${record.active}".`);
      continue;
    }
    if (entry.name !== '' && entry.name.length < 3) {
      skip('A name needs at least 3 letters.');
      continue;
    }
    if (entry.name.length > 100) {
      skip('Keep the name under 100 letters.');
      continue;
    }
    entries.push({ ...entry, wanted: { kind, entryForm, active, parent: record.parent ?? '' } });
  }

  const pending = entries.filter((entry) => entry.wanted);
  const newNames = new Map(
    pending.filter((entry) => !chart.byCode.has(entry.code)).map((entry) => [entry.code, entry.name]),
  );
  const newHeadings = new Set(
    pending
      .filter((entry) => !chart.byCode.has(entry.code) && entry.wanted.kind === 'heading')
      .map((entry) => entry.code),
  );
  const nameOf = (code) => chart.byCode.get(code)?.name ?? newNames.get(code) ?? '';
  const claimed = new Map();
  const switchingOff = new Set();

  // Codes before headings, and deeper headings before the ones above them,
  // so a heading can be switched off with everything under it.
  const order = [...pending].sort((a, b) => {
    const aHead = chart.byCode.get(a.code)?.isHeader ?? a.wanted.kind === 'heading';
    const bHead = chart.byCode.get(b.code)?.isHeader ?? b.wanted.kind === 'heading';
    if (aHead !== bHead) return aHead ? 1 : -1;
    return aHead ? b.code.localeCompare(a.code) : a.code.localeCompare(b.code);
  });

  for (const entry of order) {
    const wanted = entry.wanted;
    delete entry.wanted;
    const skip = (reason) => Object.assign(entry, { action: 'skip', reason, changes: [] });
    const existing = chart.byCode.get(entry.code);
    const lowerName = entry.name.trim().toLowerCase();

    if (!existing) {
      const isHeader = wanted.kind === 'heading';
      if (entry.name === '') {
        skip(`A new ${isHeader ? 'heading' : 'code'} needs a name.`);
        continue;
      }
      const clash = nameTakenBy(chart, entry.name);
      if (clash) {
        skip(`${clash.code} is already called ${clash.name}.`);
        continue;
      }
      if (claimed.has(lowerName)) {
        skip(`${claimed.get(lowerName)} in this file already has that name.`);
        continue;
      }
      const parent = resolveParent(chart, entry.code, wanted.parent, newHeadings);
      if (parent.reason) {
        skip(parent.reason);
        continue;
      }
      const type = typeFor(entry.code);
      const joinable = canJoinEntryForm(type, isHeader);
      const onForm = joinable && wanted.entryForm !== false;
      const active = wanted.active !== false;
      claimed.set(lowerName, entry.code);
      entry.action = 'add';
      entry.changes = [
        isHeader ? 'New heading' : 'New code',
        parent.code ? `Under ${parent.code} ${nameOf(parent.code)}` : 'At the top of its group',
        ...(onForm ? ['On the entry form'] : []),
        ...(!joinable && wanted.entryForm === true ? ['Not on the entry form: only income and expense codes can be'] : []),
        ...(active ? [] : ['Added switched off']),
      ];
      entry.plan = { isNew: true, isHeader, type, parentCode: parent.code, onForm, active };
      continue;
    }

    if (wanted.kind && (wanted.kind === 'heading') !== existing.isHeader) {
      skip(`${entry.code} is already a ${existing.isHeader ? 'heading' : 'code'}, and cannot become a ${wanted.kind}.`);
      continue;
    }
    const name = entry.name === '' ? existing.name : entry.name;
    entry.name = name;
    const currentParent = parentCodeOf(chart, existing);
    let parentCode = currentParent;
    if (wanted.parent !== '' && wanted.parent !== currentParent) {
      const parent = resolveParent(chart, entry.code, wanted.parent, newHeadings);
      if (parent.reason) {
        skip(parent.reason);
        continue;
      }
      if (existing.isHeader && parent.code !== currentParent && wouldLoop(chart, existing, parent.code)) {
        skip(`Heading ${parent.code} sits under ${entry.code}, so ${entry.code} cannot go under it.`);
        continue;
      }
      parentCode = parent.code;
    }

    if (existing.isSystem) {
      if (name !== existing.name || parentCode !== currentParent || (wanted.active !== null && wanted.active !== existing.isActive)) {
        skip(`${entry.code} is built in: its name, heading and switch stay as they are.`);
      } else {
        Object.assign(entry, { action: 'unchanged', changes: [] });
      }
      continue;
    }

    const plan = { isNew: false, id: existing.id, rename: null, parentCode: null, form: null, active: null };
    if (name !== existing.name) {
      const clash = nameTakenBy(chart, name, entry.code);
      if (clash || (claimed.has(name.toLowerCase()) && claimed.get(name.toLowerCase()) !== entry.code)) {
        skip(clash ? `${clash.code} is already called ${clash.name}.` : `${claimed.get(name.toLowerCase())} in this file already has that name.`);
        continue;
      }
      plan.rename = name;
      entry.changes.push(`Name: ${existing.name} to ${name}`);
    }
    claimed.set(name.toLowerCase(), entry.code);
    if (parentCode !== currentParent) {
      plan.parentCode = parentCode;
      entry.changes.push(`Moves under ${parentCode} ${nameOf(parentCode)}`);
    }

    const endsActive = wanted.active ?? existing.isActive;
    if (wanted.active !== null && wanted.active !== existing.isActive) {
      if (wanted.active === false) {
        const blocker = await switchOffBlocker(runner, chart, existing, switchingOff);
        if (blocker) {
          skip(blocker);
          continue;
        }
        switchingOff.add(entry.code);
        entry.changes.push('Switched off');
      } else {
        entry.changes.push('Switched on');
      }
      plan.active = wanted.active;
    }
    if (endsActive && canJoinEntryForm(existing.type, existing.isHeader) && wanted.entryForm !== null) {
      if (wanted.entryForm && !existing.onEntryForm) {
        plan.form = true;
        entry.changes.push('Put on the entry form');
      } else if (!wanted.entryForm && existing.onEntryForm) {
        plan.form = false;
        entry.changes.push('Taken off the entry form');
      }
    }
    plan.keepFormOff = wanted.entryForm === false;

    entry.action = entry.changes.length > 0 ? 'update' : 'unchanged';
    if (entry.action === 'update') entry.plan = plan;
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
    rows: plan.entries.map(({ row, code, name, action, changes, reason }) => ({
      row, code, name, action, changes, reason: reason ?? null,
    })),
  };
}

async function applyPlan(connection, chart, plan, user, ip) {
  const ids = new Map(chart.list.map((entry) => [entry.code, entry.id]));
  const planned = plan.entries.filter((entry) => entry.plan);
  const audit = (recordId, action, after) => writeAudit(connection, {
    userId: user.id, ip, table: 'chart_of_accounts', recordId, action, after,
  });

  const adds = planned
    .filter((entry) => entry.plan.isNew)
    .sort((a, b) => (a.plan.isHeader === b.plan.isHeader ? a.code.localeCompare(b.code) : a.plan.isHeader ? -1 : 1));
  for (const entry of adds) {
    const { type, isHeader, parentCode, onForm, active } = entry.plan;
    const id = await repo.insertCode(connection, {
      code: entry.code, name: entry.name, type, normal_balance: normalFor(type),
      parent_id: parentCode ? ids.get(parentCode) : null, is_header: isHeader, is_active: active,
    });
    ids.set(entry.code, id);
    if (onForm) {
      const categoryId = await repo.insertCategoryLike(connection, {
        name: entry.name, direction: directionFor(type), coaId: id, code: entry.code,
      });
      if (categoryId && !active) await repo.setCategoriesActive(connection, id, false);
    }
    await audit(id, AuditAction.INSERT, { code: entry.code, name: entry.name, type, isHeader, parentCode, onForm, active, by: 'import' });
  }

  const updates = planned.filter((entry) => !entry.plan.isNew);
  for (const entry of updates) {
    const { id, rename, parentCode, form } = entry.plan;
    const existing = chart.byId.get(id);
    if (rename) {
      await repo.rename(connection, id, rename);
      await repo.renameMatchingCategories(connection, id, existing.name, rename);
    }
    if (parentCode) await repo.setParent(connection, id, ids.get(parentCode));
    if (form === true) {
      if (existing.categories.length > 0) await repo.setCategoriesActive(connection, id, true);
      else {
        await repo.insertCategoryLike(connection, {
          name: rename ?? existing.name, direction: directionFor(existing.type), coaId: id, code: existing.code,
        });
      }
    }
    if (form === false) await repo.setCategoriesActive(connection, id, false);
  }

  const switchOn = updates.filter((entry) => entry.plan.active === true).sort((a, b) => a.code.localeCompare(b.code));
  for (const entry of switchOn) {
    await repo.setActive(connection, entry.plan.id, true);
    if (!entry.plan.keepFormOff) await repo.setCategoriesActive(connection, entry.plan.id, true);
  }
  const switchOff = updates
    .filter((entry) => entry.plan.active === false)
    .sort((a, b) => {
      const aHead = chart.byId.get(a.plan.id).isHeader;
      const bHead = chart.byId.get(b.plan.id).isHeader;
      if (aHead !== bHead) return aHead ? 1 : -1;
      return b.code.localeCompare(a.code);
    });
  for (const entry of switchOff) {
    await repo.setActive(connection, entry.plan.id, false);
    await repo.setCategoriesActive(connection, entry.plan.id, false);
  }

  for (const entry of updates) {
    await audit(entry.plan.id, AuditAction.UPDATE, { changes: entry.changes, by: 'import' });
  }
}

/**
 * Reads a file of codes. Without [apply], says what would change and saves
 * nothing. With it, saves every row that can be saved, all together: if one
 * fails, none is kept. Rows that are skipped are listed with the reason.
 */
export async function importCodes({ user, csv, apply, ip = null }) {
  assertOwner(user);

  if (!apply) {
    const pool = getPool();
    const chart = await loadChart(pool);
    return { applied: false, ...publicPlan(await planImport(pool, chart, csv)) };
  }

  const plan = await withTransaction(async (connection) => {
    await repo.lockAll(connection);
    const chart = await loadChart(connection);
    const result = await planImport(connection, chart, csv);
    await applyPlan(connection, chart, result, user, ip);
    return result;
  });
  return { applied: true, ...publicPlan(plan) };
}
