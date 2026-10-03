// The ledger, the approval inbox and the review list.
//
// Search and filtering run on the server. The app holds one page of rows, so
// searching what it holds would quietly miss everything else. Decision 022.

import test, { before, after } from 'node:test';
import assert from 'node:assert/strict';

import {
  connect, dropAll, buildSchema, seedUsers, seedAccounts,
  startServer, signIn, accountId, categoryId, idempotencyKey,
} from './helpers/api.js';
import { WARNING_CODES } from '../modules/transactions/validation.js';

let connection;
let api;
const tokens = {};
let bankId;
let cashId;
let outCategory;
let inCategory;

before(async () => {
  connection = await connect();
  await buildSchema(connection);
  await seedUsers(connection);
  await seedAccounts(connection);
  api = await startServer();

  for (const role of ['owner', 'staff']) {
    tokens[role] = (await signIn(api, `${role}@test.local`)).body.accessToken;
  }

  bankId = await accountId(connection, 'Winibex bank');
  cashId = await accountId(connection, 'Office cash');
  outCategory = await categoryId(connection, 'out');
  inCategory = await categoryId(connection, 'in');

  await post({ direction: 'in', gross: 50000000, description: 'Client payment from Acme', date: '2026-07-02' });
  await post({ direction: 'out', gross: 9000000, description: 'Office rent July', date: '2026-07-05' });
  await post({ direction: 'out', gross: 560000, description: 'Claude subscription', date: '2026-07-06' });

  // Cash has to be in the tin before anything can be paid out of it. The
  // database refuses cash below zero, which is why this entry exists.
  await post({ direction: 'in', gross: 1000000, description: 'Cash drawn for the office', date: '2026-07-06', accountId: cashId });
  await post({ direction: 'out', gross: 250000, description: 'Tea and biscuits', date: '2026-07-07', accountId: cashId });
});

after(async () => {
  await api?.close();
  if (connection) {
    await dropAll(connection);
    await connection.end();
  }
});

async function create({ direction, gross, description, date, account = null, token = tokens.owner }) {
  const response = await api.post('/transactions', {
    token,
    headers: idempotencyKey(),
    body: {
      date, direction, method: 'account', description,
      categoryId: direction === 'in' ? inCategory : outCategory,
      accountId: account ?? bankId,
      gross: { minor: gross, currency: 'PKR' },
      acknowledged_warnings: WARNING_CODES,
    },
  });
  assert.equal(response.status, 201, response.raw);
  return response.body.transaction.id;
}

async function post({ direction, gross, description, date, accountId: account }) {
  const id = await create({ direction, gross, description, date, account });
  await api.post(`/transactions/${id}/approve`, { token: tokens.owner, headers: idempotencyKey() });
  return id;
}

// ---------------------------------------------------------------------------
// The ledger
// ---------------------------------------------------------------------------

test('the ledger comes back newest first, with what each row is', async () => {
  const response = await api.get('/transactions', { token: tokens.owner });

  assert.equal(response.status, 200);
  assert.equal(response.body.transactions.length, 5);
  assert.equal(response.body.total, 5);

  const first = response.body.transactions[0];
  assert.equal(first.description, 'Tea and biscuits', 'the most recent entry leads');
  assert.ok(first.journalNumber);
  assert.equal(first.accountName, 'Office cash');
  assert.ok(first.categoryName);
  assert.equal(first.amount.currency, 'PKR');
});

test('search looks across every row, not the page in front of you', async () => {
  const response = await api.get('/transactions?search=rent', { token: tokens.owner });

  assert.equal(response.body.total, 1);
  assert.equal(response.body.transactions[0].description, 'Office rent July');
});

test('a journal number is searchable, which is how an auditor asks for an entry', async () => {
  const all = await api.get('/transactions', { token: tokens.owner });
  const number = all.body.transactions[0].journalNumber;

  const response = await api.get(`/transactions?search=${encodeURIComponent(number)}`, {
    token: tokens.owner,
  });
  assert.equal(response.body.total, 1);
});

test('filters narrow by account, direction and date', async () => {
  const byAccount = await api.get(`/transactions?accountId=${cashId}`, { token: tokens.owner });
  assert.equal(byAccount.body.total, 2, 'the drawing and the spending both sit on the cash account');

  const byDirection = await api.get('/transactions?direction=out', { token: tokens.owner });
  assert.equal(byDirection.body.total, 3);

  const byDate = await api.get('/transactions?from=2026-07-06&to=2026-07-07', { token: tokens.owner });
  assert.equal(byDate.body.total, 3);
});

test('paging reports what is left rather than making the app guess', async () => {
  const first = await api.get('/transactions?pageSize=2&page=1', { token: tokens.owner });

  assert.equal(first.body.transactions.length, 2);
  assert.equal(first.body.total, 5);
  assert.equal(first.body.hasMore, true);

  const last = await api.get('/transactions?pageSize=2&page=3', { token: tokens.owner });
  assert.equal(last.body.hasMore, false);

  const second = await api.get('/transactions?pageSize=2&page=2', { token: tokens.owner });
  const ids = [
    ...first.body.transactions,
    ...second.body.transactions,
    ...last.body.transactions,
  ].map((row) => row.id);
  assert.equal(new Set(ids).size, 5, 'a row appeared on two pages or was skipped');
});

test('a draft is private to whoever created it', async () => {
  await create({
    direction: 'out', gross: 100000, description: 'Staff draft, not submitted',
    date: '2026-07-08', token: tokens.staff,
  });

  const mine = await api.get('/transactions?search=Staff draft', { token: tokens.staff });
  assert.equal(mine.body.total, 1);

  const theirs = await api.get('/transactions?search=Staff draft', { token: tokens.owner });
  assert.equal(theirs.body.total, 0, 'an unsubmitted draft is private until it is submitted');
});

test('a reversed entry says so, and so does its reversal', async () => {
  const id = await post({ direction: 'out', gross: 75000, description: 'Paid twice by mistake', date: '2026-07-09' });
  await api.post(`/transactions/${id}/reverse`, {
    token: tokens.owner, headers: idempotencyKey(), body: { reason: 'duplicate' },
  });

  const response = await api.get('/transactions?search=Paid twice', { token: tokens.owner });
  const original = response.body.transactions.find((row) => row.id === id);
  assert.equal(original.status, 'reversed');
  assert.equal(original.isReversed, true);

  const reversal = await api.get('/transactions?search=Reversal', { token: tokens.owner });
  assert.ok(reversal.body.transactions.some((row) => row.isReversal));
});

// ---------------------------------------------------------------------------
// The approval inbox
// ---------------------------------------------------------------------------

test('the inbox holds what is waiting, oldest first', async () => {
  const first = await create({
    direction: 'out', gross: 300000, description: 'Waiting since this morning',
    date: '2026-07-10', token: tokens.staff,
  });
  await api.post(`/transactions/${first}/submit`, { token: tokens.staff });

  const second = await create({
    direction: 'out', gross: 400000, description: 'Waiting since this afternoon',
    date: '2026-07-10', token: tokens.staff,
  });
  await api.post(`/transactions/${second}/submit`, { token: tokens.staff });

  const response = await api.get('/approvals', { token: tokens.owner });

  assert.equal(response.status, 200);
  assert.equal(response.body.approvals.length, 2);
  assert.equal(response.body.approvals[0].id, first, 'an entry waiting longer comes first');
  assert.ok(response.body.approvals[0].createdByName);
  assert.ok(response.body.approvals[0].submittedAt);
});

test('the inbox says which entries are your own', async () => {
  const mine = await create({
    direction: 'out', gross: 120000, description: 'Entered by the owner',
    date: '2026-07-10', token: tokens.owner,
  });
  await api.post(`/transactions/${mine}/submit`, { token: tokens.owner });

  const response = await api.get('/approvals', { token: tokens.owner });
  const row = response.body.approvals.find((item) => item.id === mine);

  assert.equal(row.isOwnEntry, true, 'nobody approves their own entry under the same login');
  assert.ok(response.body.approvals.some((item) => item.isOwnEntry === false));
});

test('an approved entry leaves the inbox', async () => {
  const before = await api.get('/approvals', { token: tokens.owner });
  const target = before.body.approvals.find((item) => !item.isOwnEntry);

  await api.post(`/transactions/${target.id}/approve`, {
    token: tokens.owner, headers: idempotencyKey(),
  });

  const after = await api.get('/approvals', { token: tokens.owner });
  assert.ok(!after.body.approvals.some((item) => item.id === target.id));
});

// ---------------------------------------------------------------------------
// The review list
// ---------------------------------------------------------------------------

test('flags carry the entry they are about, not just a code', async () => {
  const response = await api.get('/flags', { token: tokens.owner });

  assert.equal(response.status, 200);
  assert.ok(response.body.flags.length > 0, 'every entry so far has had no receipt');

  const flag = response.body.flags[0];
  assert.ok(flag.code);
  assert.ok(flag.transaction.description, 'a flag with no entry behind it cannot be reviewed');
  assert.ok(flag.transaction.amount.minor > 0);
});

test('acknowledged warnings record who confirmed them', async () => {
  const response = await api.get('/flags?severity=warning', { token: tokens.owner });

  if (response.body.flags.length > 0) {
    assert.ok(
      response.body.flags.every((flag) => flag.acknowledgedByName),
      'a confirmation nobody is named on is not a confirmation',
    );
  }
});

test('all three need a login', async () => {
  assert.equal((await api.get('/transactions')).status, 401);
  assert.equal((await api.get('/approvals')).status, 401);
  assert.equal((await api.get('/flags')).status, 401);
});
