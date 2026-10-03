// Validation in three tiers, over HTTP.
//
// One test per blocking rule proving it blocks. One per warning proving it
// returns 409 and then goes through once acknowledged. docs/TESTING.md.

import test, { before, after } from 'node:test';
import assert from 'node:assert/strict';

import {
  connect, dropAll, buildSchema, seedUsers, seedAccounts,
  startServer, signIn, accountId, categoryId, idempotencyKey,
} from './helpers/api.js';
import { WARNING_CODES } from '../modules/transactions/validation.js';

let connection;
let api;
let token;
let bankId;
let cashId;
let outCategory;

before(async () => {
  connection = await connect();
  await buildSchema(connection);
  await seedUsers(connection);
  await seedAccounts(connection);
  api = await startServer();

  token = (await signIn(api, 'owner@test.local')).body.accessToken;
  bankId = await accountId(connection, 'Winibex bank');
  cashId = await accountId(connection, 'Office cash');
  outCategory = await categoryId(connection, 'out');
});

after(async () => {
  await api?.close();
  if (connection) {
    await dropAll(connection);
    await connection.end();
  }
});

function entry(overrides = {}) {
  return {
    date: '2026-07-05',
    direction: 'out',
    method: 'card',
    description: 'Monthly software subscription',
    categoryId: outCategory,
    accountId: bankId,
    gross: { minor: 560000, currency: 'PKR' },
    ...overrides,
  };
}

function create(body) {
  return api.post('/transactions', { token, body, headers: idempotencyKey() });
}

// Setup, not the thing under test: acknowledge everything so the entry lands.
async function post(body) {
  const created = await create({ ...body, acknowledged_warnings: WARNING_CODES });
  assert.equal(created.status, 201, created.raw);
  await api.post(`/transactions/${created.body.transaction.id}/approve`, {
    token, headers: idempotencyKey(),
  });
  return created.body.transaction.id;
}

// ---------------------------------------------------------------------------
// Blocked
// ---------------------------------------------------------------------------

test('a date in the future is blocked', async () => {
  const response = await create(entry({ date: '2099-01-01' }));
  assert.equal(response.status, 400);
  assert.equal(response.body.error.code, 'FUTURE_DATE');
});

test('an entry before the books went live is blocked unless it is historical', async () => {
  const live = await create(entry({ date: '2026-05-01' }));
  assert.equal(live.status, 400);
  assert.equal(live.body.error.code, 'LIVE_BEFORE_GO_LIVE');

  const historical = await create(entry({
    date: '2026-05-01', entryType: 'historical', acknowledged_warnings: WARNING_CODES,
  }));
  assert.equal(historical.status, 201);
});

test('a historical entry dated after the books went live is blocked', async () => {
  const response = await create(entry({ date: '2026-07-05', entryType: 'historical' }));
  assert.equal(response.status, 400);
  assert.equal(response.body.error.code, 'HISTORICAL_AFTER_GO_LIVE');
});

test('an inactive account is blocked', async () => {
  await connection.query('UPDATE accounts SET is_active = 0 WHERE id = ?', [bankId]);
  const response = await create(entry());
  await connection.query('UPDATE accounts SET is_active = 1 WHERE id = ?', [bankId]);

  assert.equal(response.status, 400);
  assert.equal(response.body.error.code, 'INACTIVE_ACCOUNT');
});

test('a date before the account opened is blocked', async () => {
  const response = await create(entry({ date: '2024-01-01', entryType: 'historical' }));
  assert.equal(response.status, 400);
  assert.equal(response.body.error.code, 'BEFORE_OPENING_DATE');
});

test('spending cash the company does not have is blocked', async () => {
  const response = await create(entry({
    accountId: cashId, method: 'cash', gross: { minor: 100000, currency: 'PKR' },
  }));

  assert.equal(response.status, 400);
  assert.equal(response.body.error.code, 'CASH_BELOW_ZERO');
  assert.ok(/below zero/i.test(response.body.error.message));
});

test('there can only ever be one opening entry', async () => {
  const first = await create(entry({
    date: '2026-07-01', entryType: 'opening', accountId: null, direction: 'in',
    description: 'Opening balances at 30 June 2026',
  }));
  assert.equal(first.status, 201);

  const second = await create(entry({
    date: '2026-07-01', entryType: 'opening', accountId: null, direction: 'in',
    description: 'Opening balances again',
  }));
  assert.equal(second.status, 400);
  assert.equal(second.body.error.code, 'OPENING_ALREADY_EXISTS');
});

// ---------------------------------------------------------------------------
// Warned
// ---------------------------------------------------------------------------

test('a possible duplicate warns, names the entry it matched, and goes through once confirmed', async () => {
  await post(entry({ description: 'Office rent July', gross: { minor: 9000000, currency: 'PKR' } }));

  const warned = await create(entry({
    description: 'Office rent July again', gross: { minor: 9000000, currency: 'PKR' },
  }));

  assert.equal(warned.status, 409);
  assert.equal(warned.body.error.code, 'VALIDATION_WARNINGS');

  const duplicate = warned.body.error.details.warnings.find((w) => w.code === 'POSSIBLE_DUPLICATE');
  assert.ok(duplicate, 'no duplicate warning was raised');
  assert.ok(
    duplicate.message.includes('Office rent July'),
    'a warning that does not name what it matched gets dismissed by reflex',
  );

  const confirmed = await create(entry({
    description: 'Office rent July again',
    gross: { minor: 9000000, currency: 'PKR' },
    acknowledged_warnings: warned.body.error.details.warnings.map((w) => w.code),
  }));
  assert.equal(confirmed.status, 201);
});

test('an acknowledged warning is recorded against the entry, not thrown away', async () => {
  const [rows] = await connection.query(
    `SELECT code, severity, acknowledged_by FROM entry_flags
      WHERE code = 'POSSIBLE_DUPLICATE' ORDER BY id DESC LIMIT 1`,
  );
  assert.equal(rows[0].severity, 'warning');
  assert.ok(rows[0].acknowledged_by, 'nobody was recorded as having confirmed it');
});

test('a backdated entry warns', async () => {
  const old = new Date(Date.now() - 120 * 24 * 60 * 60 * 1000).toISOString().slice(0, 10);
  const response = await create(entry({ date: old, description: 'Something from months ago' }));

  if (response.status === 409) {
    const codes = response.body.error.details.warnings.map((w) => w.code);
    assert.ok(codes.includes('BACKDATED'));
  } else {
    // Only if today is close enough to go-live that 120 days ago is blocked
    // instead, which the blocking test above already covers.
    assert.equal(response.status, 400);
  }
});

test('a bank account going below zero warns rather than blocks', async () => {
  const response = await create(entry({
    description: 'More than the bank holds', gross: { minor: 99000000, currency: 'PKR' },
  }));

  assert.equal(response.status, 409);
  const codes = response.body.error.details.warnings.map((w) => w.code);
  assert.ok(codes.includes('BANK_BELOW_ZERO'), 'an overdraft is possible in real life, so it warns');
});

// ---------------------------------------------------------------------------
// Flagged
// ---------------------------------------------------------------------------

test('a thin description is flagged, and the entry still saves', async () => {
  const response = await create(entry({
    description: 'tea', acknowledged_warnings: WARNING_CODES,
  }));
  assert.equal(response.status, 201);

  const [rows] = await connection.query(
    `SELECT code, severity FROM entry_flags WHERE transaction_id = ?`,
    [response.body.transaction.id],
  );
  const codes = rows.map((row) => row.code);
  assert.ok(codes.includes('THIN_DESCRIPTION'));
  assert.ok(codes.includes('NO_RECEIPT'));
  assert.equal(rows.find((row) => row.code === 'THIN_DESCRIPTION').severity, 'flag');
});

test('editing a draft replaces its warnings rather than leaving the old ones', async () => {
  const created = await create(entry({
    description: 'ok', acknowledged_warnings: WARNING_CODES,
  }));
  const id = created.body.transaction.id;

  const [before] = await connection.query(
    'SELECT COUNT(*) AS n FROM entry_flags WHERE transaction_id = ?', [id],
  );

  await api.patch(`/transactions/${id}`, {
    token,
    body: entry({
      description: 'A properly written description now',
      acknowledged_warnings: WARNING_CODES,
    }),
  });

  const [after] = await connection.query(
    `SELECT code FROM entry_flags WHERE transaction_id = ?`, [id],
  );
  assert.ok(Number(before[0].n) > 0);
  assert.ok(
    !after.map((row) => row.code).includes('THIN_DESCRIPTION'),
    'the old flag described figures that no longer exist',
  );
});
