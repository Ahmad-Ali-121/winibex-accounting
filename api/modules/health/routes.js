import { Router } from 'express';

import { ping } from '../../core/db.js';
import { AppError, ErrorCode } from '../../core/errors.js';

export const healthRoutes = Router();

// Open, no authentication. It says whether the service is up and whether it
// can reach the database, and nothing else. No version numbers, no paths.
healthRoutes.get('/health', async (req, res) => {
  try {
    await ping();
  } catch {
    throw new AppError(
      503,
      ErrorCode.DATABASE_UNAVAILABLE,
      'The service cannot reach its database.',
    );
  }

  res.json({
    status: 'ok',
    database: 'ok',
    uptimeSeconds: Math.floor(process.uptime()),
  });
});
