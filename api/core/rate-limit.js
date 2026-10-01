// A small fixed-window limiter, held in memory.
//
// In memory is the right scope here: one Node process on Hostinger, four
// users. A shared store would be a dependency and a second thing to operate,
// for no gain.
//
// Only failed requests count. Signing in successfully ten times in a morning
// is normal and must never contribute to a lockout; ten wrong passwords is
// the thing worth stopping.

import { AppError, ErrorCode } from './errors.js';

export function createRateLimiter({
  windowMs,
  limit,
  keyOf,
  message = 'Too many attempts. Try again in a few minutes.',
}) {
  const hits = new Map();

  function entryFor(key, now) {
    const existing = hits.get(key);
    if (existing && now < existing.resetAt) return existing;
    const fresh = { count: 0, resetAt: now + windowMs };
    hits.set(key, fresh);
    return fresh;
  }

  function sweep(now) {
    if (hits.size < 500) return;
    for (const [key, entry] of hits) {
      if (now >= entry.resetAt) hits.delete(key);
    }
  }

  function limiter(req, res, next) {
    const now = Date.now();
    sweep(now);

    const key = keyOf(req);
    const entry = entryFor(key, now);

    if (entry.count >= limit) {
      const retryAfter = Math.ceil((entry.resetAt - now) / 1000);
      res.set('Retry-After', String(retryAfter));
      return next(new AppError(429, ErrorCode.RATE_LIMITED, message));
    }

    res.on('finish', () => {
      if (res.statusCode >= 400) entry.count += 1;
    });

    return next();
  }

  limiter.reset = () => hits.clear();
  return limiter;
}
