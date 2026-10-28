// Batch G: taxes in bulk. Decision 069.
//
//   - only the owner imports or exports taxes
//   - a preview saves nothing; confirming saves what can be saved
//   - rows with the same short code are one tax with several rules
//   - a changed rate needs a later start date and ends the old rate the day
//     before; it is never changed in place
//   - words change in place; rules follow the file
//   - an exported file imports back with nothing to change

import test, { before, after } from 'node:test';
import assert from 'node:assert/strict';

import {
  connect, dropAll, buildSchema, seedUsers, seedAccounts, startServer, signIn,
} from './helpers/api.js';
import { businessToday, addDays } from '../core/dates.js';
import { parseCsv, toCsv } from '../core/csv.js';

let connection;
let api;
const tokens = {};
let today;
let outCode;
let outCategoryId;

const HEAD = [
  'Short code', 'Name', 'Kind', 'Authority', 'Law section', 'Applies to', 'Worked out as', 'Rate for a filer',
  'Rate for a non-filer', 'Whose filer status sets the rate', 'Can we claim it back', 'Posts to ledger code',
  'Starts on', 'Suggest on', 'Currency', 'Account type', 'Only for category code', 'Return section', 'Notes',
];
const EXAMPLE = HEAD.map(() => 'e.g. something');

function taxRow(overrides = {}) {
  const row = {
    code: 'G-153', name: 'Test withholding on services', kind: 'withholding', authority: 'FBR', law: 'ITO 2001 s.153',
    applies: 'money out', computation: 'percent', filer: '4', nonFiler: '8', basis: "the payee's", claim: 'no',
    ledger: '2132', from: '2026-07-01', suggest: 'money out', currency: 'rupees only', account: 'any',
    category: outCode, section: '', notes: '',
    ...overrides,
  };
  return [
    row.code, row.name, row.kind, row.authority, row.law, row.applies, row.computation, row.filer, row.nonFiler,
    row.basis, row.claim, row.ledger, row.from, row.suggest, row.currency, row.account, row.category, row.section,
    row.notes,
  ];
}

async function importCsv(rows, apply = false, token = tokens.owner) {
  return api.post('/taxes/import', { token, body: { csv: toCsv([HEAD, EXAMPLE, ...rows]), apply } });
}

async function current(code = 'G-153') {
  const response = await api.get('/taxes/all', { token: tokens.owner });
  assert.equal(response.status, 200, response.raw);
  return response.body.taxes.find((tax) => tax.shortCode === code && tax.isCurrent);
}

before(async () => {
  connection = await connect();
  await buildSchema(connection);
  await seedUsers(connection);
  await seedAccounts(connection);
  api = await startServer();
  for (const role of ['owner', 'admin']) {
    tokens[role] = (await signIn(api, `${role}@test.local`)).body.accessToken;
  }
  today = businessToday();
  const [rows] = await connection.query(
    `SELECT a.code, MIN(c.id) AS id FROM categories c JOIN chart_of_accounts a ON a.id = c.coa_id
      WHERE c.direction = 'out' AND c.is_active = 1 AND a.type = 'expense'
      GROUP BY a.code ORDER BY a.code LIMIT 1`,
  );
  outCode = rows[0].code;
  outCategoryId = Number(rows[0].id);
});

after(async () => {
  await api?.close();
  if (connection) {
    await dropAll(connection);
    await connection.end();
  }
});

test('069: the taxes template has every column and an example row', async () => {
  const response = await api.get('/taxes/template', { token: tokens.owner });
  assert.equal(response.status, 200, response.raw);
  const rows = parseCsv(response.body.csv);
  assert.equal(rows.length, 2);
  assert.match(rows[0][0], /^Short code/);
  assert.equal(rows[0].length, 19);
  assert.ok(rows[1].every((cell) => cell.startsWith('e.g.')));
});

test('069: only the owner imports or exports taxes', async () => {
  const exported = await api.get('/taxes/export', { token: tokens.admin });
  assert.equal(exported.status, 403, exported.raw);
  const imported = await importCsv([taxRow()], false, tokens.admin);
  assert.equal(imported.status, 403, imported.raw);
});

test('069: a preview groups rows into taxes, explains skips, and saves nothing', async () => {
  const response = await importCsv([
    taxRow(),
    taxRow({ currency: 'foreign only', category: '' }),
    taxRow({ code: 'G-BAD', kind: 'sometimes' }),
    taxRow({ code: 'G-WAY', suggest: 'money in' }),
  ]);
  assert.equal(response.status, 200, response.raw);
  assert.deepEqual(response.body.summary, { add: 1, update: 0, unchanged: 0, skip: 2 });

  const added = response.body.rows.find((row) => row.code === 'G-153');
  assert.deepEqual(added.rows, [3, 4]);
  assert.equal(added.changes.filter((change) => change.startsWith('Suggested on')).length, 2);

  const bad = response.body.rows.find((row) => row.code === 'G-BAD');
  assert.match(bad.reason, /Kind must be/);
  const way = response.body.rows.find((row) => row.code === 'G-WAY');
  assert.match(way.reason, /cannot be suggested on money in/);

  assert.equal(await current(), undefined, 'a preview saves nothing');
});

test('069: confirming adds the tax with its rules, and the form suggests it', async () => {
  const response = await importCsv([taxRow(), taxRow({ currency: 'foreign only', category: '' })], true);
  assert.equal(response.status, 200, response.raw);
  assert.equal(response.body.applied, true);

  const tax = await current();
  assert.equal(tax.rateAtl, '4.0000');
  assert.equal(tax.rules.filter((rule) => rule.isActive).length, 2);

  const suggested = await api.get(
    `/taxes/suggest?date=${today}&direction=out&base=1000000&currency=PKR&categoryId=${outCategoryId}`,
    { token: tokens.owner },
  );
  assert.equal(suggested.status, 200, suggested.raw);
  assert.ok(suggested.body.suggestions.some((line) => line.shortCode === 'G-153'));
});

test('069: an exported file imports back with nothing to change', async () => {
  const exported = await api.get('/taxes/export', { token: tokens.owner });
  assert.equal(exported.status, 200, exported.raw);
  const preview = await api.post('/taxes/import', { token: tokens.owner, body: { csv: exported.body.csv } });
  assert.equal(preview.status, 200, preview.raw);
  assert.deepEqual(preview.body.summary, { add: 0, update: 0, unchanged: 1, skip: 0 });
});

test('069: a rate is never changed in place', async () => {
  const response = await importCsv([taxRow({ filer: '5', nonFiler: '10' })]);
  assert.equal(response.status, 200, response.raw);
  assert.equal(response.body.summary.skip, 1);
  assert.match(response.body.rows[0].reason, /never changed in place/);
});

test('069: a later start date starts a new rate and ends the old one the day before', async () => {
  const before = await current();
  const from = addDays(today, -5);
  const response = await importCsv([taxRow({ filer: '5', nonFiler: '10', from })], true);
  assert.equal(response.status, 200, response.raw);
  assert.equal(response.body.summary.update, 1);

  const now = await current();
  assert.notEqual(now.id, before.id);
  assert.equal(now.rateAtl, '5.0000');
  assert.equal(now.effectiveFrom, from);
  assert.equal(now.rules.filter((rule) => rule.isActive).length, 1, 'the rules come from the file');

  const [rows] = await connection.query('SELECT effective_to FROM taxes WHERE id = ?', [before.id]);
  const ended = rows[0].effective_to instanceof Date
    ? rows[0].effective_to.toISOString().slice(0, 10)
    : String(rows[0].effective_to).slice(0, 10);
  assert.equal(ended, addDays(from, -1));
});

test('069: words change in place and rules follow the file', async () => {
  const before = await current();
  const from = before.effectiveFrom;
  const response = await importCsv([
    taxRow({ name: 'Test withholding on services, renamed', filer: '5', nonFiler: '10', from, suggest: 'never', category: '' }),
  ], true);
  assert.equal(response.status, 200, response.raw);
  const row = response.body.rows[0];
  assert.equal(row.action, 'update');
  assert.ok(row.changes.some((change) => change.startsWith('Name:')));
  assert.ok(row.changes.some((change) => change.startsWith('No longer suggested')));

  const now = await current();
  assert.equal(now.id, before.id, 'the same row, renamed');
  assert.equal(now.name, 'Test withholding on services, renamed');
  assert.equal(now.rules.filter((rule) => rule.isActive).length, 0);
});

test('069: rows of one tax must agree on everything but when it is suggested', async () => {
  const response = await importCsv([taxRow({ code: 'G-TWO' }), taxRow({ code: 'G-TWO', filer: '6' })]);
  assert.equal(response.status, 200, response.raw);
  assert.equal(response.body.rows[0].action, 'skip');
  assert.match(response.body.rows[0].reason, /do not agree/);
});
