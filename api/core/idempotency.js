// Idempotency.
//
// A double tap on a phone, or a dropped connection where the reply never
// arrived and the app retried, must never post the same expense twice. The
// client generates a key when the form opens and sends it with the request.
// The same key returns the same stored answer instead of doing the work again.
//
// How it holds up under a genuine race: the key is the primary key of
// idempotency_keys, so the first request to insert it wins. A second request
// arriving while the first is still working gets a duplicate-key error, finds
// the row with no stored response yet, and is told the original is in flight.
// It does not wait and it does not run the work.
//
// The same key must also mean the same request. Each key stores a SHA-256 of
// the body it was first used with, and a different body under that key is
// refused, never answered with the first result. Before this check a changed
// entry, sent again under its old key, was told it had been saved and the old
// figures were posted. Defect F7, decision 059, migration 006.
//
// Rows live 24 hours. This is the only table in the system anything deletes
// from.

import crypto from 'node:crypto';

import { getPool } from './db.js';
import { AppError, ErrorCode, badRequest } from './errors.js';
import { fromJsonColumn } from './json.js';

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const HEADER = 'idempotency-key';

// Said in words a person can act on. The app should never show this, because
// it edits the existing draft rather than resending under the old key, but if
// it ever does, the person must understand it.
const REUSED_MESSAGE =
  'This was already sent once with different details, so it was not saved again. Start it again as a new entry.';

function endpointOf(req) {
  return `${req.method} ${req.baseUrl ?? ''}${req.path}`.slice(0, 120);
}

// JSON with object keys sorted at every level, so the same content always
// gives the same text whatever order a client wrote the keys in. Arrays keep
// their order, because in an array the order is part of the content.
function canonical(value) {
  if (Array.isArray(value)) return `[${value.map(canonical).join(',')}]`;
  if (value && typeof value === 'object') {
    const keys = Object.keys(value).sort();
    return `{${keys.map((key) => `${JSON.stringify(key)}:${canonical(value[key])}`).join(',')}}`;
  }
  return JSON.stringify(value ?? null);
}

// A request with no body, such as approving, fingerprints as an empty object,
// so every bodiless request to one address matches every other.
export function fingerprintOf(body) {
  const isEmpty = body === undefined || body === null
    || (typeof body === 'object' && !Array.isArray(body) && Object.keys(body).length === 0);
  return crypto.createHash('sha256').update(isEmpty ? '{}' : canonical(body)).digest('hex');
}

export function idempotency({ required = true } = {}) {
  return async function idempotencyMiddleware(req, res, next) {
    const key = req.get(HEADER);

    if (!key) {
      if (!required) return next();
      return next(
        badRequest(
          ErrorCode.IDEMPOTENCY_KEY_REQUIRED,
          'This request needs an Idempotency-Key header.',
          { field: HEADER },
        ),
      );
    }

    if (!UUID.test(key)) {
      return next(
        badRequest(ErrorCode.IDEMPOTENCY_KEY_INVALID, 'Idempotency-Key must be a UUID.', {
          field: HEADER,
        }),
      );
    }

    const pool = getPool();
    const endpoint = endpointOf(req);
    const userId = req.user?.id ?? null;
    const requestHash = fingerprintOf(req.body);

    try {
      await pool.query(
        'INSERT INTO idempotency_keys (idempotency_key, user_id, endpoint, request_hash) VALUES (?, ?, ?, ?)',
        [key, userId, endpoint, requestHash],
      );
    } catch (error) {
      if (error.code !== 'ER_DUP_ENTRY') throw error;
      return replay(req, res, next, { pool, key, endpoint, userId, requestHash });
    }

    captureResponse(req, res, { pool, key });
    return next();
  };
}

async function replay(req, res, next, { pool, key, endpoint, userId, requestHash }) {
  const [rows] = await pool.query(
    'SELECT user_id, endpoint, request_hash, response_json FROM idempotency_keys WHERE idempotency_key = ?',
    [key],
  );
  const stored = rows[0];

  if (!stored) {
    // Purged between the insert failing and this read. Treat it as new.
    return next();
  }

  // The same key on a different request is refused: another person, another
  // address, or the same address with different content. Replaying the first
  // answer to a different request is how a changed entry was reported saved
  // with its old figures. A row from before migration 006 has no fingerprint;
  // it is compared on person and address only, and expires within a day.
  const differentContent = stored.request_hash !== null
    && stored.request_hash !== undefined
    && stored.request_hash !== requestHash;
  if (String(stored.user_id) !== String(userId) || stored.endpoint !== endpoint || differentContent) {
    return next(new AppError(409, ErrorCode.IDEMPOTENCY_KEY_REUSED, REUSED_MESSAGE));
  }

  if (!stored.response_json) {
    return next(
      new AppError(
        409,
        ErrorCode.REQUEST_IN_PROGRESS,
        'An identical request is still being processed. Try again in a moment.',
      ),
    );
  }

  const replayed = fromJsonColumn(stored.response_json);
  res.set('Idempotent-Replay', 'true');
  return res.status(replayed.status).json(replayed.body);
}

function captureResponse(req, res, { pool, key }) {
  const originalJson = res.json.bind(res);

  res.json = (body) => {
    const status = res.statusCode;

    // Only a success is worth replaying. A failure must be retryable with the
    // same key, so its placeholder row is removed instead.
    const finish =
      status >= 200 && status < 300
        ? pool.query('UPDATE idempotency_keys SET response_json = ? WHERE idempotency_key = ?', [
            JSON.stringify({ status, body }),
            key,
          ])
        : pool.query('DELETE FROM idempotency_keys WHERE idempotency_key = ?', [key]);

    finish.catch((error) => {
      console.error('Could not record idempotency result:', error);
    });

    return originalJson(body);
  };
}

export async function purgeExpiredKeys({ olderThanHours = 24 } = {}) {
  const [result] = await getPool().query(
    'DELETE FROM idempotency_keys WHERE created_at < UTC_TIMESTAMP() - INTERVAL ? HOUR',
    [olderThanHours],
  );
  return result.affectedRows;
}
