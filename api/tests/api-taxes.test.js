// The tax engine, over HTTP.
//
// The taxes table is deliberately empty in migration 002: real rates wait for
// the accountant, decision 046. These tests seed their own, in the test
// database only, so the engine can be proved without guessing a rate that will
// end up in the books.
//
// The rates below come from docs/TAXES.md for tax year 2027. If the accountant
// changes them, these tests do not need to change: nothing here asserts that a
// rate is correct, only that the right rate is chosen and applied correctly.

import test, { before, after } from 'node:test';
import assert from 'node:assert/strict';

import {
  connect, dropAll, buildSchema, seedUsers, seedAccounts,
  startServer, signIn, categoryId,
} from './helpers/api.js';

let connection;
let api;
let token;
let outCategory;
let vendors = {};

async function coaId(code) {
  const [rows] = await connection.query('SELECT id FROM chart_of_accounts WHERE code = ?', [code]);
  return Number(rows[0].id);
}

before(async () => {
  connection = await connect();
  await buildSchema(connection);
  await seedUsers(connection);
  await seedAccounts(connection);
  api = await startServer();

  token = (await signIn(api, 'owner@test.local')).body.accessToken;
  outCategory = await categoryId(connection, 'out');

  // Section 154A, final tax on IT export receipts, deducted from Winibex.
  // Section 236Y, advance tax on foreign card payments, deducted from Winibex.
  // Section 153, services, which Winibex deducts from a vendor.
  await connection.query(
    `INSERT INTO taxes
       (name, short_code, authority, law_reference, kind, applies_to, computation,
        rate_atl, rate_non_atl, status_basis, return_section, is_adjustable,
        coa_id, effective_from, effective_to) VALUES
       ('IT export final tax', 's.154A', 'fbr', 'ITO 2001 s.154A', 'final', 'sales', 'percent',
        0.25, 1.00, 'company', '154A', 0, ?, '2026-07-01', NULL),
       ('Foreign card advance tax', 's.236Y', 'fbr', 'ITO 2001 s.236Y', 'advance', 'purchases', 'percent',
        0.50, 1.00, 'company', '236Y', 1, ?, '2026-07-01', NULL),
       ('Services withholding, IT', 's.153', 'fbr', 'ITO 2001 s.153(1)(b)', 'withholding', 'purchases', 'percent',
        4.00, 8.00, 'counterparty', '153', 0, ?, '2026-07-01', NULL),
       ('An expired tax', 's.old', 'fbr', 'ITO 2001 s.236P', 'advance', 'both', 'percent',
        0.60, 1.20, 'company', '236P', 1, ?, '2025-07-01', '2026-06-30')`,
    [await coaId('9100'), await coaId('1141'), await coaId('2132'), await coaId('1141')],
  );

  const [taxRows] = await connection.query('SELECT id, short_code FROM taxes');
  const tax = Object.fromEntries(taxRows.map((row) => [row.short_code, Number(row.id)]));

  await connection.query(
    `INSERT INTO tax_rules (name, tax_id, direction, currency_is_foreign, account_type, priority) VALUES
       ('Foreign receipt, IT export', ?, 'in',  1, NULL, 10),
       ('Foreign card payment',       ?, 'out', 1, NULL, 10),
       ('Local service payment',      ?, 'out', 0, NULL, 20),
       ('Expired rule',               ?, 'out', 1, NULL, 90)`,
    [tax['s.154A'], tax['s.236Y'], tax['s.153'], tax['s.old']],
  );

  const owner = (await connection.query(`SELECT id FROM users WHERE role = 'owner'`))[0][0].id;
  await connection.query(
    `INSERT INTO vendors (name, kind, atl_status, atl_checked_on, created_by) VALUES
       ('Filer Software House', 'company', 'atl', CURDATE(), ?),
       ('Non Filer Designs',    'company', 'non_atl', CURDATE(), ?),
       ('Unknown Freelancer',   'individual', 'unknown', NULL, ?)`,
    [owner, owner, owner],
  );
  const [vendorRows] = await connection.query('SELECT id, name FROM vendors');
  vendors = Object.fromEntries(vendorRows.map((row) => [row.name, Number(row.id)]));
});

after(async () => {
  await api?.close();
  if (connection) {
    await dropAll(connection);
    await connection.end();
  }
});

function suggest(params) {
  const query = new URLSearchParams(params).toString();
  return api.get(`/taxes/suggest?${query}`, { token });
}

// ---------------------------------------------------------------------------
// Effective dates
// ---------------------------------------------------------------------------

test('only taxes in force on the date are listed', async () => {
  const now = await api.get('/taxes?date=2026-07-05', { token });
  const codes = now.body.taxes.map((tax) => tax.shortCode);

  assert.ok(codes.includes('s.154A'));
  assert.ok(!codes.includes('s.old'), 'a tax that ended in June 2026 is not in force in July');

  const then = await api.get('/taxes?date=2026-01-01', { token });
  assert.ok(then.body.taxes.map((tax) => tax.shortCode).includes('s.old'));
});

// ---------------------------------------------------------------------------
// Suggestion
// ---------------------------------------------------------------------------

test('a foreign client receipt suggests Section 154A at the filer rate', async () => {
  // $500 at 278 is PKR 139,000. 0.25% of that is PKR 347.50.
  const response = await suggest({
    direction: 'in', base: 13900000, currency: 'USD', date: '2026-07-05',
  });

  assert.equal(response.status, 200);
  const line = response.body.suggestions.find((s) => s.shortCode === 's.154A');
  assert.ok(line, 'no 154A line was suggested on a foreign receipt');
  assert.equal(line.amount.minor, 34750, 'PKR 347.50');
  assert.equal(line.atlStatusUsed, 'atl');
  assert.equal(line.atlParty, 'company');
  assert.equal(line.deductedBy, 'bank');
  assert.equal(line.kind, 'final');
});

test('a foreign card payment suggests Section 236Y', async () => {
  // $20 at 280 is PKR 5,600. 0.5% is PKR 28.
  const response = await suggest({
    direction: 'out', base: 560000, currency: 'USD', date: '2026-07-05',
  });

  const line = response.body.suggestions.find((s) => s.shortCode === 's.236Y');
  assert.equal(line.amount.minor, 2800);
  assert.equal(line.isAdjustable, true, '236Y on a company card is creditable later');
  assert.ok(!response.body.suggestions.some((s) => s.shortCode === 's.old'));
});

test('nothing is suggested for a situation no rule matches', async () => {
  const response = await suggest({ direction: 'in', base: 100000, currency: 'PKR' });
  assert.equal(response.body.suggestions.length, 0);
});

// ---------------------------------------------------------------------------
// Whose filer status decides the rate. Decision 030.
// ---------------------------------------------------------------------------

test('paying a filer vendor withholds at the filer rate', async () => {
  const response = await suggest({
    direction: 'out', base: 10000000, currency: 'PKR',
    vendorId: vendors['Filer Software House'],
  });

  const line = response.body.suggestions.find((s) => s.shortCode === 's.153');
  assert.equal(line.rateApplied, '4.0000');
  assert.equal(line.amount.minor, 400000, 'PKR 4,000 of PKR 100,000');
  assert.equal(line.atlStatusUsed, 'atl');
  assert.equal(line.atlParty, 'vendor', "the vendor's status decides, not Winibex's");
  assert.equal(line.deductedBy, 'us', 'Winibex holds this back and owes it to FBR');
  assert.equal(line.warning, null);
});

test('paying a non-filer vendor withholds at double the rate', async () => {
  const response = await suggest({
    direction: 'out', base: 10000000, currency: 'PKR',
    vendorId: vendors['Non Filer Designs'],
  });

  const line = response.body.suggestions.find((s) => s.shortCode === 's.153');
  assert.equal(line.amount.minor, 800000, 'PKR 8,000, the non-filer rate');
  assert.equal(line.atlStatusUsed, 'non_atl');
});

test('a vendor with unknown status gets the non-filer rate and says why', async () => {
  const response = await suggest({
    direction: 'out', base: 10000000, currency: 'PKR',
    vendorId: vendors['Unknown Freelancer'],
  });

  const line = response.body.suggestions.find((s) => s.shortCode === 's.153');
  assert.equal(line.atlStatusUsed, 'non_atl');
  assert.ok(
    /no confirmed filer status/i.test(line.warning),
    'guessing the lower rate leaves Winibex owing FBR the difference',
  );
});

test('a tax deducted from Winibex uses Winibex own status, whoever the vendor is', async () => {
  const response = await suggest({
    direction: 'out', base: 560000, currency: 'USD',
    vendorId: vendors['Non Filer Designs'],
  });

  const line = response.body.suggestions.find((s) => s.shortCode === 's.236Y');
  assert.equal(line.atlParty, 'company');
  assert.equal(line.atlStatusUsed, 'atl', "the bank deducts this against Winibex's number");
});

test('Winibex own status drives it, and flipping the setting flips the rate', async () => {
  await connection.query(`UPDATE settings SET value = 'inactive' WHERE setting_key = 'atl_status'`);

  const response = await suggest({ direction: 'in', base: 13900000, currency: 'USD' });
  const line = response.body.suggestions.find((s) => s.shortCode === 's.154A');
  assert.equal(line.atlStatusUsed, 'non_atl');
  assert.equal(line.amount.minor, 139000, '1% instead of 0.25%');

  await connection.query(`UPDATE settings SET value = 'active' WHERE setting_key = 'atl_status'`);
});

// ---------------------------------------------------------------------------
// The snapshot
// ---------------------------------------------------------------------------

test('changing a rate does not change a tax line already recorded', async () => {
  const [taxes] = await connection.query(`SELECT id FROM taxes WHERE short_code = 's.154A'`);
  const taxId = Number(taxes[0].id);

  const [accounts] = await connection.query(`SELECT id FROM accounts WHERE name = 'Winibex bank'`);
  const [owners] = await connection.query(`SELECT id FROM users WHERE role = 'owner'`);

  await connection.query(
    `INSERT INTO transactions
       (date, account_id, direction, amount, currency, method, description, category_id,
        gross_amount, tax_total, status, created_by)
     VALUES ('2026-07-05', ?, 'in', 13865250, 'PKR', 'account', 'Client payment', ?, 13900000, 34750, 'draft', ?)`,
    [accounts[0].id, outCategory, owners[0].id],
  );
  const [created] = await connection.query('SELECT LAST_INSERT_ID() AS id');

  await connection.query(
    `INSERT INTO transaction_taxes
       (transaction_id, tax_id, base_amount, rate_applied, atl_status_used, atl_party, tax_amount, deducted_by)
     VALUES (?, ?, 13900000, 0.25, 'atl', 'company', 34750, 'bank')`,
    [created[0].id, taxId],
  );

  // The accountant revises the rate next year.
  await connection.query(`UPDATE taxes SET rate_atl = 0.50 WHERE id = ?`, [taxId]);

  const [lines] = await connection.query(
    'SELECT rate_applied, tax_amount FROM transaction_taxes WHERE transaction_id = ?',
    [created[0].id],
  );
  assert.equal(Number(lines[0].rate_applied), 0.25, 'history was rewritten by a rate change');
  assert.equal(Number(lines[0].tax_amount), 34750);

  await connection.query(`UPDATE taxes SET rate_atl = 0.25 WHERE id = ?`, [taxId]);
});

test('suggestions need a login', async () => {
  const response = await api.get('/taxes/suggest?direction=out&base=1000');
  assert.equal(response.status, 401);
});
