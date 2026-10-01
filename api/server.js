// Entry point. Everything it checks here is something that would otherwise
// show up later as a confusing failure in the middle of a user's request.

import process from 'node:process';

import { createApp } from './app.js';
import { assertConfig, config } from './core/config.js';
import { getPool, assertSession, ping, closePool } from './core/db.js';

async function start() {
  assertConfig();

  const version = await ping();
  await assertSession(getPool());
  console.log(`Database: ${config.db.database} (${version})`);

  const app = createApp();
  const server = app.listen(config.port, () => {
    console.log(`API listening on ${config.port} in ${config.env} mode`);
  });

  const shutdown = (signal) => {
    console.log(`\n${signal} received, shutting down.`);
    server.close(async () => {
      await closePool();
      process.exit(0);
    });
    // If a request hangs, do not wait forever.
    setTimeout(() => process.exit(1), 10000).unref();
  };

  process.on('SIGTERM', () => shutdown('SIGTERM'));
  process.on('SIGINT', () => shutdown('SIGINT'));
}

start().catch(async (error) => {
  console.error(`\nFailed to start: ${error.message}`);
  await closePool().catch(() => {});
  process.exit(1);
});
