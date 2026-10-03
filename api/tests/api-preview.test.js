// The category picker and the journal preview.
//
// The preview is the one the entry form shows before anything is saved. It
// must come from the same code that does the real posting, or the lines on
// screen would be a second opinion and the ones actually written would be the
// ones nobody checked.

import test, { before, after } from 'node:test';
import assert from 'node:assert/strict';

import {
  connect, dropAll, buildSchema, seedUsers, seedAccounts,
  startServer, signIn, accountId, categoryId, userId, idempotencyKey,
} from './helpers/api.js';
import { WARNING_CODES } from '../modules/transactions/validation.js';

let connection;
let api;
let token;
let bankId;
let outCategory;

before(async () => {
  connection = await connect();
  await buildSchema(connection);
  await seedUsers(connection);
  await seedAccounts(connection);
  api = await startServer();

  token = (await signIn(api, 'owner@test.local')).body.accessToken;
  bankId = await accountId(connection, 'Winibex bank');
  outCategory = await categoryId(connection, 'out');
});

after(async () => {
  await api?.close();
  if (connection) {
    await dropAll(connection);
    await connection.end();
  }
});

function draft(overrides = {}) {
  return {
    date: '2026-07-05',
    direction: 'out',
    method: 'card',
    description: 'Claude subscription',
    categoryId: outCategory,
    accountId: bankId,
    gross: { minor: 560000, currency: 'PKR' },
    ...overrides,
  };
}

// ---------------------------------------------------------------------------
// Categories
// ---------------------------------------------------------------------------

test('categories come back grouped by main head', async () => {
  const response = await api.get('/categories', { token });

  assert.equal(response.status, 200);
  assert.ok(response.body.categories.length > 0);
  assert.ok(response.body.groups.length > 0);

  const heads = response.body.groups.map((group) => group.mainHead);
  assert.equal(new Set(heads).size, heads.length, 'a main head appeared twice');

  const first = response.body.categories[0];
  assert.ok(first.ledger.code, 'a category without its ledger code is no use to the accountant');
});

test('categories can be narrowed to one direction', async () => {
  const response = await api.get('/categories?direction=in', { token });
  assert.ok(response.body.categories.every((category) => category.direction === 'in'));
});

test('the control accounts are kept out of the picker', async () => {
  const response = await api.get('/categories', { token });
  const codes = response.body.categories.map((category) => category.ledger.code);

  assert.ok(!codes.includes('1118'), 'funds in transit is for the transfer engine only');
  assert.ok(!codes.includes('3400'), 'opening balance equity is for the opening entry only');
});

// ---------------------------------------------------------------------------
// The journal preview
// ---------------------------------------------------------------------------

test('the preview shows the lines the entry would post, with codes and names', async () => {
  const response = await api.post('/transactions/preview', {
    token,
    body: draft({
      charges: [
        { type: 'forex_fee', amount: { minor: 28000, currency: 'PKR' }, coaId: await coa('8200') },
        { type: 'bank_charge', amount: { minor: 4500, currency: 'PKR' }, coaId: await coa('8100') },
      ],
    }),
  });

  assert.equal(response.status, 200, response.raw);
  assert.equal(response.body.totals.amount, 592500, '5,600 plus 325 of fees');

  const debits = response.body.lines.reduce((sum, line) => sum + line.debit, 0);
  const credits = response.body.lines.reduce((sum, line) => sum + line.credit, 0);
  assert.equal(debits, credits, 'a preview that does not balance would never post');

  const bank = response.body.lines.find((line) => line.code === '1113');
  assert.equal(bank.credit, 592500, 'the bank is credited with everything that leaves it');

  assert.ok(
    response.body.lines.every((line) => line.code && line.name),
    'a preview of ledger ids tells the person nothing they can check',
  );
});

test('a preview saves nothing', async () => {
  const [before] = await connection.query('SELECT COUNT(*) AS n FROM transactions');

  await api.post('/transactions/preview', { token, body: draft() });

  const [after] = await connection.query('SELECT COUNT(*) AS n FROM transactions');
  assert.equal(Number(after[0].n), Number(before[0].n));
});

test('a preview for a cost paid personally credits the payable, not a bank', async () => {
  const ahmad = await userId(connection, 'staff@test.local');

  const response = await api.post('/transactions/preview', {
    token,
    body: draft({ accountId: null, paidByType: 'person', paidByUserId: ahmad }),
  });

  assert.equal(response.status, 200, response.raw);
  const credit = response.body.lines.find((line) => line.credit > 0);
  assert.equal(credit.code, '2114', 'the company owes a person, not the bank');
});

test('a preview that does not reconcile is refused, with the reason', async () => {
  const response = await api.post('/transactions/preview', {
    token,
    body: draft({ gross: { minor: 0, currency: 'PKR' } }),
  });

  assert.equal(response.status, 400);
});

test('the preview and the posted entry produce the same lines', async () => {
  const body = draft({ description: 'Preview then post' });

  const preview = await api.post('/transactions/preview', { token, body });

  const created = await api.post('/transactions', {
    token,
    headers: idempotencyKey(),
    body: { ...body, acknowledged_warnings: WARNING_CODES },
  });
  await api.post(`/transactions/${created.body.transaction.id}/approve`, {
    token, headers: idempotencyKey(),
  });

  const posted = await api.get(`/transactions/${created.body.transaction.id}/journal`, { token });

  const shape = (lines) => lines
    .map((line) => `${Number(line.coa_id ?? line.coaId)}:${Number(line.debit)}:${Number(line.credit)}`)
    .sort();

  assert.deepEqual(
    shape(posted.body.lines), shape(preview.body.lines),
    'the person approved a journal that is not the one that was written',
  );
});

test('both need a login', async () => {
  assert.equal((await api.get('/categories')).status, 401);
  assert.equal((await api.post('/transactions/preview', { body: draft() })).status, 401);
});

async function coa(code) {
  const [rows] = await connection.query('SELECT id FROM chart_of_accounts WHERE code = ?', [code]);
  return Number(rows[0].id);
}
