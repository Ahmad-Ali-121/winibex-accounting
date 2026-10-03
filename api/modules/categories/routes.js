import { Router } from 'express';
import { z } from 'zod';

import { parseOrThrow } from '../../core/errors.js';
import { requireAuth } from '../../core/auth.js';
import * as service from './service.js';

export const categoryRoutes = Router();

const listQuery = z.object({
  direction: z.enum(['in', 'out']).optional(),
});

categoryRoutes.get('/categories', requireAuth, async (req, res) => {
  const query = parseOrThrow(listQuery, req.query ?? {});
  res.json(await service.listCategories({ direction: query.direction ?? null }));
});
