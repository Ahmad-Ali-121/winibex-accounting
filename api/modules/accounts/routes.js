import { Router } from 'express';
import { z } from 'zod';

import { parseOrThrow } from '../../core/errors.js';
import { requireAuth } from '../../core/auth.js';
import * as service from './service.js';

export const accountRoutes = Router();

const listQuery = z.object({
  includeInactive: z.enum(['true', 'false']).optional(),
});

const idParam = z.object({
  id: z.coerce.number().int().positive(),
});

// Open item D in docs/DECISIONS.md is still undecided: whether staff see the
// company balance at all, or only their own submissions. Until it is decided
// this needs a login and nothing more, which is the behaviour today.
accountRoutes.get('/accounts', requireAuth, async (req, res) => {
  const query = parseOrThrow(listQuery, req.query ?? {});
  res.json(await service.listAccounts({ includeInactive: query.includeInactive === 'true' }));
});

accountRoutes.get('/dashboard', requireAuth, async (req, res) => {
  res.json(await service.dashboard());
});

// Declared before /accounts/:id, or Express matches "petty-cash" as an id.
accountRoutes.get('/accounts/petty-cash', requireAuth, async (req, res) => {
  res.json(await service.pettyCashStatus());
});

accountRoutes.get('/accounts/:id', requireAuth, async (req, res) => {
  const { id } = parseOrThrow(idParam, req.params);
  res.json({ account: await service.getAccount(id) });
});
