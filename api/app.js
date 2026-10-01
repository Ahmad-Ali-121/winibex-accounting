import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import cookieParser from 'cookie-parser';

import { errorHandler, notFoundHandler } from './core/errors.js';
import { isProduction } from './core/config.js';
import { healthRoutes } from './modules/health/routes.js';
import { authRoutes } from './modules/auth/routes.js';

export const API_PREFIX = '/api/v1';

function allowedOrigins() {
  const raw = process.env.CORS_ORIGINS ?? '';
  return raw
    .split(',')
    .map((value) => value.trim())
    .filter(Boolean);
}

export function createApp() {
  const app = express();

  // Hostinger puts the app behind its own proxy, so req.ip must come from the
  // forwarded header or every user looks like the same address and the login
  // rate limit locks out the whole company at once.
  app.set('trust proxy', 1);
  app.disable('x-powered-by');

  app.use(helmet());
  app.use(
    cors({
      origin: allowedOrigins(),
      credentials: true,
    }),
  );
  app.use(express.json({ limit: '1mb' }));
  app.use(cookieParser());

  app.use(API_PREFIX, healthRoutes);
  app.use(API_PREFIX, authRoutes);

  app.use(notFoundHandler);
  app.use(errorHandler);

  if (!isProduction) {
    app.set('json spaces', 2);
  }

  return app;
}
