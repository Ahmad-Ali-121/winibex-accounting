// Two different kinds of token, on purpose.
//
// The access token is a short-lived JWT. It is not stored anywhere, so it
// cannot be revoked, which is why it expires in minutes.
//
// The refresh token is a long random string. Only its SHA-256 hash is stored,
// so a leaked database does not hand anyone a working session. It rotates on
// every use and belongs to a family: if an old one is ever presented again,
// that means a copy is in circulation, and the whole family is revoked.

import crypto from 'node:crypto';
import jwt from 'jsonwebtoken';

import { auth } from './config.js';
import { AppError, ErrorCode } from './errors.js';

const ISSUER = 'winibex-accounting';

export function signAccessToken(user) {
  return jwt.sign(
    { role: user.role, name: user.name, mustChangePassword: Boolean(user.must_change_password) },
    auth.accessSecret,
    {
      subject: String(user.id),
      issuer: ISSUER,
      expiresIn: `${auth.accessTokenMinutes}m`,
    },
  );
}

export function verifyAccessToken(token) {
  try {
    return jwt.verify(token, auth.accessSecret, { issuer: ISSUER });
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      throw new AppError(401, ErrorCode.TOKEN_EXPIRED, 'Your session has expired. Sign in again.');
    }
    throw new AppError(401, ErrorCode.TOKEN_INVALID, 'That session is not valid.');
  }
}

export function createRefreshToken() {
  const token = crypto.randomBytes(48).toString('base64url');
  return { token, hash: hashRefreshToken(token) };
}

export function hashRefreshToken(token) {
  return crypto.createHash('sha256').update(token).digest('hex');
}

export function refreshExpiryDate(from = new Date()) {
  const expires = new Date(from);
  expires.setUTCDate(expires.getUTCDate() + auth.refreshTokenDays);
  return expires;
}

// MariaDB DATETIME wants 'YYYY-MM-DD HH:MM:SS' with no zone marker. Everything
// is stored UTC, so the ISO string is simply trimmed.
export function toSqlDateTime(date) {
  return date.toISOString().slice(0, 19).replace('T', ' ');
}

export function newFamilyId() {
  return crypto.randomUUID();
}
