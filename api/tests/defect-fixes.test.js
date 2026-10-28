// Defects found while writing docs/PHASE1-TEST.md, one test each, so none of
// them can come back. Batch 1 is the server checks, decision 057. Batch 2 is
// the review list, decision 056.
//
//   D1   "No receipt" is raised only where a receipt is expected, and clears
//        itself when the receipt arrives
//   D2   the owner or an admin can mark a flag reviewed, with a reason
//   D5   the rate-deviation warning gives the real percentage and fires
//   D6   a transfer with no fee is not warned against its own first leg
//   D7   withholding from a vendor with no NTN or CNIC is refused
//   D8   a duplicate cheque number is a 409, not a 500
//   D9   "today" is Pakistan's date, not UTC's
//   D11  dashboard In and Out count only money crossing the company's accounts
//   D12  journal lines come back with their ledger code and name
//   D14  an unusual-amount warning survives an average with a fraction of a paisa
//   F6   the approval inbox carries every field of a ledger row, status included
//   F7   a changed entry under its old key is refused, never posted with the old figures
//   F5   a tax line is checked against its tax: on, in force, right direction, not above its base
//   F2   foreign amount x rate must agree with the rupees, within one rupee
//   062  withholding needs a vendor; rejecting clears the entry's flags
//
// Every entry is dated today in Pakistan, except the opening entry, so the
// whole file sits inside the current month and the dashboard can be checked
// against cash held.

import test, { before, after } from 'node:test';
import assert from 'node:assert/strict';

import {
  connect, dropAll, buildSchema, seedUsers, seedAccounts,
  startServer, signIn, accountId, userId, idempotencyKey,
} from './helpers/api.js';
import { businessDate, businessToday, addDays } from '../core/dates.js';
import { percentApart, WARNING_CODES } from '../modules/transactions/validation.js';

const OPENING_BANK = 50000000;   // PKR 500,000
const OPENING_CASH = 5000000;    // PKR 50,000

let connection;
let api;
const tokens = {};
let today;
let bankId;
let cashId;
let pettyId;
let staffId;
let outCategories;
let inCategory;
let withholdingTaxId;

const pkr = (minor) => ({ minor, currency: 'PKR' });

// Money-out and money-in categories a person could pick, leaving out the
// system ones (transfers, opening equity, reimbursements). Each test takes its
// own, so one test's entries never change another's category average.
async function pickableCategories(direction) {
  const [rows] = await connection.query(
    `SELECT c.id FROM categories c JOIN chart_of_accounts a ON a.id = c.coa_id
      WHERE c.direction = ? AND c.is_active = 1
        AND a.code NOT IN ('1118', '3400', '2114')
      ORDER BY c.id`,
    [direction],
  );
  return rows.map((row) => Number(row.id));
}

function entry(overrides = {}) {
  return {
    date: today,
    direction: 'out',
    method: 'online',
    description: 'Defect test entry',
    categoryId: outCategories[0],
    accountId: bankId,
    gross: pkr(100000),
    ...overrides,
  };
}

async function create(body, token = tokens.owner) {
  return api.post('/transactions', { token, headers: idempotencyKey(), body });
}

async function createAndPost(body) {
  const created = await create(body);
  assert.equal(created.status, 201, created.raw);
  const posted = await api.post(`/transactions/${created.body.transaction.id}/approve`, {
    token: tokens.owner, headers: idempotencyKey(),
  });
  assert.equal(posted.status, 200, posted.raw);
  return created.body.transaction.id;
}

async function dashboard() {
  const response = await api.get('/dashboard', { token: tokens.owner });
  assert.equal(response.status, 200, response.raw);
  return response.body;
}

before(async () => {
  connection = await connect();
  await buildSchema(connection);
  await seedUsers(connection);
  await seedAccounts(connection);
  api = await startServer();

  for (const role of ['owner', 'staff']) {
    tokens[role] = (await signIn(api, `${role}@test.local`)).body.accessToken;
  }

  today = businessToday();
  bankId = await accountId(connection, 'Winibex bank');
  cashId = await accountId(connection, 'Office cash');
  pettyId = await accountId(connection, 'Petty cash');
  staffId = await userId(connection, 'staff@test.local');
  outCategories = await pickableCategories('out');
  [inCategory] = await pickableCategories('in');
  assert.ok(outCategories.length >= 4, 'the seed needs at least four money-out categories');
  assert.ok(inCategory, 'the seed needs a money-in category');

  // A withholding tax, which the seed deliberately leaves out (decision 046).
  await connection.query(
    `INSERT INTO taxes (name, short_code, authority, kind, applies_to, computation,
                        rate_atl, rate_non_atl, status_basis, coa_id, effective_from)
     SELECT 'Test withholding', 'T-153', 'fbr', 'withholding', 'purchases', 'percent',
            4.0000, 8.0000, 'counterparty', id, '2026-07-01'
       FROM chart_of_accounts WHERE code = '2132'`,
  );
  const [taxes] = await connection.query(`SELECT id FROM taxes WHERE short_code = 'T-153'`);
  withholdingTaxId = Number(taxes[0].id);

  // The books open on 1 July with money in the bank and the cash tin. This is
  // the only entry outside the current month.
  const opening = await api.post('/opening-entry', {
    token: tokens.owner,
    headers: idempotencyKey(),
    body: {
      balances: [
        { code: '1113', amount: OPENING_BANK },
        { code: '1111', amount: OPENING_CASH },
      ],
    },
  });
  assert.equal(opening.status, 201, opening.raw);
});

after(async () => {
  await api?.close();
  if (connection) {
    await dropAll(connection);
    await connection.end();
  }
});

// --- D9 -----------------------------------------------------------------------

test('D9: the business date is Pakistan\'s, which is ahead of UTC after 19:00 UTC', () => {
  assert.equal(businessDate(new Date('2026-10-19T18:59:59Z')), '2026-10-19');
  assert.equal(businessDate(new Date('2026-10-19T19:00:00Z')), '2026-10-20', '00:00 in Karachi');
  assert.equal(businessDate(new Date('2026-10-19T20:30:00Z')), '2026-10-20', '01:30 in Karachi');
  assert.equal(businessDate(new Date('2026-12-31T19:30:00Z')), '2027-01-01', 'new year in Karachi first');
});

test('D9: today in Pakistan is accepted and tomorrow in Pakistan is refused', async () => {
  const todays = await create(entry({ description: 'Dated today in Pakistan', gross: pkr(110000) }));
  assert.equal(todays.status, 201, todays.raw);

  const tomorrows = await create(entry({
    date: addDays(today, 1), description: 'Dated tomorrow in Pakistan', gross: pkr(120000),
  }));
  assert.equal(tomorrows.status, 400, tomorrows.raw);
  assert.equal(tomorrows.body.error.code, 'FUTURE_DATE');
});

// --- D5 -----------------------------------------------------------------------

test('D5: the percentage between two rates is the real one', () => {
  assert.equal(percentApart('300', '280.500000'), 6.95);
  assert.equal(percentApart('280', '300'), 6.67);
  assert.equal(percentApart('290', '280.5'), 3.39);
  assert.equal(percentApart('280.5', '280.5'), 0);
  assert.equal(percentApart('not a rate', '280'), null);
  assert.equal(percentApart('300', '0'), null);
});

test('D5: a rate 6.95% away from the last one is warned, naming the real percentage', async () => {
  await createAndPost(entry({
    direction: 'in', categoryId: inCategory, method: 'account',
    description: 'Export invoice at 280.50',
    foreign: { minor: 50000, currency: 'USD' }, fxRate: '280.50', gross: pkr(14025000),
  }));

  const far = await create(entry({
    direction: 'in', categoryId: inCategory, method: 'account',
    description: 'Export invoice at 300',
    foreign: { minor: 10000, currency: 'USD' }, fxRate: '300', gross: pkr(3000000),
  }));
  assert.equal(far.status, 409, far.raw);
  const warning = far.body.error.details.warnings.find((item) => item.code === 'RATE_DEVIATION');
  assert.ok(warning, 'a 6.95% jump must be warned');
  assert.match(warning.message, /6\.95% away from 280\.5/);

  const near = await create(entry({
    direction: 'in', categoryId: inCategory, method: 'account',
    description: 'Export invoice at 290',
    foreign: { minor: 10000, currency: 'USD' }, fxRate: '290', gross: pkr(2900000),
  }));
  assert.equal(near.status, 201, `3.39% is under the 5% setting: ${near.raw}`);
});

// --- D6 -----------------------------------------------------------------------

test('D6: a transfer with no fee goes through without warning about itself', async () => {
  const transfer = await api.post('/transfers', {
    token: tokens.owner,
    headers: idempotencyKey(),
    body: {
      date: today, fromAccountId: cashId, toAccountId: pettyId,
      amount: pkr(500000), description: 'Petty cash top up',
    },
  });
  assert.equal(transfer.status, 201, transfer.raw);
});

test('D6: a second identical transfer is still warned, so the duplicate check works', async () => {
  const again = await api.post('/transfers', {
    token: tokens.owner,
    headers: idempotencyKey(),
    body: {
      date: today, fromAccountId: cashId, toAccountId: pettyId,
      amount: pkr(500000), description: 'Petty cash top up',
    },
  });
  assert.equal(again.status, 409, again.raw);
  const codes = again.body.error.details.warnings.map((item) => item.code);
  assert.ok(codes.includes('POSSIBLE_DUPLICATE'), `got ${codes.join(', ')}`);
});

// --- D7 -----------------------------------------------------------------------

async function vendor(body) {
  const response = await api.post('/vendors', { token: tokens.owner, body });
  assert.equal(response.status, 201, response.raw);
  return response.body.vendor.id;
}

function withheldFrom(vendorId, description) {
  return entry({
    description,
    categoryId: outCategories[1],
    vendorId,
    gross: pkr(1000000),
    taxes: [{
      taxId: withholdingTaxId,
      baseAmount: pkr(1000000),
      rateApplied: '8.0000',
      atlStatusUsed: 'non_atl',
      atlParty: 'vendor',
      amount: pkr(80000),
      deductedBy: 'us',
    }],
  });
}

test('D7: withholding from a vendor with no NTN and no CNIC is refused', async () => {
  const noId = await vendor({ name: 'No ID Freelancer', kind: 'individual', atlStatus: 'unknown' });

  const response = await create(withheldFrom(noId, 'Logo design, no tax ID'));
  assert.equal(response.status, 400, response.raw);
  assert.equal(response.body.error.code, 'MISSING_VENDOR_TAX_ID');

  const [rows] = await connection.query(
    `SELECT COUNT(*) AS n FROM transactions WHERE description = 'Logo design, no tax ID'`,
  );
  assert.equal(Number(rows[0].n), 0, 'nothing may be written');
});

test('D7: withholding from a vendor with a CNIC goes through', async () => {
  const withCnic = await vendor({
    name: 'Contractor With CNIC', kind: 'individual', cnic: '35202-1234567-1', atlStatus: 'unknown',
  });

  const response = await create(withheldFrom(withCnic, 'App module, contractor with CNIC'));
  assert.equal(response.status, 201, response.raw);
  assert.equal(response.body.transaction.withheldTotal, 80000);
  assert.equal(response.body.transaction.amount, 920000, 'only the net leaves the bank');
});

// --- D8 -----------------------------------------------------------------------

test('D8: a cheque number used twice on one account is a clear 409', async () => {
  const cheque = {
    accountId: bankId, chequeNumber: 'T-000101', payee: 'Test Landlord',
    amount: pkr(4500000), issueDate: today,
  };
  const first = await api.post('/cheques', { token: tokens.owner, body: cheque });
  assert.equal(first.status, 201, first.raw);

  const second = await api.post('/cheques', {
    token: tokens.owner, body: { ...cheque, payee: 'Someone else' },
  });
  assert.equal(second.status, 409, second.raw);
  assert.equal(second.body.error.code, 'ALREADY_EXISTS');

  const register = await api.get(`/cheques?accountId=${bankId}`, { token: tokens.owner });
  const matching = register.body.cheques.filter((item) => item.chequeNumber === 'T-000101');
  assert.equal(matching.length, 1, 'the database kept only one');
});

// --- D12 ----------------------------------------------------------------------

test('D12: journal lines come back with their ledger code and name', async () => {
  const id = await createAndPost(entry({ description: 'Journal panel check', gross: pkr(130000) }));

  const response = await api.get(`/transactions/${id}/journal`, { token: tokens.owner });
  assert.equal(response.status, 200, response.raw);
  assert.equal(response.body.lines.length, 2);
  for (const line of response.body.lines) {
    assert.match(String(line.code), /^\d{4}$/, 'a four-digit ledger code');
    assert.ok(String(line.name ?? '').length > 0, 'a ledger name');
  }
  assert.ok(response.body.lines.some((line) => line.code === '1113'), 'the bank line is 1113');
});

// --- D14 ----------------------------------------------------------------------

test('D14: an unusual amount is warned even when the usual one has a fraction of a paisa', async () => {
  const category = outCategories[2];
  // 1,000.00, 1,000.01 and 1,000.03 average 1,000.0133: not a whole paisa.
  await createAndPost(entry({ categoryId: category, description: 'Stationery one', gross: pkr(100000) }));
  await createAndPost(entry({ categoryId: category, description: 'Stationery two', gross: pkr(100001) }));
  await createAndPost(entry({ categoryId: category, description: 'Stationery three', gross: pkr(100003) }));

  const big = await create(entry({ categoryId: category, description: 'Stationery, a lot', gross: pkr(600000) }));
  assert.equal(big.status, 409, `not a 500: ${big.raw}`);
  const warning = big.body.error.details.warnings.find((item) => item.code === 'UNUSUAL_AMOUNT');
  assert.ok(warning);
  assert.match(warning.message, /averages PKR 1,000 over 3 entries/);
});

// --- D11 ----------------------------------------------------------------------

test('D11: a transfer counts only its bank fee as money out', async () => {
  const before = await dashboard();

  const transfer = await api.post('/transfers', {
    token: tokens.owner,
    headers: idempotencyKey(),
    body: {
      date: today, fromAccountId: bankId, toAccountId: cashId,
      amount: pkr(1000000), fee: pkr(5000), description: 'Cash withdrawal',
    },
  });
  assert.equal(transfer.status, 201, transfer.raw);

  const after = await dashboard();
  assert.equal(after.monthIn.minor - before.monthIn.minor, 0, 'nothing came in');
  assert.equal(after.monthOut.minor - before.monthOut.minor, 5000, 'only the PKR 50 fee left');
});

test('D11: reversing money in lowers In and leaves Out alone', async () => {
  const id = await createAndPost(entry({
    direction: 'in', categoryId: inCategory, method: 'account',
    description: 'Client advance, to be reversed', gross: pkr(2500000),
  }));
  const before = await dashboard();

  const reversed = await api.post(`/transactions/${id}/reverse`, {
    token: tokens.owner, headers: idempotencyKey(), body: { reason: 'Wrong client' },
  });
  assert.equal(reversed.status, 200, reversed.raw);

  const after = await dashboard();
  assert.equal(after.monthIn.minor - before.monthIn.minor, -2500000);
  assert.equal(after.monthOut.minor - before.monthOut.minor, 0);
});

test('D11: a cost paid on a personal card is not money out until it is paid back', async () => {
  const before = await dashboard();

  await createAndPost(entry({
    accountId: null, paidByType: 'person', paidByUserId: staffId,
    categoryId: outCategories[3], description: 'Subscription on a personal card', gross: pkr(595300),
  }));
  const afterCost = await dashboard();
  assert.equal(afterCost.monthOut.minor, before.monthOut.minor, 'no company account moved');

  const owed = await api.get(`/people/${staffId}/outstanding`, { token: tokens.owner });
  assert.equal(owed.status, 200, owed.raw);
  const repaid = await api.post('/reimbursements', {
    token: tokens.owner,
    headers: idempotencyKey(),
    body: {
      personUserId: staffId, accountId: bankId, date: today, note: 'Paid back',
      items: [{ transactionId: owed.body.items[0].transactionId, amount: pkr(595300) }],
    },
  });
  assert.equal(repaid.status, 201, repaid.raw);

  const afterRepay = await dashboard();
  assert.equal(afterRepay.monthOut.minor - afterCost.monthOut.minor, 595300, 'the repayment left the bank');
});

test('D11: cash at the start of the month plus In minus Out is cash held now', async () => {
  // Everything above is dated this month except the opening entry, so the
  // cash the month started with is exactly what the books opened with.
  const now = await dashboard();
  const startOfMonth = OPENING_BANK + OPENING_CASH;
  assert.equal(
    startOfMonth + now.monthIn.minor - now.monthOut.minor,
    now.cashHeld.minor,
    `start ${startOfMonth}, in ${now.monthIn.minor}, out ${now.monthOut.minor}, held ${now.cashHeld.minor}`,
  );
});

// --- D1 -----------------------------------------------------------------------

test('D1: money in, transfers, reimbursements and the opening entry carry no "No receipt" flag', async () => {
  // The tests above created each kind, so this is not a check on nothing.
  const [kinds] = await connection.query(
    `SELECT
        SUM(t.direction = 'in' AND t.transfer_group_id IS NULL AND t.entry_type = 'normal') AS money_in,
        SUM(t.transfer_group_id IS NOT NULL) AS transfer_legs,
        SUM(t.entry_type = 'opening') AS opening,
        SUM(a.code = '2114') AS reimbursements
       FROM transactions t
       JOIN categories c ON c.id = t.category_id
       JOIN chart_of_accounts a ON a.id = c.coa_id`,
  );
  for (const [kind, count] of Object.entries(kinds[0])) {
    assert.ok(Number(count) > 0, `no ${kind} entry exists to check`);
  }

  const [wrong] = await connection.query(
    `SELECT t.id, t.description
       FROM entry_flags f
       JOIN transactions t ON t.id = f.transaction_id
       JOIN categories c ON c.id = t.category_id
       JOIN chart_of_accounts a ON a.id = c.coa_id
      WHERE f.code = 'NO_RECEIPT'
        AND (t.direction = 'in' OR t.transfer_group_id IS NOT NULL
             OR t.entry_type <> 'normal' OR a.code IN ('2114', '1118'))`,
  );
  assert.deepEqual(wrong, [], 'these entries never need a receipt');
});

async function flagsOn(transactionId) {
  const [rows] = await connection.query(
    `SELECT id, code, resolved, resolved_by, resolution_note FROM entry_flags
      WHERE transaction_id = ? ORDER BY id`,
    [transactionId],
  );
  return rows;
}

let inkId;

test('D1: a payment is flagged until its receipt arrives, then the flag clears itself', async () => {
  const created = await create(entry({ description: 'Printer ink, receipt to follow', gross: pkr(200000) }));
  assert.equal(created.status, 201, created.raw);
  inkId = created.body.transaction.id;

  const flag = (await flagsOn(inkId)).find((row) => row.code === 'NO_RECEIPT');
  assert.ok(flag, 'an ordinary payment with nothing attached is flagged');
  assert.equal(Number(flag.resolved), 0);

  const before = await dashboard();
  const uploaded = await api.upload(`/transactions/${inkId}/attachments`, {
    token: tokens.owner, file: Buffer.from('receipt'), filename: 'ink.png', mime: 'image/png',
  });
  assert.equal(uploaded.status, 201, uploaded.raw);

  const after = (await flagsOn(inkId)).find((row) => row.code === 'NO_RECEIPT');
  assert.equal(Number(after.resolved), 1);
  assert.equal(after.resolved_by, null, 'nobody resolved it; the receipt did');
  assert.equal(after.resolution_note, 'Receipt attached');
  assert.equal((await dashboard()).openFlagCount, before.openFlagCount - 1);

  const resolved = await api.get('/flags?resolved=true', { token: tokens.owner });
  const listed = resolved.body.flags.find((item) => item.id === Number(flag.id));
  assert.ok(listed, 'a resolved flag is kept and can be listed');
  assert.equal(listed.resolvedAutomatically, true);
  assert.equal(listed.resolutionNote, 'Receipt attached');
});

test('D1: editing a draft that already has its receipt does not flag it again', async () => {
  const edited = await api.patch(`/transactions/${inkId}`, {
    token: tokens.owner,
    body: entry({ description: 'Printer ink, two cartridges', gross: pkr(200000) }),
  });
  assert.equal(edited.status, 200, edited.raw);

  const codes = (await flagsOn(inkId)).map((row) => row.code);
  assert.ok(!codes.includes('NO_RECEIPT'), `got ${codes.join(', ')}`);
});

// --- D2 -----------------------------------------------------------------------

let teaFlagId;

test('D2: staff cannot mark a flag reviewed', async () => {
  const created = await create(entry({ description: 'tea', gross: pkr(30000) }));
  assert.equal(created.status, 201, created.raw);
  const flag = (await flagsOn(created.body.transaction.id)).find((row) => row.code === 'THIN_DESCRIPTION');
  assert.ok(flag);
  teaFlagId = Number(flag.id);

  const response = await api.post(`/flags/${teaFlagId}/resolve`, {
    token: tokens.staff, body: { note: 'Looks fine to me' },
  });
  assert.equal(response.status, 403, response.raw);
});

test('D2: marking reviewed needs a reason', async () => {
  const response = await api.post(`/flags/${teaFlagId}/resolve`, {
    token: tokens.owner, body: { note: 'ok' },
  });
  assert.equal(response.status, 400, response.raw);
});

test('D2: the owner marks a flag reviewed, and it leaves the open list but is kept', async () => {
  const before = await dashboard();

  const response = await api.post(`/flags/${teaFlagId}/resolve`, {
    token: tokens.owner, body: { note: 'Office tea for the team, nothing more to say' },
  });
  assert.equal(response.status, 200, response.raw);
  assert.equal(response.body.flag.resolved, true);
  assert.equal(response.body.flag.resolvedAutomatically, false);
  assert.equal(response.body.flag.resolvedByName, 'Winibex office');
  assert.equal(response.body.flag.resolutionNote, 'Office tea for the team, nothing more to say');
  assert.ok(response.body.flag.resolvedAt);

  assert.equal((await dashboard()).openFlagCount, before.openFlagCount - 1);

  const open = await api.get('/flags', { token: tokens.owner });
  assert.ok(!open.body.flags.some((item) => item.id === teaFlagId));
  const resolved = await api.get('/flags?resolved=true', { token: tokens.owner });
  assert.ok(resolved.body.flags.some((item) => item.id === teaFlagId));

  const [audit] = await connection.query(
    `SELECT COUNT(*) AS n FROM audit_log WHERE table_name = 'entry_flags' AND record_id = ?`,
    [teaFlagId],
  );
  assert.equal(Number(audit[0].n), 1, 'who resolved it and why is in the audit log');
});

test('D2: a flag already dealt with cannot be resolved twice', async () => {
  const response = await api.post(`/flags/${teaFlagId}/resolve`, {
    token: tokens.owner, body: { note: 'Second attempt' },
  });
  assert.equal(response.status, 409, response.raw);
});

test('D2: a flag that does not exist is a 404', async () => {
  const response = await api.post('/flags/999999/resolve', {
    token: tokens.owner, body: { note: 'Nothing to resolve' },
  });
  assert.equal(response.status, 404, response.raw);
});

// --- F6 -----------------------------------------------------------------------
// Found in the full Phase 1 test, not while writing it. The inbox rows are
// ledger rows plus who and when, and the app reads them with the same parser
// as the ledger. A missing field broke the whole screen, so every field the
// ledger sends is checked here, not only the one that was missing.

test('F6: the approval inbox carries every field of a ledger row, status included', async () => {
  const created = await create(
    entry({ description: 'Courier for signed contract', gross: pkr(90000) }),
    tokens.staff,
  );
  assert.equal(created.status, 201, created.raw);
  const id = created.body.transaction.id;

  const submitted = await api.post(`/transactions/${id}/submit`, { token: tokens.staff });
  assert.equal(submitted.status, 200, submitted.raw);

  const inbox = await api.get('/approvals', { token: tokens.owner });
  assert.equal(inbox.status, 200, inbox.raw);
  const row = inbox.body.approvals.find((item) => item.id === id);
  assert.ok(row, 'the submitted entry is in the inbox');

  assert.equal(row.status, 'pending');
  assert.equal(row.journalNumber, null);
  assert.equal(row.isReversed, false);
  assert.equal(row.isReversal, false);
  assert.equal(row.isOwnEntry, false);
  assert.ok(row.createdByName, 'who entered it is named');

  const ledger = await api.get(`/transactions?status=pending`, { token: tokens.owner });
  const ledgerRow = ledger.body.transactions.find((item) => item.id === id);
  assert.ok(ledgerRow);
  for (const key of Object.keys(ledgerRow)) {
    assert.ok(key in row, `the inbox row has ${key}, as the ledger row does`);
  }

  const theirs = await api.get('/approvals', { token: tokens.staff });
  assert.equal(theirs.status, 200, theirs.raw);
  assert.equal(theirs.body.approvals.find((item) => item.id === id).isOwnEntry, true);
});

// --- F7 -----------------------------------------------------------------------
// Found on the last step of the full Phase 1 test. A posting was refused for a
// missing receipt, the amount was changed from 6,000 to 6,500, and the second
// save under the same key was answered with the first draft, which was then
// posted at 6,000. Decision 059.

test('F7: the same key with a changed amount is refused, and nothing new is saved', async () => {
  const headers = idempotencyKey();
  const body = entry({ description: 'Limit test, same key', gross: pkr(600000),
    acknowledged_warnings: WARNING_CODES });

  const first = await api.post('/transactions', { token: tokens.owner, headers, body });
  assert.equal(first.status, 201, first.raw);

  const [before] = await connection.query('SELECT COUNT(*) AS n FROM transactions');

  const changed = await api.post('/transactions', {
    token: tokens.owner, headers, body: { ...body, gross: pkr(650000) },
  });
  assert.equal(changed.status, 409, changed.raw);
  assert.equal(changed.body.error.code, 'IDEMPOTENCY_KEY_REUSED');

  const [after] = await connection.query('SELECT COUNT(*) AS n FROM transactions');
  assert.equal(Number(after[0].n), Number(before[0].n), 'the changed request created something');

  const [rows] = await connection.query('SELECT amount FROM transactions WHERE id = ?', [first.body.transaction.id]);
  assert.equal(Number(rows[0].amount), 600000, 'the first draft was left as it was');
});

test('F7: the same key with the same body still replays the first answer', async () => {
  const headers = idempotencyKey();
  const body = entry({ description: 'Limit test, true repeat', gross: pkr(70000),
    acknowledged_warnings: WARNING_CODES });

  const first = await api.post('/transactions', { token: tokens.owner, headers, body });
  const again = await api.post('/transactions', { token: tokens.owner, headers, body });

  assert.equal(first.status, 201, first.raw);
  assert.equal(again.status, 201, again.raw);
  assert.equal(again.body.transaction.id, first.body.transaction.id);
});

test('F7: a changed draft is saved by editing it, and posts with the new figures', async () => {
  const body = entry({ description: 'Limit test, edited draft', gross: pkr(600000),
    acknowledged_warnings: WARNING_CODES });
  const created = await create(body);
  assert.equal(created.status, 201, created.raw);
  const id = created.body.transaction.id;

  const edited = await api.patch(`/transactions/${id}`, {
    token: tokens.owner, body: { ...body, gross: pkr(650000) },
  });
  assert.equal(edited.status, 200, edited.raw);

  const posted = await api.post(`/transactions/${id}/approve`, {
    token: tokens.owner, headers: idempotencyKey(),
  });
  assert.equal(posted.status, 200, posted.raw);

  const [rows] = await connection.query('SELECT amount, status FROM transactions WHERE id = ?', [id]);
  assert.equal(Number(rows[0].amount), 650000);
  assert.equal(rows[0].status, 'posted');
});

// --- F5 -----------------------------------------------------------------------
// Found in the full Phase 1 test: nothing checked a tax line against the tax
// it named. UI-GUIDE lists every one of these as blocking.

// Taken by the bank, not withheld by Winibex, so these tests are about the tax
// checks alone and not about the vendor rule of decision 062.
function taxLine(taxId, { base = 1000000, amount = 40000, deductedBy = 'bank', party = 'company' } = {}) {
  return {
    taxId, baseAmount: pkr(base), rateApplied: '4.0000', atlStatusUsed: 'atl',
    atlParty: party, amount: pkr(amount), deductedBy,
  };
}

async function extraTax({ code, appliesTo = 'purchases', from = '2026-07-01', to = null, active = 1 }) {
  await connection.query(
    `INSERT INTO taxes (name, short_code, authority, kind, applies_to, computation,
                        rate_atl, rate_non_atl, status_basis, coa_id, effective_from, effective_to, is_active)
     SELECT ?, ?, 'fbr', 'withholding', ?, 'percent', 4.0000, 8.0000, 'counterparty', id, ?, ?, ?
       FROM chart_of_accounts WHERE code = '2132'`,
    [`Test tax ${code}`, code, appliesTo, from, to, active],
  );
  const [rows] = await connection.query('SELECT id FROM taxes WHERE short_code = ?', [code]);
  return Number(rows[0].id);
}

async function expectRefused(body, code) {
  const response = await create({ ...body, acknowledged_warnings: WARNING_CODES });
  assert.equal(response.status, 400, response.raw);
  assert.equal(response.body.error.code, code);
  return response.body.error.message;
}

test('F5: a tax that is switched off is refused, by name', async () => {
  const id = await extraTax({ code: 'T-OFF', active: 0 });
  const message = await expectRefused(
    entry({ description: 'Tax switched off', gross: pkr(1000000), taxes: [taxLine(id)] }),
    'TAX_INACTIVE',
  );
  assert.match(message, /T-OFF/);
});

test('F5: a tax not yet in force on the entry date is refused, with its dates', async () => {
  const id = await extraTax({ code: 'T-LATER', from: addDays(today, 30) });
  const message = await expectRefused(
    entry({ description: 'Tax not yet in force', gross: pkr(1000000), taxes: [taxLine(id)] }),
    'TAX_NOT_IN_EFFECT',
  );
  assert.match(message, /was not in force on/);
});

test('F5: a tax that has ended is refused', async () => {
  const id = await extraTax({ code: 'T-ENDED', from: '2026-07-01', to: addDays(today, -1) });
  await expectRefused(
    entry({ description: 'Tax that has ended', gross: pkr(1000000), taxes: [taxLine(id)] }),
    'TAX_NOT_IN_EFFECT',
  );
});

test('F5: a tax for money coming in is refused on money going out', async () => {
  const id = await extraTax({ code: 'T-SALES', appliesTo: 'sales' });
  const message = await expectRefused(
    entry({ description: 'Sales tax on a subscription', gross: pkr(1000000),
      taxes: [taxLine(id, { deductedBy: 'bank', party: 'company' })] }),
    'TAX_WRONG_DIRECTION',
  );
  assert.match(message, /is for money coming in, and this entry is money going out/);
});

test('F5: a tax larger than the amount it is charged on is refused', async () => {
  await expectRefused(
    entry({ description: 'Tax above its base', gross: pkr(1000000),
      taxes: [taxLine(withholdingTaxId, { base: 100000, amount: 200000 })] }),
    'TAX_LARGER_THAN_BASE',
  );
});

test('F5: a tax that fits on every count goes through', async () => {
  const id = await extraTax({ code: 'T-FINE' });
  const response = await create({
    ...entry({ description: 'Tax that fits', gross: pkr(1000000), taxes: [taxLine(id)] }),
    acknowledged_warnings: WARNING_CODES,
  });
  assert.equal(response.status, 201, response.raw);
});

// --- F2 -----------------------------------------------------------------------
// Found in the full Phase 1 test: USD 500 at 280 was saved with PKR 140,250.

test('F2: rupees that do not match foreign amount x rate are refused, with the right figure', async () => {
  const message = await expectRefused(
    entry({
      direction: 'in', categoryId: inCategory, method: 'account',
      description: 'Rate and rupees disagree',
      foreign: { minor: 50000, currency: 'USD' }, fxRate: '280', gross: pkr(14025000),
    }),
    'RATE_AMOUNT_MISMATCH',
  );
  assert.equal(message, 'USD 500.00 at 280 is PKR 140,000.00, not PKR 140,250.00. Correct the rate or the rupees.');
});

test('F2: a difference of up to one rupee is accepted, for the bank rounding', async () => {
  const response = await create({
    ...entry({
      direction: 'in', categoryId: inCategory, method: 'account',
      description: 'Rate and rupees one rupee apart',
      foreign: { minor: 50000, currency: 'USD' }, fxRate: '280', gross: pkr(14000100),
    }),
    acknowledged_warnings: WARNING_CODES,
  });
  assert.equal(response.status, 201, response.raw);
});

// --- Decision 062 ---------------------------------------------------------------

test('062: withholding with no vendor named is refused', async () => {
  const response = await create({
    ...entry({
      description: 'Withheld with no payee', gross: pkr(1000000),
      taxes: [taxLine(withholdingTaxId, { deductedBy: 'us', party: 'vendor' })],
    }),
    acknowledged_warnings: WARNING_CODES,
  });
  assert.equal(response.status, 400, response.raw);
  assert.equal(response.body.error.code, 'MISSING_VENDOR_TAX_ID');
  assert.equal(response.body.error.field, 'vendorId');
});

test('062: rejecting an entry clears its open flags', async () => {
  const created = await create(
    entry({ description: 'tea', gross: pkr(25000), acknowledged_warnings: WARNING_CODES }),
    tokens.staff,
  );
  assert.equal(created.status, 201, created.raw);
  const id = created.body.transaction.id;
  await api.post(`/transactions/${id}/submit`, { token: tokens.staff });

  const [before] = await connection.query(
    'SELECT COUNT(*) AS n FROM entry_flags WHERE transaction_id = ? AND resolved = 0', [id],
  );
  assert.ok(Number(before[0].n) > 0, 'a thin description and no receipt should raise flags');

  const rejected = await api.post(`/transactions/${id}/reject`, {
    token: tokens.owner, body: { reason: 'Say what it was for' },
  });
  assert.equal(rejected.status, 200, rejected.raw);

  const [after] = await connection.query(
    `SELECT COUNT(*) AS open_flags, SUM(resolution_note = 'Entry rejected') AS cleared
       FROM entry_flags WHERE transaction_id = ?`, [id],
  );
  assert.equal(Number(after[0].open_flags) - Number(after[0].cleared), 0, 'no flag left open');
});
