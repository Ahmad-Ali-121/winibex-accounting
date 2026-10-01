// The four pieces the posting engine will sit on. Everything here is tested
// against the real database, including the concurrency, because the guarantees
// being checked live in the database rather than in the code.

import test, { before, after } from 'node:test';
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import express from 'express';

import { connect, dropAll, buildSchema, seedUsers } from './helpers/api.js';
import { getPool, closePool, withTransaction } from '../core/db.js';
import { writeAudit, readAuditFor, AuditAction } from '../core/audit.js';
import { allocate, peek } from '../core/sequences.js';
import { idempotency, purgeExpiredKeys } from '../core/idempotency.js';
import { errorHandler, notFoundHandler } from '../core/errors.js';

let connection;
let ownerId;

before(async () => {
  connection = await connect();
  await buildSchema(connection);
  await seedUsers(connection);
  const [rows] = await connection.query('SELECT id FROM users WHERE email = ?', [
    'owner@test.local',
  ]);
  ownerId = rows[0].id;
});

after(async () => {
  if (connection) {
    await dropAll(connection);
    await connection.end();
  }
  await closePool();
});

// ---------------------------------------------------------------------------
// withTransaction
// ---------------------------------------------------------------------------

test('a committed transaction keeps its work', async () => {
  await withTransaction(async (tx) => {
    await tx.query("INSERT INTO settings (setting_key, value, value_type) VALUES ('tx_commit','yes','string')");
  });

  const [rows] = await connection.query('SELECT value FROM settings WHERE setting_key = ?', [
    'tx_commit',
  ]);
  assert.equal(rows[0].value, 'yes');
});

test('a thrown error rolls back everything in the transaction, not just the last statement', async () => {
  await assert.rejects(
    withTransaction(async (tx) => {
      await tx.query("INSERT INTO settings (setting_key, value, value_type) VALUES ('tx_a','1','string')");
      await tx.query("INSERT INTO settings (setting_key, value, value_type) VALUES ('tx_b','2','string')");
      throw new Error('something went wrong halfway');
    }),
    /something went wrong halfway/,
  );

  const [rows] = await connection.query(
    "SELECT setting_key FROM settings WHERE setting_key IN ('tx_a','tx_b')",
  );
  assert.deepEqual(rows, [], 'a half-written transaction survived');
});

test('a database error inside the transaction rolls it back too', async () => {
  await assert.rejects(
    withTransaction(async (tx) => {
      await tx.query("INSERT INTO settings (setting_key, value, value_type) VALUES ('tx_c','1','string')");
      await tx.query('INSERT INTO settings (setting_key) VALUES (NULL)');
    }),
  );

  const [rows] = await connection.query("SELECT setting_key FROM settings WHERE setting_key = 'tx_c'");
  assert.deepEqual(rows, []);
});

test('the connection goes back to the pool even when the callback throws', async () => {
  for (let i = 0; i < 20; i += 1) {
    await assert.rejects(
      withTransaction(() => {
        throw new Error('nope');
      }),
    );
  }
  // If connections leaked, the pool would be exhausted by now and this hangs.
  const [rows] = await getPool().query('SELECT 1 AS ok');
  assert.equal(rows[0].ok, 1);
});

// ---------------------------------------------------------------------------
// Audit log
// ---------------------------------------------------------------------------

test('an audit entry records both sides of a change', async () => {
  await withTransaction(async (tx) => {
    await writeAudit(tx, {
      userId: ownerId,
      table: 'users',
      recordId: ownerId,
      action: AuditAction.UPDATE,
      before: { role: 'staff' },
      after: { role: 'admin' },
      ip: '127.0.0.1',
    });
  });

  const entries = await readAuditFor(connection, 'users', ownerId);
  const entry = entries.at(-1);
  assert.equal(entry.action, 'update');
  assert.deepEqual(entry.before_json, { role: 'staff' });
  assert.deepEqual(entry.after_json, { role: 'admin' });
});

// An audit row that outlives a rolled-back change would be a record of
// something that never happened.
test('the audit entry rolls back with the change it describes', async () => {
  const before = (await readAuditFor(connection, 'users', ownerId)).length;

  await assert.rejects(
    withTransaction(async (tx) => {
      await writeAudit(tx, {
        userId: ownerId,
        table: 'users',
        recordId: ownerId,
        action: AuditAction.PERMISSION_CHANGE,
        after: { role: 'owner' },
      });
      throw new Error('change failed');
    }),
  );

  const afterwards = (await readAuditFor(connection, 'users', ownerId)).length;
  assert.equal(afterwards, before, 'an audit row survived a rolled-back change');
});

test('an audit entry with no user is allowed, for work done by a job', async () => {
  await withTransaction(async (tx) => {
    await writeAudit(tx, {
      table: 'recurring_costs',
      recordId: 1,
      action: AuditAction.INSERT,
      after: { created: 'by cron' },
    });
  });

  const entries = await readAuditFor(connection, 'recurring_costs', 1);
  assert.equal(entries.at(-1).user_id, null);
});

test('writeAudit refuses an entry it cannot store properly', async () => {
  await assert.rejects(
    withTransaction((tx) => writeAudit(tx, { table: 'users', action: 'x'.repeat(40) })),
    /too long/,
  );
  await assert.rejects(
    withTransaction((tx) => writeAudit(tx, { action: 'insert' })),
    /table name/,
  );
});

// ---------------------------------------------------------------------------
// Sequences
// ---------------------------------------------------------------------------

test('the invoice sequence starts where the spreadsheet stopped', async () => {
  const current = await peek(connection, 'invoice');
  assert.equal(current.value, 5026);
  assert.equal(current.prefix, 'INV-');
});

test('allocating gives consecutive numbers with the prefix', async () => {
  const first = await withTransaction((tx) => allocate(tx, 'journal'));
  const second = await withTransaction((tx) => allocate(tx, 'journal'));

  assert.equal(second.value, first.value + 1);
  assert.equal(second.formatted, `JV-${second.value}`);
});

// The whole point. A number taken by work that then fails must not be lost.
test('a rolled-back transaction gives the number back', async () => {
  const before = (await peek(connection, 'voucher')).value;

  await assert.rejects(
    withTransaction(async (tx) => {
      await allocate(tx, 'voucher');
      throw new Error('the insert failed');
    }),
  );

  const afterwards = (await peek(connection, 'voucher')).value;
  assert.equal(afterwards, before, 'a number was burned by a failed transaction');
});

test('allocating outside a transaction is refused', async () => {
  await assert.rejects(() => allocate(getPool(), 'journal'), /inside a transaction/);
});

test('an unknown sequence name is refused before touching the database', async () => {
  await assert.rejects(
    withTransaction((tx) => allocate(tx, 'not_a_sequence')),
    /Unknown sequence/,
  );
});

// Two people creating an invoice at the same moment is the case that produces
// either duplicates or gaps if the locking is wrong.
test('concurrent allocation produces no gaps and no duplicates', async () => {
  const start = (await peek(connection, 'receipt')).value;
  const count = 25;

  const results = await Promise.all(
    Array.from({ length: count }, () => withTransaction((tx) => allocate(tx, 'receipt'))),
  );

  const numbers = results.map((r) => r.value).sort((a, b) => a - b);
  const expected = Array.from({ length: count }, (_, i) => start + i);

  assert.deepEqual(numbers, expected, 'allocation was not gapless under concurrency');
  assert.equal(new Set(numbers).size, count, 'a number was handed out twice');
  assert.equal((await peek(connection, 'receipt')).value, start + count);
});

// ---------------------------------------------------------------------------
// Idempotency
// ---------------------------------------------------------------------------

function buildIdempotentApp({ onRequest }) {
  const app = express();
  app.use(express.json());
  app.use((req, res, next) => {
    req.user = { id: ownerId };
    next();
  });
  app.post('/things', idempotency(), (req, res) => {
    const result = onRequest(req);
    res.status(result.status).json(result.body);
  });
  app.use(notFoundHandler);
  app.use(errorHandler);
  return app;
}

async function startApp(app) {
  const server = await new Promise((resolve) => {
    const listener = app.listen(0, '127.0.0.1', () => resolve(listener));
  });
  const { port } = server.address();
  return {
    async post(path, { key, body } = {}) {
      const response = await fetch(`http://127.0.0.1:${port}${path}`, {
        method: 'POST',
        headers: {
          'content-type': 'application/json',
          ...(key ? { 'idempotency-key': key } : {}),
        },
        body: JSON.stringify(body ?? {}),
      });
      return {
        status: response.status,
        body: await response.json(),
        replayed: response.headers.get('idempotent-replay') === 'true',
      };
    },
    close: () => new Promise((resolve) => server.close(resolve)),
  };
}

test('the same key twice does the work once and returns the same answer', async () => {
  let runs = 0;
  const app = await startApp(
    buildIdempotentApp({
      onRequest: () => {
        runs += 1;
        return { status: 201, body: { created: runs } };
      },
    }),
  );

  try {
    const key = crypto.randomUUID();
    const first = await app.post('/things', { key, body: { amount: 500 } });
    const second = await app.post('/things', { key, body: { amount: 500 } });

    assert.equal(runs, 1, 'the work ran twice');
    assert.equal(first.status, 201);
    assert.equal(second.status, 201);
    assert.deepEqual(second.body, first.body);
    assert.equal(second.replayed, true);
  } finally {
    await app.close();
  }
});

test('different keys do the work each time', async () => {
  let runs = 0;
  const app = await startApp(
    buildIdempotentApp({
      onRequest: () => {
        runs += 1;
        return { status: 201, body: { created: runs } };
      },
    }),
  );

  try {
    await app.post('/things', { key: crypto.randomUUID() });
    await app.post('/things', { key: crypto.randomUUID() });
    assert.equal(runs, 2);
  } finally {
    await app.close();
  }
});

test('a missing or malformed key is refused', async () => {
  const app = await startApp(
    buildIdempotentApp({ onRequest: () => ({ status: 201, body: {} }) }),
  );

  try {
    const missing = await app.post('/things', {});
    assert.equal(missing.status, 400);
    assert.equal(missing.body.error.code, 'IDEMPOTENCY_KEY_REQUIRED');

    const malformed = await app.post('/things', { key: 'not-a-uuid' });
    assert.equal(malformed.status, 400);
    assert.equal(malformed.body.error.code, 'IDEMPOTENCY_KEY_INVALID');
  } finally {
    await app.close();
  }
});

// A failure must stay retryable. Storing it would make the user resubmit the
// form to get the same error forever.
test('a failed request does not keep its key, so a retry can succeed', async () => {
  let attempt = 0;
  const app = await startApp(
    buildIdempotentApp({
      onRequest: () => {
        attempt += 1;
        return attempt === 1
          ? { status: 400, body: { error: { code: 'VALIDATION_FAILED' } } }
          : { status: 201, body: { created: true } };
      },
    }),
  );

  try {
    const key = crypto.randomUUID();
    const failed = await app.post('/things', { key });
    assert.equal(failed.status, 400);

    // Give the delete a moment; it is fired after the response is sent.
    await new Promise((resolve) => setTimeout(resolve, 150));

    const retried = await app.post('/things', { key });
    assert.equal(retried.status, 201);
  } finally {
    await app.close();
  }
});

test('the same key on a different endpoint is refused rather than replayed', async () => {
  const key = crypto.randomUUID();
  await getPool().query(
    'INSERT INTO idempotency_keys (idempotency_key, user_id, endpoint, response_json) VALUES (?, ?, ?, ?)',
    [key, ownerId, 'POST /somewhere-else', JSON.stringify({ status: 200, body: { ok: true } })],
  );

  const app = await startApp(
    buildIdempotentApp({ onRequest: () => ({ status: 201, body: {} }) }),
  );

  try {
    const response = await app.post('/things', { key });
    assert.equal(response.status, 409);
    assert.equal(response.body.error.code, 'IDEMPOTENCY_KEY_REUSED');
  } finally {
    await app.close();
  }
});

test('a request still in flight is told so, rather than running twice', async () => {
  const key = crypto.randomUUID();
  await getPool().query(
    'INSERT INTO idempotency_keys (idempotency_key, user_id, endpoint) VALUES (?, ?, ?)',
    [key, ownerId, 'POST /things'],
  );

  let runs = 0;
  const app = await startApp(
    buildIdempotentApp({
      onRequest: () => {
        runs += 1;
        return { status: 201, body: {} };
      },
    }),
  );

  try {
    const response = await app.post('/things', { key });
    assert.equal(response.status, 409);
    assert.equal(response.body.error.code, 'REQUEST_IN_PROGRESS');
    assert.equal(runs, 0, 'the work ran while an identical request was in flight');
  } finally {
    await app.close();
  }
});

test('keys older than a day are purged, newer ones are kept', async () => {
  const oldKey = crypto.randomUUID();
  const freshKey = crypto.randomUUID();

  await getPool().query(
    `INSERT INTO idempotency_keys (idempotency_key, user_id, endpoint, created_at)
     VALUES (?, ?, 'POST /things', UTC_TIMESTAMP() - INTERVAL 30 HOUR)`,
    [oldKey, ownerId],
  );
  await getPool().query(
    'INSERT INTO idempotency_keys (idempotency_key, user_id, endpoint) VALUES (?, ?, ?)',
    [freshKey, ownerId, 'POST /things'],
  );

  const removed = await purgeExpiredKeys();
  assert.ok(removed >= 1);

  const [rows] = await getPool().query(
    'SELECT idempotency_key FROM idempotency_keys WHERE idempotency_key IN (?, ?)',
    [oldKey, freshKey],
  );
  const remaining = rows.map((r) => r.idempotency_key);
  assert.ok(!remaining.includes(oldKey), 'an expired key survived the purge');
  assert.ok(remaining.includes(freshKey), 'a fresh key was purged');
});
