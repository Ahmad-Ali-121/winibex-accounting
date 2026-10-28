// What the entry form's tax and charge step needs from the server. Decision 064.
//
//   - the tax list narrowed to the entry's direction
//   - a tax added by hand worked out by the server, never by the app
//   - a charge with no account goes to the usual one for its type, and a
//     chosen account must be a cost account

import test, { before, after } from 'node:test';
import assert from 'node:assert/strict';

import {
  connect, dropAll, buildSchema, seedUsers, seedAccounts,
  startServer, signIn, accountId, userId, idempotencyKey,
} from './helpers/api.js';
import { businessToday, addDays } from '../core/dates.js';
import { WARNING_CODES } from '../modules/transactions/validation.js';

let connection;
let api;
let token;
let today;
let bankId;
let outCategory;
let purchaseTaxId;
let salesTaxId;
let laterTaxId;
let filerVendorId;

const pkr = (minor) => ({ minor, currency: 'PKR' });

async function addTax({ code, appliesTo, basis = 'counterparty', from = '2026-07-01', ledger = '2132' }) {
  await connection.query(
    `INSERT INTO taxes (name, short_code, authority, kind, applies_to, computation,
                        rate_atl, rate_non_atl, status_basis, coa_id, effective_from)
     SELECT ?, ?, 'fbr', 'withholding', ?, 'percent', 4.0000, 8.0000, ?, id, ?
       FROM chart_of_accounts WHERE code = ?`,
    [`Test tax ${code}`, code, appliesTo, basis, from, ledger],
  );
  const [rows] = await connection.query('SELECT id FROM taxes WHERE short_code = ?', [code]);
  return Number(rows[0].id);
}

async function coaId(code) {
  const [rows] = await connection.query('SELECT id FROM chart_of_accounts WHERE code = ?', [code]);
  return Number(rows[0].id);
}

function entry(overrides = {}) {
  return {
    date: today,
    direction: 'out',
    method: 'online',
    description: 'Entry form test',
    categoryId: outCategory,
    accountId: bankId,
    gross: pkr(1000000),
    acknowledged_warnings: WARNING_CODES,
    ...overrides,
  };
}

before(async () => {
  connection = await connect();
  await buildSchema(connection);
  await seedUsers(connection);
  await seedAccounts(connection);
  api = await startServer();
  token = (await signIn(api, 'owner@test.local')).body.accessToken;

  today = businessToday();
  bankId = await accountId(connection, 'Winibex bank');

  const [categories] = await connection.query(
    `SELECT c.id FROM categories c JOIN chart_of_accounts a ON a.id = c.coa_id
      WHERE c.direction = 'out' AND c.is_active = 1 AND a.type = 'expense'
      ORDER BY a.code LIMIT 1`,
  );
  outCategory = Number(categories[0].id);

  purchaseTaxId = await addTax({ code: 'EF-153', appliesTo: 'purchases' });
  salesTaxId = await addTax({ code: 'EF-SALES', appliesTo: 'sales', basis: 'company', ledger: '1142' });
  laterTaxId = await addTax({ code: 'EF-LATER', appliesTo: 'purchases', from: addDays(today, 30) });

  const ownerId = await userId(connection, 'owner@test.local');
  await connection.query(
    `INSERT INTO vendors (name, kind, ntn, atl_status, atl_checked_on, created_by)
     VALUES ('Filer vendor', 'company', '1234567-8', 'atl', ?, ?)`,
    [today, ownerId],
  );
  const [vendors] = await connection.query(`SELECT id FROM vendors WHERE name = 'Filer vendor'`);
  filerVendorId = Number(vendors[0].id);
});

after(async () => {
  await api?.close();
  if (connection) {
    await dropAll(connection);
    await connection.end();
  }
});

// --- the tax list -------------------------------------------------------------

test('064: the tax list for money out leaves out taxes for money in', async () => {
  const response = await api.get(`/taxes?date=${today}&direction=out`, { token });
  assert.equal(response.status, 200, response.raw);

  const codes = response.body.taxes.map((tax) => tax.shortCode);
  assert.ok(codes.includes('EF-153'));
  assert.ok(!codes.includes('EF-SALES'), 'a sales tax was offered on money out');
  assert.ok(!codes.includes('EF-LATER'), 'a tax not yet in force was offered');

  const tax = response.body.taxes.find((item) => item.shortCode === 'EF-153');
  assert.equal(tax.appliesTo, 'purchases');
  assert.equal(tax.computation, 'percent');
});

// --- a tax added by hand ------------------------------------------------------

test('064: a tax picked by hand is worked out by the server, at the payee filer rate', async () => {
  const response = await api.get(
    `/taxes/suggest?date=${today}&direction=out&base=1000000&vendorId=${filerVendorId}&taxIds=${purchaseTaxId}`,
    { token },
  );
  assert.equal(response.status, 200, response.raw);
  assert.equal(response.body.suggestions.length, 1);

  const line = response.body.suggestions[0];
  assert.equal(line.taxId, purchaseTaxId);
  assert.equal(line.atlStatusUsed, 'atl');
  assert.equal(line.atlParty, 'vendor');
  assert.equal(line.deductedBy, 'us');
  assert.deepEqual(line.amount, pkr(40000), '4% of PKR 10,000 is PKR 400');
});

test('064: a tax for money in cannot be picked for money out', async () => {
  const response = await api.get(
    `/taxes/suggest?date=${today}&direction=out&base=1000000&taxIds=${salesTaxId}`,
    { token },
  );
  assert.equal(response.status, 400, response.raw);
  assert.match(response.body.error.message, /EF-SALES is for money coming in/);
});

test('064: a tax not in force on the entry date cannot be picked', async () => {
  const response = await api.get(
    `/taxes/suggest?date=${today}&direction=out&base=1000000&taxIds=${laterTaxId}`,
    { token },
  );
  assert.equal(response.status, 400, response.raw);
  assert.match(response.body.error.message, /not in force/);
});

// --- charges ------------------------------------------------------------------

async function previewCodes(charges) {
  const response = await api.post('/transactions/preview', { token, body: entry({ charges }) });
  assert.equal(response.status, 200, response.raw);
  return response.body.lines.map((line) => line.code);
}

test('064: a charge with no account goes to the usual account for its type', async () => {
  assert.ok((await previewCodes([{ type: 'bank_charge', amount: pkr(5000) }])).includes('8100'));
  assert.ok((await previewCodes([{ type: 'forex_fee', amount: pkr(5000) }])).includes('8200'));
  assert.ok((await previewCodes([{ type: 'card_fee', amount: pkr(5000) }])).includes('8200'));
  assert.ok((await previewCodes([{ type: 'platform_fee', amount: pkr(5000) }])).includes('5400'));
});

test('064: a charge saved with no account is stored against the usual one', async () => {
  const created = await api.post('/transactions', {
    token, headers: idempotencyKey(),
    body: entry({ description: 'Charge with no account', charges: [{ type: 'forex_fee', amount: pkr(2800) }] }),
  });
  assert.equal(created.status, 201, created.raw);

  const [rows] = await connection.query(
    `SELECT a.code FROM transaction_charges c JOIN chart_of_accounts a ON a.id = c.coa_id
      WHERE c.transaction_id = ?`,
    [created.body.transaction.id],
  );
  assert.equal(rows[0].code, '8200');
});

test('064: a charge may go to another cost account the person picks', async () => {
  const codes = await previewCodes([{ type: 'other', amount: pkr(5000), coaId: await coaId('6400') }]);
  assert.ok(codes.includes('6400'));
});

test('064: a charge cannot go to an account that is not a cost', async () => {
  const response = await api.post('/transactions/preview', {
    token, body: entry({ charges: [{ type: 'bank_charge', amount: pkr(5000), coaId: await coaId('1113') }] }),
  });
  assert.equal(response.status, 400, response.raw);
  assert.equal(response.body.error.field, 'charges');
});
