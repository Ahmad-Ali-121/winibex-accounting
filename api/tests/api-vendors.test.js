// Vendors.
//
// Two fields here decide money. atl_status picks the rate on every Section 153
// line, and ntn or cnic is what the quarterly Section 165 statement reports a
// deduction under. A vendor with neither cannot be withheld from at all.

import test, { before, after } from 'node:test';
import assert from 'node:assert/strict';

import {
  connect, dropAll, buildSchema, seedUsers, seedAccounts,
  startServer, signIn,
} from './helpers/api.js';

let connection;
let api;
const tokens = {};

before(async () => {
  connection = await connect();
  await buildSchema(connection);
  await seedUsers(connection);
  await seedAccounts(connection);
  api = await startServer();

  for (const role of ['owner', 'admin', 'staff']) {
    tokens[role] = (await signIn(api, `${role}@test.local`)).body.accessToken;
  }
});

after(async () => {
  await api?.close();
  if (connection) {
    await dropAll(connection);
    await connection.end();
  }
});

function create(body, token = tokens.owner) {
  return api.post('/vendors', { token, body });
}

test('a vendor can be added with a filer status and the date it was checked', async () => {
  const response = await create({
    name: 'Filer Software House',
    kind: 'company',
    ntn: '1234567-8',
    atlStatus: 'atl',
    atlCheckedOn: new Date().toISOString().slice(0, 10),
  });

  assert.equal(response.status, 201, response.raw);
  assert.equal(response.body.vendor.atlStatus, 'atl');
  assert.equal(response.body.vendor.atlCheckIsStale, false);
  assert.equal(response.body.vendor.canBeWithheldFrom, true);
});

test('a filer status with no check date is refused, in words rather than a constraint name', async () => {
  const response = await create({
    name: 'Undated Vendor', kind: 'company', ntn: '7654321-0', atlStatus: 'atl',
  });

  assert.equal(response.status, 400);
  assert.equal(response.body.error.field, 'atlCheckedOn');
  assert.ok(/stale/i.test(response.body.error.message));
});

test('a local vendor with no NTN and no CNIC cannot be withheld from', async () => {
  const response = await create({ name: 'Nameless Contractor', kind: 'individual' });

  assert.equal(response.status, 201, 'the vendor itself is fine to record');
  assert.equal(
    response.body.vendor.canBeWithheldFrom, false,
    'there is nothing to file a deduction against',
  );
});

test('a foreign payee needs no Pakistani tax number', async () => {
  const response = await create({ name: 'Upwork Global Inc', kind: 'foreign', country: 'USA' });

  assert.equal(response.status, 201);
  assert.equal(response.body.vendor.canBeWithheldFrom, true, 'none is expected of a foreign payee');
});

test('an unchecked filer status reads as stale from the start', async () => {
  const response = await create({ name: 'Unknown Status Ltd', kind: 'company', ntn: '1111111-1' });

  assert.equal(response.body.vendor.atlStatus, 'unknown');
  assert.equal(response.body.vendor.atlCheckIsStale, true);
});

test('a filer status checked months ago reads as stale', async () => {
  const created = await create({
    name: 'Checked Long Ago', kind: 'company', ntn: '2222222-2',
    atlStatus: 'atl', atlCheckedOn: '2026-01-01',
  });

  const fetched = await api.get(`/vendors/${created.body.vendor.id}`, { token: tokens.owner });
  assert.equal(fetched.body.vendor.atlCheckIsStale, true, 'a year-old check is not a check');
});

test('two vendors cannot share a name', async () => {
  await create({ name: 'Only One Of These', kind: 'company', ntn: '3333333-3' });
  const second = await create({ name: 'Only One Of These', kind: 'company', ntn: '4444444-4' });

  assert.notEqual(second.status, 201);
});

test('staff can read vendors but not add or change them', async () => {
  const read = await api.get('/vendors', { token: tokens.staff });
  assert.equal(read.status, 200);
  assert.ok(read.body.vendors.length > 0);

  const written = await create({ name: 'Added By Staff', kind: 'company', ntn: '5555555-5' }, tokens.staff);
  assert.equal(written.status, 403);
});

test('an admin can update a filer status, and it is audited', async () => {
  const created = await create({ name: 'Status Changes', kind: 'company', ntn: '6666666-6' });
  const id = created.body.vendor.id;

  const updated = await api.patch(`/vendors/${id}`, {
    token: tokens.admin,
    body: { atlStatus: 'non_atl', atlCheckedOn: new Date().toISOString().slice(0, 10) },
  });

  assert.equal(updated.status, 200);
  assert.equal(updated.body.vendor.atlStatus, 'non_atl');

  const [audit] = await connection.query(
    `SELECT action FROM audit_log WHERE table_name = 'vendors' AND record_id = ?`, [id],
  );
  assert.ok(audit.length >= 2, 'the change to a rate-deciding field was not recorded');
});

test('vendors can be searched by name or tax number', async () => {
  const byName = await api.get('/vendors?q=Filer', { token: tokens.owner });
  assert.ok(byName.body.vendors.some((v) => v.name === 'Filer Software House'));

  const byNtn = await api.get('/vendors?q=1234567-8', { token: tokens.owner });
  assert.equal(byNtn.body.vendors.length, 1);
});

test('a deactivated vendor is hidden unless asked for, never deleted', async () => {
  const created = await create({ name: 'No Longer Used', kind: 'company', ntn: '7777777-7' });
  await api.patch(`/vendors/${created.body.vendor.id}`, {
    token: tokens.owner, body: { isActive: false },
  });

  const visible = await api.get('/vendors', { token: tokens.owner });
  const all = await api.get('/vendors?includeInactive=true', { token: tokens.owner });

  assert.ok(!visible.body.vendors.some((v) => v.name === 'No Longer Used'));
  assert.ok(all.body.vendors.some((v) => v.name === 'No Longer Used'));
});

test('vendors need a login', async () => {
  assert.equal((await api.get('/vendors')).status, 401);
});
