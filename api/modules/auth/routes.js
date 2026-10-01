import { Router } from 'express';
import { z } from 'zod';

import { parseOrThrow, unauthorized, ErrorCode } from '../../core/errors.js';
import { createRateLimiter } from '../../core/rate-limit.js';
import { requireAuth } from '../../core/auth.js';
import { isProduction, auth as authConfig } from '../../core/config.js';
import * as service from './service.js';

export const authRoutes = Router();

const REFRESH_COOKIE = 'winibex_refresh';

const loginSchema = z.object({
  email: z.string().trim().toLowerCase().email('Enter a valid email address.').max(190),
  password: z.string().min(1, 'Enter your password.').max(1024),
});

// Five failed attempts per fifteen minutes, counted per IP and email address
// together, so one person guessing cannot lock out everyone behind an office
// connection, and attempts on one account cannot be spread across hosts.
export const loginLimiter = createRateLimiter({
  windowMs: 15 * 60 * 1000,
  limit: 5,
  keyOf: (req) => `${req.ip}|${String(req.body?.email ?? '').toLowerCase()}`,
  message: 'Too many sign-in attempts. Try again in a few minutes.',
});

function setRefreshCookie(res, token, expiresAt) {
  res.cookie(REFRESH_COOKIE, token, {
    httpOnly: true,
    secure: isProduction,
    sameSite: 'strict',
    expires: expiresAt,
    path: '/api/v1/auth',
  });
}

function readRefreshToken(req) {
  // Web sends it as an httpOnly cookie. Android has no cookie jar, so it sends
  // it in the body from secure storage.
  return req.cookies?.[REFRESH_COOKIE] ?? req.body?.refreshToken ?? null;
}

authRoutes.post('/auth/login', loginLimiter, async (req, res) => {
  const { email, password } = parseOrThrow(loginSchema, req.body ?? {});

  const session = await service.login({
    email,
    password,
    ip: req.ip,
    userAgent: req.get('user-agent'),
  });

  setRefreshCookie(res, session.refreshToken, session.refreshExpiresAt);

  res.json({
    accessToken: session.accessToken,
    refreshToken: session.refreshToken,
    expiresInMinutes: authConfig.accessTokenMinutes,
    user: session.user,
  });
});

authRoutes.post('/auth/refresh', async (req, res) => {
  const token = readRefreshToken(req);
  if (!token) {
    throw unauthorized(ErrorCode.NOT_AUTHENTICATED, 'Sign in to continue.');
  }

  const session = await service.refresh({
    refreshToken: token,
    ip: req.ip,
    userAgent: req.get('user-agent'),
  });

  setRefreshCookie(res, session.refreshToken, session.refreshExpiresAt);

  res.json({
    accessToken: session.accessToken,
    refreshToken: session.refreshToken,
    expiresInMinutes: authConfig.accessTokenMinutes,
    user: session.user,
  });
});

authRoutes.post('/auth/logout', async (req, res) => {
  await service.logout({ refreshToken: readRefreshToken(req) });
  res.clearCookie(REFRESH_COOKIE, { path: '/api/v1/auth' });
  res.json({ status: 'signed out' });
});

authRoutes.get('/me', requireAuth, (req, res) => {
  res.json({ user: service.publicUser(req.user) });
});
