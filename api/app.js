import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import cookieParser from 'cookie-parser';

import { errorHandler, notFoundHandler } from './core/errors.js';
import { isProduction } from './core/config.js';
import { healthRoutes } from './modules/health/routes.js';
import { authRoutes } from './modules/auth/routes.js';
import { accountRoutes } from './modules/accounts/routes.js';
import { transactionRoutes } from './modules/transactions/routes.js';
import { taxRoutes } from './modules/taxes/routes.js';
import { reimbursementRoutes } from './modules/reimbursements/routes.js';
import { vendorRoutes } from './modules/vendors/routes.js';
import { chequeRoutes } from './modules/cheques/routes.js';
import { historyRoutes } from './modules/history/routes.js';
import { categoryRoutes } from './modules/categories/routes.js';
import { userRoutes } from './modules/users/routes.js';
import { attachmentRoutes } from './modules/attachments/routes.js';

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
  app.use(API_PREFIX, accountRoutes);
  app.use(API_PREFIX, transactionRoutes);
  app.use(API_PREFIX, taxRoutes);
  app.use(API_PREFIX, reimbursementRoutes);
  app.use(API_PREFIX, vendorRoutes);
  app.use(API_PREFIX, chequeRoutes);
  app.use(API_PREFIX, historyRoutes);
  app.use(API_PREFIX, categoryRoutes);
  app.use(API_PREFIX, userRoutes);
  app.use(API_PREFIX, attachmentRoutes);

  app.use(notFoundHandler);
  app.use(errorHandler);

  if (!isProduction) {
    app.set('json spaces', 2);
  }

  return app;
}
