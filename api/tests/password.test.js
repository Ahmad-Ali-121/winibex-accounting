import test from 'node:test';
import assert from 'node:assert/strict';
import process from 'node:process';

import {
  hashPassword,
  verifyPassword,
  needsRehash,
  configuredAlgorithm,
} from '../core/password.js';

const GOOD = 'correct-horse-battery';

// argon2 is not installed yet. The tests that need it skip themselves rather
// than fail, so adding the package later turns them on with no edit here.
const hasArgon2 = await import('argon2').then(
  () => true,
  () => false,
);
const needsArgon2 = { skip: hasArgon2 ? false : 'argon2 is not installed' };

function withAlgorithm(value, fn) {
  const previous = process.env.PASSWORD_ALGORITHM;
  if (value === undefined) {
    delete process.env.PASSWORD_ALGORITHM;
  } else {
    process.env.PASSWORD_ALGORITHM = value;
  }
  return (async () => {
    try {
      await fn();
    } finally {
      if (previous === undefined) {
        delete process.env.PASSWORD_ALGORITHM;
      } else {
        process.env.PASSWORD_ALGORITHM = previous;
      }
    }
  })();
}

test('the configured algorithm is one we support', () => {
  assert.ok(['argon2id', 'bcrypt'].includes(configuredAlgorithm()));
});

test('an unknown algorithm is rejected rather than silently defaulted', () =>
  withAlgorithm('sha1', () => {
    assert.throws(() => configuredAlgorithm(), /argon2id or bcrypt/);
  }));

test('bcrypt hashes and verifies', () =>
  withAlgorithm('bcrypt', async () => {
    const hash = await hashPassword(GOOD);
    assert.match(hash, /^\$2[aby]\$/);
    assert.equal(await verifyPassword(hash, GOOD), true);
    assert.equal(await verifyPassword(hash, 'wrong-password-here'), false);
  }));

test('the same password hashes differently every time', () =>
  withAlgorithm('bcrypt', async () => {
    const first = await hashPassword(GOOD);
    const second = await hashPassword(GOOD);
    assert.notEqual(first, second);
  }));

test('a password over 72 bytes is refused under bcrypt, not truncated', () =>
  withAlgorithm('bcrypt', async () => {
    await assert.rejects(() => hashPassword('a'.repeat(80)), /72 bytes/);
  }));

test('a short password is refused', () =>
  withAlgorithm('bcrypt', async () => {
    await assert.rejects(() => hashPassword('short'), /at least 10/);
  }));

test('an unrecognised hash format raises rather than returning false', async () => {
  await assert.rejects(() => verifyPassword('not-a-hash', GOOD), /Unrecognised/);
});

test('an empty stored hash never verifies', async () => {
  assert.equal(await verifyPassword('', GOOD), false);
  assert.equal(await verifyPassword(null, GOOD), false);
});

test('argon2id hashes and verifies', needsArgon2, () =>
  withAlgorithm('argon2id', async () => {
    const hash = await hashPassword(GOOD);
    assert.match(hash, /^\$argon2id\$/);
    assert.equal(await verifyPassword(hash, GOOD), true);
    assert.equal(await verifyPassword(hash, 'wrong-password-here'), false);
  }));

// Switching algorithm must never lock anyone out of an existing account.
test('a bcrypt hash still verifies while argon2id is configured', needsArgon2, () =>
  withAlgorithm('bcrypt', async () => {
    const bcryptHash = await hashPassword(GOOD);
    await withAlgorithm('argon2id', async () => {
      assert.equal(await verifyPassword(bcryptHash, GOOD), true);
      assert.equal(needsRehash(bcryptHash), true);
    });
  }));

test('an argon2id hash still verifies while bcrypt is configured', needsArgon2, () =>
  withAlgorithm('argon2id', async () => {
    const argonHash = await hashPassword(GOOD);
    await withAlgorithm('bcrypt', async () => {
      assert.equal(await verifyPassword(argonHash, GOOD), true);
      assert.equal(needsRehash(argonHash), true);
    });
  }));
