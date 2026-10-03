import { Router } from 'express';
import { z } from 'zod';

import { parseOrThrow } from '../../core/errors.js';
import { requireAuth } from '../../core/auth.js';
import * as service from './service.js';

export const vendorRoutes = Router();

const idParam = z.object({ id: z.coerce.number().int().positive() });

const listQuery = z.object({
  q: z.string().trim().max(100).optional(),
  includeInactive: z.enum(['true', 'false']).optional(),
});

const vendorBody = z.object({
  name: z.string().trim().min(1, 'A vendor needs a name.').max(150),
  kind: z.enum(['company', 'aop', 'individual', 'foreign']),
  ntn: z.string().trim().max(20).optional(),
  cnic: z.string().trim().max(20).optional(),
  strn: z.string().trim().max(20).optional(),
  atlStatus: z.enum(['atl', 'non_atl', 'unknown']).optional(),
  atlCheckedOn: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
  defaultTaxId: z.number().int().positive().optional(),
  country: z.string().trim().max(60).optional(),
  email: z.string().trim().email().max(190).optional(),
  phone: z.string().trim().max(40).optional(),
  notes: z.string().trim().max(1000).optional(),
});

const vendorChanges = vendorBody.partial().extend({ isActive: z.boolean().optional() });

function actorFrom(req) {
  return { id: Number(req.user.id), role: req.user.role };
}

vendorRoutes.get('/vendors', requireAuth, async (req, res) => {
  const query = parseOrThrow(listQuery, req.query ?? {});
  res.json(await service.listVendors({
    search: query.q ?? null,
    includeInactive: query.includeInactive === 'true',
  }));
});

vendorRoutes.get('/vendors/:id', requireAuth, async (req, res) => {
  const { id } = parseOrThrow(idParam, req.params);
  res.json({ vendor: await service.getVendor(id) });
});

vendorRoutes.post('/vendors', requireAuth, async (req, res) => {
  const body = parseOrThrow(vendorBody, req.body ?? {});
  const vendor = await service.createVendor({ user: actorFrom(req), input: body, ip: req.ip });
  res.status(201).json({ vendor });
});

vendorRoutes.patch('/vendors/:id', requireAuth, async (req, res) => {
  const { id } = parseOrThrow(idParam, req.params);
  const changes = parseOrThrow(vendorChanges, req.body ?? {});
  const vendor = await service.updateVendor({ user: actorFrom(req), id, changes, ip: req.ip });
  res.json({ vendor });
});
