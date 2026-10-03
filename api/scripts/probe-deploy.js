// A throwaway first deploy.
//
// Hostinger's Business plan gives no SSH and no build log, so a deploy that
// fails leaves nothing to read. This runs first, on its own, and reports what
// the real server actually is before anything that matters is deployed.
//
// It answers the questions DEPLOY.md says to answer at this point:
//
//   Which Node version is really running
//   Does the database answer, and is it the MariaDB 11.8 we built against
//   Does password hashing work, and how slow is it on this hardware
//   Is UPLOAD_DIR writable, and is it outside the web root
//   Are the session settings the pool relies on actually applied
//
// Delete this file once the real API is deployed. It is deliberately standalone
// and imports nothing from the app, so a broken import in the app cannot stop
// the probe from telling us why.

import http from 'node:http';
import process from 'node:process';
import path from 'node:path';
import { mkdir, writeFile, unlink, stat } from 'node:fs/promises';

const PORT = process.env.PORT || 3000;

async function checkNode() {
  return {
    version: process.version,
    platform: `${process.platform} ${process.arch}`,
    // Hostinger offers 18, 20, 22 and 24. The app needs 20.6 or later for
    // --env-file, and 24 was selected in hPanel.
    meetsRequirement: Number(process.versions.node.split('.')[0]) >= 20,
    timezone: process.env.TZ ?? '(not set)',
    nodeEnv: process.env.NODE_ENV ?? '(not set)',
  };
}

async function checkDatabase() {
  try {
    const mysql = await import('mysql2/promise');

    const connection = await mysql.createConnection({
      host: process.env.DB_HOST,
      port: Number(process.env.DB_PORT ?? 3306),
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      database: process.env.DB_NAME,
      supportBigNumbers: true,
      timezone: 'Z',
      multipleStatements: false,
      connectTimeout: 10000,
    });

    // The same session settings core/db.js applies. If Hostinger refuses any
    // of them, that has to be known now rather than when money is being
    // silently truncated.
    const applied = [];
    for (const statement of [
      "SET SESSION sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ZERO_DATE,NO_ZERO_IN_DATE,NO_ENGINE_SUBSTITUTION,ONLY_FULL_GROUP_BY'",
      "SET SESSION time_zone = '+00:00'",
      "SET SESSION transaction_isolation = 'READ-COMMITTED'",
    ]) {
      try {
        await connection.query(statement);
        applied.push({ statement: statement.slice(12, 40), ok: true });
      } catch (error) {
        applied.push({ statement: statement.slice(12, 40), ok: false, error: error.message });
      }
    }

    const [version] = await connection.query('SELECT VERSION() AS version');
    const [session] = await connection.query(
      'SELECT @@SESSION.sql_mode AS sqlMode, @@SESSION.time_zone AS timeZone',
    );
    const [limits] = await connection.query("SHOW VARIABLES LIKE 'max_connections'");

    // The one that silently corrupts money if it is wrong. Decision 044.
    const [big] = await connection.query('SELECT 9007199254740993 AS big');

    // The collation migration 001 uses. It exists from MariaDB 11.6 only.
    const [collation] = await connection.query(
      "SELECT COUNT(*) AS found FROM information_schema.collations WHERE collation_name = 'utf8mb4_uca1400_ai_ci'",
    );

    const [tables] = await connection.query(
      'SELECT COUNT(*) AS n FROM information_schema.tables WHERE table_schema = DATABASE()',
    );

    await connection.end();

    return {
      reachable: true,
      version: version[0].version,
      isMariaDb11: /^11\./.test(String(version[0].version)),
      sessionStatements: applied,
      sqlMode: session[0].sqlMode,
      timeZone: session[0].timeZone,
      maxConnections: limits[0]?.Value ?? null,
      bigIntExact: String(big[0].big) === '9007199254740993',
      collationExists: Number(collation[0].found) === 1,
      tablesAlready: Number(tables[0].n),
    };
  } catch (error) {
    return { reachable: false, error: error.message, code: error.code };
  }
}

async function checkPasswords() {
  const result = {};

  try {
    const bcrypt = await import('bcryptjs');
    const started = Date.now();
    const hash = await bcrypt.hash('a-test-password-not-a-real-one', 12);
    const hashedIn = Date.now() - started;

    const verifyStarted = Date.now();
    const verified = await bcrypt.compare('a-test-password-not-a-real-one', hash);

    result.bcrypt = {
      works: verified,
      hashMs: hashedIn,
      verifyMs: Date.now() - verifyStarted,
      // Cost 12 on slow shared hosting can take over a second, which makes
      // every login feel broken. If this is high, the cost comes down.
      acceptable: hashedIn < 1000,
    };
  } catch (error) {
    result.bcrypt = { works: false, error: error.message };
  }

  // argon2 is a native module. It is not in package.json by design, decision
  // 042, because a module that fails to compile fails the whole deploy with no
  // readable log. This only reports whether it happens to be present.
  try {
    await import('argon2');
    result.argon2 = { installed: true };
  } catch {
    result.argon2 = { installed: false, note: 'not installed, which is the deliberate default' };
  }

  return result;
}

async function checkUploads() {
  const directory = process.env.UPLOAD_DIR;
  if (!directory) return { configured: false };

  const probe = path.join(directory, 'probe', 'write-test.txt');

  try {
    await mkdir(path.dirname(probe), { recursive: true });
    await writeFile(probe, 'probe');
    const written = await stat(probe);
    await unlink(probe);

    return {
      configured: true,
      directory,
      writable: true,
      sizeWritten: written.size,
      // A receipt reachable over the web is a leaked supplier invoice.
      looksOutsideWebRoot: !/public_html/i.test(directory),
    };
  } catch (error) {
    return { configured: true, directory, writable: false, error: error.message };
  }
}

function checkSecrets() {
  // Values are never reported, only whether each is present and long enough.
  const required = [
    'DB_HOST', 'DB_NAME', 'DB_USER', 'DB_PASSWORD',
    'JWT_ACCESS_SECRET', 'JWT_REFRESH_SECRET', 'CORS_ORIGINS', 'UPLOAD_DIR',
  ];

  return Object.fromEntries(required.map((name) => {
    const value = process.env[name];
    const isSecret = name.includes('SECRET') || name.includes('PASSWORD');
    return [name, {
      set: Boolean(value),
      ...(isSecret && value ? { longEnough: value.length >= 32 } : {}),
    }];
  }));
}

const server = http.createServer(async (req, res) => {
  const report = {
    probe: 'winibex-accounting deploy probe',
    checkedAt: new Date().toISOString(),
    node: await checkNode(),
    database: await checkDatabase(),
    passwords: await checkPasswords(),
    uploads: await checkUploads(),
    environment: checkSecrets(),
  };

  res.writeHead(200, { 'content-type': 'application/json' });
  res.end(JSON.stringify(report, null, 2));
});

server.listen(PORT, () => {
  console.log(`Probe listening on ${PORT}`);
});
