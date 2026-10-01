// Password hashing.
//
// Decision 039: argon2id, with bcryptjs as the documented fallback if the
// argon2 native module will not build on Hostinger.
//
// Two things this file is careful about:
//
// 1. Which algorithm produced a stored hash is read from the hash itself, not
//    from configuration. Switching PASSWORD_ALGORITHM therefore does not lock
//    anyone out of an account created before the switch.
// 2. bcrypt silently ignores everything past 72 bytes of a password. That is a
//    security hole, not a quirk, so it is rejected rather than truncated.

const MIN_LENGTH = 10;
const MAX_LENGTH = 1024;
const BCRYPT_MAX_BYTES = 72;
const BCRYPT_ROUNDS = 12;

// OWASP minimums for argon2id: 19 MiB of memory, two iterations, one lane.
const ARGON2_MEMORY_COST = 19456;
const ARGON2_TIME_COST = 2;
const ARGON2_PARALLELISM = 1;

const ARGON2_HASH = /^\$argon2(id|i|d)\$/;
const BCRYPT_HASH = /^\$2[aby]?\$/;

let argon2Cache = null;
let bcryptCache = null;

async function argon2Lib() {
  if (!argon2Cache) {
    const loaded = await import('argon2');
    argon2Cache = loaded.default ?? loaded;
  }
  return argon2Cache;
}

async function bcryptLib() {
  if (!bcryptCache) {
    const loaded = await import('bcryptjs');
    bcryptCache = loaded.default ?? loaded;
  }
  return bcryptCache;
}

export function configuredAlgorithm() {
  const value = (process.env.PASSWORD_ALGORITHM ?? 'argon2id').toLowerCase();
  if (value !== 'argon2id' && value !== 'bcrypt') {
    throw new Error(
      `PASSWORD_ALGORITHM must be argon2id or bcrypt, received "${value}"`,
    );
  }
  return value;
}

function assertUsable(plain, algorithm) {
  if (typeof plain !== 'string') {
    throw new TypeError('Password must be a string');
  }
  if (plain.length < MIN_LENGTH) {
    throw new Error(`Password must be at least ${MIN_LENGTH} characters`);
  }
  if (plain.length > MAX_LENGTH) {
    throw new Error(`Password must be at most ${MAX_LENGTH} characters`);
  }
  if (algorithm === 'bcrypt' && Buffer.byteLength(plain, 'utf8') > BCRYPT_MAX_BYTES) {
    throw new Error(
      `bcrypt ignores anything past ${BCRYPT_MAX_BYTES} bytes. Use a shorter password or argon2id.`,
    );
  }
}

export async function hashPassword(plain) {
  const algorithm = configuredAlgorithm();
  assertUsable(plain, algorithm);

  if (algorithm === 'bcrypt') {
    const bcrypt = await bcryptLib();
    return bcrypt.hash(plain, BCRYPT_ROUNDS);
  }

  const argon2 = await argon2Lib();
  return argon2.hash(plain, {
    type: argon2.argon2id,
    memoryCost: ARGON2_MEMORY_COST,
    timeCost: ARGON2_TIME_COST,
    parallelism: ARGON2_PARALLELISM,
  });
}

export async function verifyPassword(storedHash, plain) {
  if (typeof storedHash !== 'string' || storedHash.length === 0) return false;
  if (typeof plain !== 'string' || plain.length === 0) return false;

  if (ARGON2_HASH.test(storedHash)) {
    const argon2 = await argon2Lib();
    return argon2.verify(storedHash, plain);
  }

  if (BCRYPT_HASH.test(storedHash)) {
    const bcrypt = await bcryptLib();
    return bcrypt.compare(plain, storedHash);
  }

  throw new Error('Unrecognised password hash format');
}

// True when a hash was made with an algorithm or cost other than the one now
// configured. Login can use this to re-hash transparently on a correct password.
export function needsRehash(storedHash) {
  const algorithm = configuredAlgorithm();
  if (algorithm === 'bcrypt') {
    if (!BCRYPT_HASH.test(storedHash)) return true;
    const rounds = Number.parseInt(storedHash.split('$')[2], 10);
    return Number.isNaN(rounds) || rounds < BCRYPT_ROUNDS;
  }
  return !ARGON2_HASH.test(storedHash);
}

export const passwordPolicy = Object.freeze({
  minLength: MIN_LENGTH,
  maxLength: MAX_LENGTH,
  bcryptMaxBytes: BCRYPT_MAX_BYTES,
});
