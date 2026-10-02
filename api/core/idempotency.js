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
// Rows live 24 hours. This is the only table in the system anything deletes
// from.

import { getPool } from './db.js';
import { AppError, ErrorCode, badRequest } from './errors.js';
import { fromJsonColumn } from './json.js';

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const HEADER = 'idempotency-key';

function endpointOf(req) {
  return `${req.method} ${req.baseUrl ?? ''}${req.path}`.slice(0, 120);
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

    try {
      await pool.query(
        'INSERT INTO idempotency_keys (idempotency_key, user_id, endpoint) VALUES (?, ?, ?)',
        [key, userId, endpoint],
      );
    } catch (error) {
      if (error.code !== 'ER_DUP_ENTRY') throw error;
      return replay(req, res, next, { pool, key, endpoint, userId });
    }

    captureResponse(req, res, { pool, key });
    return next();
  };
}

async function replay(req, res, next, { pool, key, endpoint, userId }) {
  const [rows] = await pool.query(
    'SELECT user_id, endpoint, response_json FROM idempotency_keys WHERE idempotency_key = ?',
    [key],
  );
  const stored = rows[0];

  if (!stored) {
    // Purged between the insert failing and this read. Treat it as new.
    return next();
  }

  // The same key on a different request is a client bug, and replaying the
  // wrong answer would be worse than refusing.
  if (String(stored.user_id) !== String(userId) || stored.endpoint !== endpoint) {
    return next(
      new AppError(
        409,
        ErrorCode.IDEMPOTENCY_KEY_REUSED,
        'That Idempotency-Key was already used for a different request.',
      ),
    );
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
