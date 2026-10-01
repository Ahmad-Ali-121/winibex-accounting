// Reads environment variables once, checks them, and fails loudly at startup
// if something is missing. A missing database password should stop the process
// immediately, not surface as a confusing error on the first login attempt.

import process from 'node:process';

const REQUIRED = [
  'DB_HOST',
  'DB_PORT',
  'DB_NAME',
  'DB_USER',
  'DB_PASSWORD',
  'JWT_ACCESS_SECRET',
  'JWT_REFRESH_SECRET',
];

function missingKeys() {
  return REQUIRED.filter((key) => {
    const value = process.env[key];
    return value === undefined || value === '';
  });
}

export function assertConfig() {
  const missing = missingKeys();
  if (missing.length > 0) {
    throw new Error(
      `Missing environment variables: ${missing.join(', ')}. ` +
        'Copy api/.env.example to api/.env and fill it in.',
    );
  }
}

function intFrom(name, fallback) {
  const raw = process.env[name];
  if (raw === undefined || raw === '') return fallback;
  const value = Number.parseInt(raw, 10);
  if (Number.isNaN(value)) {
    throw new Error(`${name} must be a whole number, received "${raw}"`);
  }
  return value;
}

export const config = {
  env: process.env.NODE_ENV ?? 'development',
  port: intFrom('PORT', 3000),

  db: {
    host: process.env.DB_HOST,
    port: intFrom('DB_PORT', 3306),
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    // A getter, not a value, so a test run can point the pool at the test
    // database by setting DB_NAME before the pool is first opened.
    get database() {
      return process.env.DB_NAME;
    },
    // Hostinger allows 75 connections per database user. Staying well under
    // leaves room for phpMyAdmin, the cron job and a second deploy.
    connectionLimit: intFrom('DB_POOL_SIZE', 8),
  },

  // Tests point at this instead. It must never equal db.database.
  testDatabase: process.env.DB_TEST_NAME,
};

export const isProduction = config.env === 'production';

export const auth = {
  get accessSecret() {
    return process.env.JWT_ACCESS_SECRET;
  },
  get refreshSecret() {
    return process.env.JWT_REFRESH_SECRET;
  },
  accessTokenMinutes: intFrom('ACCESS_TOKEN_MINUTES', 15),
  refreshTokenDays: intFrom('REFRESH_TOKEN_DAYS', 30),
};
