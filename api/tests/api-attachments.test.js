// Receipts.
//
// The file lands on disk outside the web root; the database holds the record.
// Nothing can read one without a login, and nothing is ever deleted.
// Decisions 007 and 033.

import test, { before, after } from 'node:test';
import assert from 'node:assert/strict';
import process from 'node:process';
import { mkdtemp, rm, readdir } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';

let connection;
let api;
const tokens = {};
let bankId;
let outCategory;
let uploadDir;

// A one pixel PNG. Small enough to keep in the test, real enough that the
// mime check and the hash both have something to work with.
const PNG = Buffer.from(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  'base64',
);

let helpers;

before(async () => {
  // Receipts must not land in the repository, so the test writes to a
  // throwaway folder and removes it afterwards.
  uploadDir = await mkdtemp(path.join(tmpdir(), 'winibex-uploads-'));
  process.env.UPLOAD_DIR = uploadDir;

  helpers = await import('./helpers/api.js');

  connection = await helpers.connect();
  await helpers.buildSchema(connection);
  await helpers.seedUsers(connection);
  await helpers.seedAccounts(connection);
  api = await helpers.startServer();

  for (const role of ['owner', 'staff']) {
    tokens[role] = (await helpers.signIn(api, `${role}@test.local`)).body.accessToken;
  }

  bankId = await helpers.accountId(connection, 'Winibex bank');
  outCategory = await helpers.categoryId(connection, 'out');
});

after(async () => {
  await api?.close();
  if (connection) {
    await helpers.dropAll(connection);
    await connection.end();
  }
  if (uploadDir) await rm(uploadDir, { recursive: true, force: true });
});

async function draft({ gross = 560000, description = 'Claude subscription' } = {}) {
  const { WARNING_CODES } = await import('../modules/transactions/validation.js');
  const response = await api.post('/transactions', {
    token: tokens.owner,
    headers: helpers.idempotencyKey(),
    body: {
      date: '2026-07-05', direction: 'out', method: 'card', description,
      categoryId: outCategory, accountId: bankId,
      gross: { minor: gross, currency: 'PKR' },
      acknowledged_warnings: WARNING_CODES,
    },
  });
  assert.equal(response.status, 201, response.raw);
  return response.body.transaction.id;
}

test('a receipt is stored, fingerprinted and kept for ten years', async () => {
  const id = await draft();

  const response = await api.upload(`/transactions/${id}/attachments`, {
    token: tokens.owner,
    file: PNG,
    filename: 'receipt.png',
    mime: 'image/png',
  });

  assert.equal(response.status, 201, response.raw);
  assert.equal(response.body.attachment.documentType, 'receipt');
  assert.equal(response.body.attachment.mime, 'image/png');
  assert.equal(response.body.attachment.sizeBytes, PNG.length);
  assert.match(response.body.attachment.sha256, /^[0-9a-f]{64}$/);

  // The entry is dated 2026, so the receipt is kept until 2036.
  assert.ok(String(response.body.attachment.retainUntil).startsWith('2036'));
});

test('the file lands outside the repository, under a year and month', async () => {
  const years = await readdir(path.join(uploadDir, 'receipts'));
  assert.ok(years.length > 0, 'nothing was written to the upload folder');

  const months = await readdir(path.join(uploadDir, 'receipts', years[0]));
  const files = await readdir(path.join(uploadDir, 'receipts', years[0], months[0]));

  assert.ok(files.length > 0);
  assert.ok(
    !files.some((name) => name.includes('receipt')),
    'the uploaded name is not used on disk, or a crafted name could choose where it lands',
  );
});

test('the receipt is listed against its entry', async () => {
  const id = await draft({ description: 'Has a receipt' });
  await api.upload(`/transactions/${id}/attachments`, {
    token: tokens.owner, file: PNG, filename: 'r.png', mime: 'image/png',
  });

  const response = await api.get(`/transactions/${id}/attachments`, { token: tokens.owner });
  assert.equal(response.body.attachments.length, 1);
  assert.ok(response.body.attachments[0].uploadedByName, 'who attached it is part of the record');
});

test('a receipt cannot be read without a login', async () => {
  const id = await draft({ description: 'Private receipt' });
  const uploaded = await api.upload(`/transactions/${id}/attachments`, {
    token: tokens.owner, file: PNG, filename: 'r.png', mime: 'image/png',
  });

  const anonymous = await api.get(`/attachments/${uploaded.body.attachment.id}/file`);
  assert.equal(anonymous.status, 401);

  const signedIn = await api.get(`/attachments/${uploaded.body.attachment.id}/file`, {
    token: tokens.staff,
  });
  assert.equal(signedIn.status, 200);
});

test('anything that is not a photo or a PDF is refused', async () => {
  const id = await draft({ description: 'Wrong file type' });

  const response = await api.upload(`/transactions/${id}/attachments`, {
    token: tokens.owner,
    file: Buffer.from('#!/bin/sh\necho hello'),
    filename: 'script.sh',
    mime: 'application/x-sh',
  });

  assert.equal(response.status, 400);
  assert.equal(response.body.error.code, 'UNSUPPORTED_FILE');
});

test('a request with no file is refused in words', async () => {
  const id = await draft({ description: 'No file sent' });

  const response = await api.post(`/transactions/${id}/attachments`, {
    token: tokens.owner,
    body: {},
  });

  assert.equal(response.status, 400);
});

test('attaching to an entry that does not exist is a 404', async () => {
  const response = await api.upload('/transactions/999999/attachments', {
    token: tokens.owner, file: PNG, filename: 'r.png', mime: 'image/png',
  });
  assert.equal(response.status, 404);
});

// ---------------------------------------------------------------------------
// The receipt rule
// ---------------------------------------------------------------------------

test('a large payment cannot post without a receipt', async () => {
  await connection.query(
    `UPDATE settings SET value = '500000' WHERE setting_key = 'receipt_required_above'`,
  );

  const id = await draft({ gross: 2000000, description: 'Large payment, no receipt' });

  const posted = await api.post(`/transactions/${id}/approve`, {
    token: tokens.owner, headers: helpers.idempotencyKey(),
  });

  assert.equal(posted.status, 400);
  assert.equal(posted.body.error.code, 'RECEIPT_REQUIRED');
});

test('the same payment posts once its receipt is attached', async () => {
  const id = await draft({ gross: 2000000, description: 'Large payment with a receipt' });

  await api.upload(`/transactions/${id}/attachments`, {
    token: tokens.owner, file: PNG, filename: 'r.png', mime: 'image/png',
  });

  const posted = await api.post(`/transactions/${id}/approve`, {
    token: tokens.owner, headers: helpers.idempotencyKey(),
  });

  assert.equal(posted.status, 200, posted.raw);
  assert.ok(posted.body.journalNumber);
});

test('a small payment needs no receipt', async () => {
  const id = await draft({ gross: 100000, description: 'Small payment' });

  const posted = await api.post(`/transactions/${id}/approve`, {
    token: tokens.owner, headers: helpers.idempotencyKey(),
  });

  assert.equal(posted.status, 200, posted.raw);

  await connection.query(
    `UPDATE settings SET value = '0' WHERE setting_key = 'receipt_required_above'`,
  );
});

test('a receipt can be attached after an entry is posted', async () => {
  const id = await draft({ description: 'Receipt came later' });
  await api.post(`/transactions/${id}/approve`, {
    token: tokens.owner, headers: helpers.idempotencyKey(),
  });

  const response = await api.upload(`/transactions/${id}/attachments`, {
    token: tokens.owner, file: PNG, filename: 'late.png', mime: 'image/png',
  });

  assert.equal(
    response.status, 201,
    'the photo is often taken later, and late evidence beats no evidence',
  );
});
