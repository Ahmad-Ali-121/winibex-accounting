// Throwaway deploy probe for step 0.1.
//
// It answers one question: does this code actually run on Hostinger? It
// reports the Node version and proves password hashing works end to end on
// the real server, before login is built on top of it.
//
// Two ways to run it:
//   node scripts/probe-deploy.js            once, prints the result, exits
//   node scripts/probe-deploy.js --serve    web page, for the Hostinger deploy
//
// Nothing here touches the database and no secret is involved. Delete this
// file once step 0.6 lands the real server.

import http from 'node:http';
import process from 'node:process';
import { hashPassword, verifyPassword, configuredAlgorithm } from '../core/password.js';

const SAMPLE_PASSWORD = 'winibex-probe-password';

async function runProbe() {
  const started = Date.now();
  const result = {
    ok: false,
    algorithm: null,
    nodeVersion: process.version,
    platform: process.platform,
    arch: process.arch,
    hashed: false,
    verifiedCorrect: null,
    rejectedWrong: null,
    durationMs: null,
    error: null,
  };

  try {
    result.algorithm = configuredAlgorithm();

    const hash = await hashPassword(SAMPLE_PASSWORD);
    result.hashed = true;
    result.hashPrefix = hash.slice(0, hash.lastIndexOf('$') + 1);

    result.verifiedCorrect = await verifyPassword(hash, SAMPLE_PASSWORD);
    result.rejectedWrong = !(await verifyPassword(hash, 'not-the-password'));
    result.ok = result.verifiedCorrect === true && result.rejectedWrong === true;
  } catch (error) {
    result.error = error instanceof Error ? error.message : String(error);
  }

  result.durationMs = Date.now() - started;
  return result;
}

function serve() {
  const port = Number(process.env.PORT ?? 3000);

  const server = http.createServer(async (req, res) => {
    const result = await runProbe();
    res.writeHead(result.ok ? 200 : 500, {
      'content-type': 'application/json; charset=utf-8',
      'cache-control': 'no-store',
    });
    res.end(JSON.stringify(result, null, 2));
  });

  server.listen(port, () => {
    console.log(`argon2 probe listening on ${port}`);
  });
}

// Explicit flag only. PORT is set in the local .env, so keying off it would
// make the one-shot run silently start a server instead.
if (process.argv.includes('--serve')) {
  serve();
} else {
  const result = await runProbe();
  console.log(JSON.stringify(result, null, 2));
  process.exit(result.ok ? 0 : 1);
}
