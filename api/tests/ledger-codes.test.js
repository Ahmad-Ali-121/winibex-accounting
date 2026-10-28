// Batch F and G: the owner's ledger codes screen and headings. Decisions 068, 069.
//
//   - only the owner sees or changes ledger codes
//   - a new code takes its kind from its first digit, and an income or
//     expense code can join the entry form as a category
//   - codes and names are never used twice
//   - built-in codes and headings are left alone
//   - a code is switched off, never deleted, and only once nothing needs it

import test, { before, after } from 'node:test';
import assert from 'node:assert/strict';

import {
  connect, dropAll, buildSchema, seedUsers, seedAccounts,
  startServer, signIn, accountId, idempotencyKey,
} from './helpers/api.js';
import { businessToday } from '../core/dates.js';
import { parseCsv, toCsv } from '../core/csv.js';
import { WARNING_CODES } from '../modules/transactions/validation.js';

let connection;
let api;
const tokens = {};
let today;
let bankId;

const pkr = (minor) => ({ minor, currency: 'PKR' });

before(async () => {
  connection = await connect();
  await buildSchema(connection);
  await seedUsers(connection);
  await seedAccounts(connection);
  api = await startServer();
  for (const role of ['owner', 'admin', 'staff']) {
    tokens[role] = (await signIn(api, `${role}@test.local`)).body.accessToken;
  }
  today = businessToday();
  bankId = await accountId(connection, 'Winibex bank');
});

after(async () => {
  await api?.close();
  if (connection) {
    await dropAll(connection);
    await connection.end();
  }
});

async function codes() {
  const response = await api.get('/ledger-codes', { token: tokens.owner });
  assert.equal(response.status, 200, response.raw);
  return response.body.codes;
}

async function byCode(code) {
  return (await codes()).find((item) => item.code === code);
}

async function categoryNames(direction) {
  const response = await api.get(`/categories?direction=${direction}`, { token: tokens.owner });
  assert.equal(response.status, 200, response.raw);
  return response.body.categories.map((category) => `${category.ledger.code} ${category.name}`);
}

test('068: only the owner sees or changes ledger codes', async () => {
  for (const role of ['admin', 'staff']) {
    const list = await api.get('/ledger-codes', { token: tokens[role] });
    assert.equal(list.status, 403, list.raw);
    const add = await api.post('/ledger-codes', { token: tokens[role], body: { code: '6960', name: 'Courier charges' } });
    assert.equal(add.status, 403, add.raw);
  }
});

test('068: the list is the whole chart, headings included, in code order', async () => {
  const all = await codes();
  assert.ok(all.some((item) => item.code === '1113'));
  assert.ok(all.some((item) => item.code === '6600'));
  assert.ok(all.some((item) => item.isHeader), 'headings are listed so the screen can group by them');
  const order = all.map((item) => item.code);
  assert.deepEqual(order, [...order].sort());
});

test('068: a new expense code joins the entry form', async () => {
  const added = await api.post('/ledger-codes', {
    token: tokens.owner, body: { code: '6960', name: 'Test courier charges', addToEntryForm: true },
  });
  assert.equal(added.status, 201, added.raw);
  assert.equal(added.body.code.type, 'expense');
  assert.equal(added.body.code.normalBalance, 'debit');
  assert.equal(added.body.code.isSystem, false);
  assert.equal(added.body.code.isActive, true);
  assert.equal(added.body.code.onEntryForm, true);
  assert.ok((await categoryNames('out')).includes('6960 Test courier charges'));
});

test('068: a new income code is a money-in category, on the credit side', async () => {
  const added = await api.post('/ledger-codes', {
    token: tokens.owner, body: { code: '4910', name: 'Test training income' },
  });
  assert.equal(added.status, 201, added.raw);
  assert.equal(added.body.code.type, 'income');
  assert.equal(added.body.code.normalBalance, 'credit');
  assert.ok((await categoryNames('in')).includes('4910 Test training income'));
});

test('068: a balance sheet code never joins the entry form', async () => {
  const added = await api.post('/ledger-codes', {
    token: tokens.owner, body: { code: '1135', name: 'Test rent deposit', addToEntryForm: true },
  });
  assert.equal(added.status, 201, added.raw);
  assert.equal(added.body.code.type, 'asset');
  assert.equal(added.body.code.onEntryForm, false);
});

test('068: an expense code can stay off the entry form', async () => {
  const added = await api.post('/ledger-codes', {
    token: tokens.owner, body: { code: '6970', name: 'Test accountant only cost', addToEntryForm: false },
  });
  assert.equal(added.status, 201, added.raw);
  assert.equal(added.body.code.onEntryForm, false);
});

test('068: a code or a name is never used twice, and a code is four digits', async () => {
  const sameCode = await api.post('/ledger-codes', { token: tokens.owner, body: { code: '6960', name: 'Something else' } });
  assert.equal(sameCode.status, 400, sameCode.raw);
  assert.match(sameCode.body.error.message, /already used/);

  const existing = await byCode('6600');
  const sameName = await api.post('/ledger-codes', {
    token: tokens.owner, body: { code: '6980', name: existing.name.toUpperCase() },
  });
  assert.equal(sameName.status, 400, sameName.raw);
  assert.match(sameName.body.error.message, /6600/);

  for (const code of ['696', '06960', '0960', 'abcd']) {
    const bad = await api.post('/ledger-codes', { token: tokens.owner, body: { code, name: 'Bad code test' } });
    assert.equal(bad.status, 400, `${code}: ${bad.raw}`);
  }
});

test('068: a rename carries over to the entry form', async () => {
  const code = await byCode('6960');
  const renamed = await api.patch(`/ledger-codes/${code.id}`, {
    token: tokens.owner, body: { name: 'Test courier and postage' },
  });
  assert.equal(renamed.status, 200, renamed.raw);
  assert.equal(renamed.body.code.name, 'Test courier and postage');
  const names = await categoryNames('out');
  assert.ok(names.includes('6960 Test courier and postage'));
  assert.ok(!names.includes('6960 Test courier charges'));
});

test('068: built-in codes keep their name, heading and switch', async () => {
  const all = await codes();
  const builtIn = all.find((item) => item.isSystem && !item.isHeader);
  assert.ok(builtIn, 'the seeded chart has built-in codes');
  const rename = await api.patch(`/ledger-codes/${builtIn.id}`, { token: tokens.owner, body: { name: 'Renamed test' } });
  assert.equal(rename.status, 409, rename.raw);
  const off = await api.post(`/ledger-codes/${builtIn.id}/active`, { token: tokens.owner, body: { isActive: false } });
  assert.equal(off.status, 409, off.raw);
});

test('068: switching a code off takes it off the entry form, and back on returns it', async () => {
  const code = await byCode('6970');
  await api.post('/ledger-codes', { token: tokens.owner, body: { code: '6990', name: 'Test switch off' } });
  const target = await byCode('6990');
  assert.ok(code);

  const off = await api.post(`/ledger-codes/${target.id}/active`, { token: tokens.owner, body: { isActive: false } });
  assert.equal(off.status, 200, off.raw);
  assert.equal(off.body.code.isActive, false);
  assert.equal(off.body.code.onEntryForm, false);
  assert.ok(!(await categoryNames('out')).includes('6990 Test switch off'));

  const again = await api.post(`/ledger-codes/${target.id}/active`, { token: tokens.owner, body: { isActive: false } });
  assert.equal(again.status, 409, again.raw);

  const on = await api.post(`/ledger-codes/${target.id}/active`, { token: tokens.owner, body: { isActive: true } });
  assert.equal(on.status, 200, on.raw);
  assert.ok((await categoryNames('out')).includes('6990 Test switch off'));
});

test('068: a code with money on it stays on', async () => {
  const [rows] = await connection.query(
    `SELECT c.id FROM categories c JOIN chart_of_accounts a ON a.id = c.coa_id
      WHERE a.code = '6960' AND c.is_active = 1`,
  );
  const created = await api.post('/transactions', {
    token: tokens.owner, headers: idempotencyKey(),
    body: {
      date: today, direction: 'out', method: 'online', description: 'Courier for signed contract',
      categoryId: Number(rows[0].id), accountId: bankId, gross: pkr(150000),
      acknowledged_warnings: WARNING_CODES,
    },
  });
  assert.equal(created.status, 201, created.raw);
  const posted = await api.post(`/transactions/${created.body.transaction.id}/approve`, {
    token: tokens.owner, headers: idempotencyKey(),
  });
  assert.equal(posted.status, 200, posted.raw);

  const code = await byCode('6960');
  const off = await api.post(`/ledger-codes/${code.id}/active`, { token: tokens.owner, body: { isActive: false } });
  assert.equal(off.status, 409, off.raw);
  assert.match(off.body.error.message, /PKR 1,500/);
});

test('068: a code a current tax posts to stays on', async () => {
  await api.post('/ledger-codes', { token: tokens.owner, body: { code: '2139', name: 'Test levy payable' } });
  const tax = await api.post('/taxes', {
    token: tokens.owner,
    body: {
      name: 'Test levy', shortCode: 'F-LEVY', authority: 'fbr', kind: 'withholding', appliesTo: 'purchases',
      computation: 'percent', rateAtl: '1', rateNonAtl: '2', statusBasis: 'counterparty', isAdjustable: false,
      ledgerCode: '2139', effectiveFrom: '2026-07-01',
    },
  });
  assert.equal(tax.status, 201, tax.raw);

  const code = await byCode('2139');
  const off = await api.post(`/ledger-codes/${code.id}/active`, { token: tokens.owner, body: { isActive: false } });
  assert.equal(off.status, 409, off.raw);
  assert.match(off.body.error.message, /F-LEVY/);
});

test('068: every change is in the audit log', async () => {
  const [rows] = await connection.query(
    `SELECT action FROM audit_log WHERE table_name = 'chart_of_accounts'`,
  );
  assert.ok(rows.length >= 6, `expected the adds, rename and switches, found ${rows.length}`);
});

// --- headings, batch G, decision 069 ---------------------------------------------

test('069: a heading can be added, and codes go under it, named or nearest', async () => {
  const heading = await api.post('/ledger-codes', {
    token: tokens.owner, body: { code: '7300', name: 'Test events and fairs', kind: 'heading' },
  });
  assert.equal(heading.status, 201, heading.raw);
  assert.equal(heading.body.code.isHeader, true);
  assert.equal(heading.body.code.onEntryForm, false, 'nothing posts to a heading');

  const named = await api.post('/ledger-codes', {
    token: tokens.owner, body: { code: '7310', name: 'Test fair stalls', parentCode: '7300' },
  });
  assert.equal(named.status, 201, named.raw);
  assert.equal(named.body.code.parentCode, '7300');

  const nearest = await api.post('/ledger-codes', {
    token: tokens.owner, body: { code: '7320', name: 'Test fair travel' },
  });
  assert.equal(nearest.status, 201, nearest.raw);
  assert.equal(nearest.body.code.parentCode, '7300', 'the nearest heading before it');
});

test('069: a code only sits under a heading of its own kind that comes before it', async () => {
  for (const [parentCode, why] of [['6000', /different digits/], ['7310', /not a heading/], ['7900', /comes before/]]) {
    const response = await api.post('/ledger-codes', {
      token: tokens.owner, body: { code: '7330', name: `Test bad parent ${parentCode}`, parentCode },
    });
    assert.equal(response.status, 400, response.raw);
    assert.match(response.body.error.message, why);
  }
});

test('069: a heading can be renamed, and a code moved to another heading', async () => {
  const heading = await byCode('7300');
  const renamed = await api.patch(`/ledger-codes/${heading.id}`, {
    token: tokens.owner, body: { name: 'Test events, fairs and shows' },
  });
  assert.equal(renamed.status, 200, renamed.raw);
  assert.equal(renamed.body.code.name, 'Test events, fairs and shows');

  await api.post('/ledger-codes', { token: tokens.owner, body: { code: '7315', name: 'Test small fairs', kind: 'heading', parentCode: '7300' } });
  const code = await byCode('7320');
  const moved = await api.patch(`/ledger-codes/${code.id}`, { token: tokens.owner, body: { parentCode: '7315' } });
  assert.equal(moved.status, 200, moved.raw);
  assert.equal(moved.body.code.parentCode, '7315');
});

test('069: a heading stays on while anything under it is on', async () => {
  const heading = await byCode('7315');
  const refused = await api.post(`/ledger-codes/${heading.id}/active`, { token: tokens.owner, body: { isActive: false } });
  assert.equal(refused.status, 409, refused.raw);
  assert.match(refused.body.error.message, /7320/);

  const child = await byCode('7320');
  await api.post(`/ledger-codes/${child.id}/active`, { token: tokens.owner, body: { isActive: false } });
  const off = await api.post(`/ledger-codes/${heading.id}/active`, { token: tokens.owner, body: { isActive: false } });
  assert.equal(off.status, 200, off.raw);
});

// --- bulk import and export, batch G, decision 069 ----------------------------------

const HEAD = ['Code (4 digits)', 'Name', 'Type (code or heading)', 'Sits under heading', 'Show on entry form', 'Switched on'];
const EXAMPLE = ['e.g. 6960', 'e.g. Courier charges', 'e.g. code', 'e.g. 6000', 'e.g. yes', 'e.g. yes'];

async function importCsv(rows, apply = false, token = tokens.owner) {
  return api.post('/ledger-codes/import', { token, body: { csv: toCsv([HEAD, EXAMPLE, ...rows]), apply } });
}

test('069: the template has every column and an example row', async () => {
  const response = await api.get('/ledger-codes/template', { token: tokens.owner });
  assert.equal(response.status, 200, response.raw);
  assert.equal(response.body.filename, 'ledger-codes-template.csv');
  const rows = parseCsv(response.body.csv);
  assert.equal(rows.length, 2);
  assert.match(rows[0][0], /^Code \(4 digits/);
  assert.ok(rows[1][0].startsWith('e.g.'));
});

test('069: only the owner imports or exports codes', async () => {
  for (const path of ['/ledger-codes/export', '/ledger-codes/template']) {
    const response = await api.get(path, { token: tokens.admin });
    assert.equal(response.status, 403, response.raw);
  }
  const response = await importCsv([['8400', 'Test guarantee fees', 'code', '', 'yes', 'yes']], false, tokens.admin);
  assert.equal(response.status, 403, response.raw);
});

test('069: a preview says what each row would do and saves nothing', async () => {
  const office = await byCode('6600');
  const builtIn = (await codes()).find((item) => item.isSystem && !item.isHeader);
  const response = await importCsv([
    ['8400', 'Test guarantee fees', 'code', '', 'yes', 'yes'],
    ['6600', `${office.name} and printing`, '', '', '', ''],
    [builtIn.code, 'Renamed by a file', '', '', '', ''],
    ['8400', 'Test twice', 'code', '', '', ''],
    ['abc', 'Not a code', '', '', '', ''],
    ['8500', 'Test finance group', 'heading', '', '', ''],
    ['8510', 'Test under the new group', 'code', '8500', 'yes', 'yes'],
  ]);
  assert.equal(response.status, 200, response.raw);
  assert.equal(response.body.applied, false);
  assert.deepEqual(response.body.summary, { add: 3, update: 1, unchanged: 0, skip: 3 });

  const byRow = Object.fromEntries(response.body.rows.map((row) => [row.row, row]));
  assert.equal(byRow[3].action, 'add', 'rows count from the headings, so the first code is row 3');
  assert.equal(byRow[4].action, 'update');
  assert.equal(byRow[5].action, 'skip');
  assert.match(byRow[5].reason, /built in/);
  assert.match(byRow[6].reason, /already on row 3/);
  assert.match(byRow[7].reason, /not a code/);
  assert.ok(byRow[9].changes.some((change) => change.startsWith('Under 8500')));

  assert.equal(await byCode('8400'), undefined, 'a preview saves nothing');
});

test('069: confirming saves every row that can be saved', async () => {
  const office = await byCode('6600');
  const response = await importCsv([
    ['8400', 'Test guarantee fees', 'code', '', 'yes', 'yes'],
    ['6600', `${office.name} and printing`, '', '', '', ''],
    ['8500', 'Test finance group', 'heading', '', '', ''],
    ['8510', 'Test under the new group', 'code', '8500', 'yes', 'yes'],
  ], true);
  assert.equal(response.status, 200, response.raw);
  assert.equal(response.body.applied, true);

  assert.equal((await byCode('8400')).type, 'expense');
  assert.equal((await byCode('6600')).name, `${office.name} and printing`);
  assert.equal((await byCode('8510')).parentCode, '8500');
  assert.ok((await categoryNames('out')).includes('8400 Test guarantee fees'));
});

test('069: an exported file imports back with nothing to change', async () => {
  const exported = await api.get('/ledger-codes/export', { token: tokens.owner });
  assert.equal(exported.status, 200, exported.raw);
  const preview = await api.post('/ledger-codes/import', { token: tokens.owner, body: { csv: exported.body.csv } });
  assert.equal(preview.status, 200, preview.raw);
  assert.equal(preview.body.summary.add, 0);
  assert.equal(preview.body.summary.update, 0);
  assert.equal(preview.body.summary.skip, 0, JSON.stringify(preview.body.rows.filter((row) => row.action === 'skip')));
});

test('069: a file switches codes off and takes them off the entry form', async () => {
  const response = await importCsv([['8400', 'Test guarantee fees', 'code', '', 'no', 'no']], true);
  assert.equal(response.status, 200, response.raw);
  const code = await byCode('8400');
  assert.equal(code.isActive, false);
  assert.equal(code.onEntryForm, false);
});

test('069: a file without the code column is refused before anything else', async () => {
  const response = await api.post('/ledger-codes/import', {
    token: tokens.owner, body: { csv: toCsv([['Name'], ['Something']]) },
  });
  assert.equal(response.status, 400, response.raw);
  assert.match(response.body.error.message, /template/);
});
