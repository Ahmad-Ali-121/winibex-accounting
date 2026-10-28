// Batch E: the taxes screen and opening an entry again. Decision 067.
//
//   - only the owner changes taxes
//   - a new rate ends the old one the day before and carries its rules over,
//     so an earlier date still gets the old rate and a later one the new
//   - a rule says when a tax is suggested, and switching it off stops that
//   - a sender takes back a submitted entry; a rejected one is fixed and sent
//     again; a posted one is never reopened

import test, { before, after } from 'node:test';
import assert from 'node:assert/strict';

import {
  connect, dropAll, buildSchema, seedUsers, seedAccounts,
  startServer, signIn, accountId, idempotencyKey,
} from './helpers/api.js';
import { businessToday, addDays } from '../core/dates.js';
import { WARNING_CODES } from '../modules/transactions/validation.js';

let connection;
let api;
const tokens = {};
let today;
let bankId;
let outCategory;

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
  const [categories] = await connection.query(
    `SELECT c.id FROM categories c JOIN chart_of_accounts a ON a.id = c.coa_id
      WHERE c.direction = 'out' AND c.is_active = 1 AND a.type = 'expense' ORDER BY a.code LIMIT 1`,
  );
  outCategory = Number(categories[0].id);
});

after(async () => {
  await api?.close();
  if (connection) {
    await dropAll(connection);
    await connection.end();
  }
});

const newTax = (overrides = {}) => ({
  name: 'Test card tax',
  shortCode: 'E-236Y',
  authority: 'fbr',
  lawReference: 'ITO 2001 s.236Y',
  kind: 'advance',
  appliesTo: 'purchases',
  computation: 'percent',
  rateAtl: '0.5',
  rateNonAtl: '1',
  statusBasis: 'company',
  isAdjustable: true,
  ledgerCode: '1141',
  effectiveFrom: '2026-07-01',
  ...overrides,
});

async function suggest(date) {
  const response = await api.get(`/taxes/suggest?date=${date}&direction=out&base=1000000&currency=USD`, {
    token: tokens.owner,
  });
  assert.equal(response.status, 200, response.raw);
  return response.body.suggestions.filter((line) => line.shortCode === 'E-236Y');
}

// --- taxes ---------------------------------------------------------------------

test('067: only the owner can add a tax', async () => {
  const refused = await api.post('/taxes', { token: tokens.admin, body: newTax() });
  assert.equal(refused.status, 403, refused.raw);

  const added = await api.post('/taxes', { token: tokens.owner, body: newTax() });
  assert.equal(added.status, 201, added.raw);
  assert.equal(added.body.tax.shortCode, 'E-236Y');
  assert.equal(added.body.tax.isCurrent, true);
  assert.equal(added.body.tax.ledger.code, '1141');
});

test('067: a second current tax with the same code is refused', async () => {
  const again = await api.post('/taxes', { token: tokens.owner, body: newTax() });
  assert.equal(again.status, 409, again.raw);
  assert.match(again.body.error.message, /New rate from a date/);
});

test('067: a rule makes the tax suggested, and switching it off stops that', async () => {
  const list = await api.get('/taxes/all', { token: tokens.owner });
  const tax = list.body.taxes.find((item) => item.shortCode === 'E-236Y');

  const wrongWay = await api.post(`/taxes/${tax.id}/rules`, {
    token: tokens.owner, body: { direction: 'in' },
  });
  assert.equal(wrongWay.status, 400, wrongWay.raw, 'a purchases tax cannot be suggested on money in');

  const ruled = await api.post(`/taxes/${tax.id}/rules`, {
    token: tokens.owner, body: { direction: 'out', currencyIsForeign: true },
  });
  assert.equal(ruled.status, 201, ruled.raw);
  assert.equal((await suggest(today)).length, 1);

  const ruleId = ruled.body.tax.rules[0].id;
  const off = await api.patch(`/tax-rules/${ruleId}`, { token: tokens.owner, body: { isActive: false } });
  assert.equal(off.status, 200, off.raw);
  assert.equal((await suggest(today)).length, 0, 'a switched-off rule suggests nothing');

  await api.patch(`/tax-rules/${ruleId}`, { token: tokens.owner, body: { isActive: true } });
});

test('067: a new rate ends the old one the day before, keeps its rules, and leaves earlier dates alone', async () => {
  const list = await api.get('/taxes/all', { token: tokens.owner });
  const old = list.body.taxes.find((item) => item.shortCode === 'E-236Y' && item.isCurrent);

  const changeOn = addDays(today, -10);
  const changed = await api.post(`/taxes/${old.id}/new-rate`, {
    token: tokens.owner, body: { effectiveFrom: changeOn, rateAtl: '0.75', rateNonAtl: '1.5' },
  });
  assert.equal(changed.status, 201, changed.raw);
  assert.equal(changed.body.tax.rateAtl, '0.7500');
  assert.equal(changed.body.tax.effectiveFrom, changeOn);
  assert.equal(changed.body.tax.rules.length, 1, 'the rule came with it');

  const [rows] = await connection.query('SELECT effective_to FROM taxes WHERE id = ?', [old.id]);
  const ended = rows[0].effective_to instanceof Date
    ? rows[0].effective_to.toISOString().slice(0, 10)
    : String(rows[0].effective_to).slice(0, 10);
  assert.equal(ended, addDays(changeOn, -1));

  const before = await suggest(addDays(changeOn, -1));
  assert.equal(before.length, 1);
  assert.equal(before[0].rateApplied, '0.5000', 'an earlier date keeps the old rate');

  const after = await suggest(today);
  assert.equal(after.length, 1);
  assert.equal(after[0].rateApplied, '0.7500');

  const again = await api.post(`/taxes/${old.id}/new-rate`, {
    token: tokens.owner, body: { effectiveFrom: today, rateAtl: '1', rateNonAtl: '2' },
  });
  assert.equal(again.status, 409, again.raw, 'the replaced row cannot be changed again');
});

test('067: a new rate must start after the current one did', async () => {
  const list = await api.get('/taxes/all', { token: tokens.owner });
  const current = list.body.taxes.find((item) => item.shortCode === 'E-236Y' && item.isCurrent);
  const response = await api.post(`/taxes/${current.id}/new-rate`, {
    token: tokens.owner, body: { effectiveFrom: '2026-07-01', rateAtl: '1', rateNonAtl: '2' },
  });
  assert.equal(response.status, 400, response.raw);
});

test('067: a tax can be ended, and is then not suggested after that day', async () => {
  const added = await api.post('/taxes', {
    token: tokens.owner, body: newTax({ shortCode: 'E-END', name: 'Test ending tax' }),
  });
  const id = added.body.tax.id;
  await api.post(`/taxes/${id}/rules`, { token: tokens.owner, body: { direction: 'out' } });

  const ended = await api.post(`/taxes/${id}/end`, { token: tokens.owner, body: { lastDay: addDays(today, -1) } });
  assert.equal(ended.status, 200, ended.raw);
  assert.equal(ended.body.tax.standing, 'ended');

  const response = await api.get(`/taxes/suggest?date=${today}&direction=out&base=1000000`, { token: tokens.owner });
  assert.ok(!response.body.suggestions.some((line) => line.shortCode === 'E-END'));
});

// --- opening an entry again ---------------------------------------------------------

async function staffEntry(description) {
  const created = await api.post('/transactions', {
    token: tokens.staff, headers: idempotencyKey(),
    body: {
      date: today, direction: 'out', method: 'online', description,
      categoryId: outCategory, accountId: bankId, gross: pkr(120000),
      acknowledged_warnings: WARNING_CODES,
    },
  });
  assert.equal(created.status, 201, created.raw);
  const id = created.body.transaction.id;
  const submitted = await api.post(`/transactions/${id}/submit`, { token: tokens.staff });
  assert.equal(submitted.status, 200, submitted.raw);
  return id;
}

async function statusOf(id) {
  const [rows] = await connection.query('SELECT status, rejection_reason FROM transactions WHERE id = ?', [id]);
  return rows[0];
}

test('067: the sender takes back a submitted entry; nobody else can', async () => {
  const id = await staffEntry('Courier for contract');

  const byAdmin = await api.post(`/transactions/${id}/reopen`, { token: tokens.admin });
  assert.equal(byAdmin.status, 403, byAdmin.raw);

  const bySender = await api.post(`/transactions/${id}/reopen`, { token: tokens.staff });
  assert.equal(bySender.status, 200, bySender.raw);
  assert.equal((await statusOf(id)).status, 'draft');
});

test('067: a rejected entry is fixed and sent again, and keeps why it came back', async () => {
  const id = await staffEntry('Taxi');
  const rejected = await api.post(`/transactions/${id}/reject`, {
    token: tokens.owner, body: { reason: 'Say where the taxi went' },
  });
  assert.equal(rejected.status, 200, rejected.raw);

  const reopened = await api.post(`/transactions/${id}/reopen`, { token: tokens.staff });
  assert.equal(reopened.status, 200, reopened.raw);
  assert.equal((await statusOf(id)).rejection_reason, 'Say where the taxi went');

  const detail = await api.get(`/transactions/${id}`, { token: tokens.staff });
  assert.equal(detail.status, 200, detail.raw);

  const edited = await api.patch(`/transactions/${id}`, {
    token: tokens.staff,
    body: {
      date: today, direction: 'out', method: 'online', description: 'Taxi to the client office in Gulberg',
      categoryId: outCategory, accountId: bankId, gross: pkr(120000), acknowledged_warnings: WARNING_CODES,
    },
  });
  assert.equal(edited.status, 200, edited.raw);

  const sent = await api.post(`/transactions/${id}/submit`, { token: tokens.staff });
  assert.equal(sent.status, 200, sent.raw);
  assert.equal((await statusOf(id)).status, 'pending');
});

test('067: a posted entry is never opened again', async () => {
  const id = await staffEntry('Printer ink');
  const approved = await api.post(`/transactions/${id}/approve`, { token: tokens.owner, headers: idempotencyKey() });
  assert.equal(approved.status, 200, approved.raw);

  const response = await api.post(`/transactions/${id}/reopen`, { token: tokens.owner });
  assert.equal(response.status, 409, response.raw);
  assert.match(response.body.error.message, /Reverse it/);
});

test('067: a draft opened again shows its tax lines by name', async () => {
  const list = await api.get('/taxes/all', { token: tokens.owner });
  const tax = list.body.taxes.find((item) => item.shortCode === 'E-236Y' && item.isCurrent);
  const created = await api.post('/transactions', {
    token: tokens.owner, headers: idempotencyKey(),
    body: {
      date: today, direction: 'out', method: 'card', description: 'Claude subscription',
      categoryId: outCategory, accountId: bankId, gross: pkr(560000),
      taxes: [{
        taxId: tax.id, baseAmount: pkr(560000), rateApplied: '0.7500', atlStatusUsed: 'atl',
        atlParty: 'company', amount: pkr(4200), deductedBy: 'bank',
      }],
      acknowledged_warnings: WARNING_CODES,
    },
  });
  assert.equal(created.status, 201, created.raw);

  const detail = await api.get(`/transactions/${created.body.transaction.id}`, { token: tokens.owner });
  assert.equal(detail.body.taxes[0].tax_short_code, 'E-236Y');
  assert.equal(detail.body.taxes[0].tax_name, 'Test card tax');
});
