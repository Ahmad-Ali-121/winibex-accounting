import { Router } from 'express';
import { z } from 'zod';

import { parseOrThrow } from '../../core/errors.js';
import { requireAuth } from '../../core/auth.js';
import * as service from './service.js';

export const taxRoutes = Router();

const dateString = z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Use a date like 2026-07-05.');

const listQuery = z.object({ date: dateString.optional() });

const suggestQuery = z.object({
  date: dateString.optional(),
  direction: z.enum(['in', 'out']),
  base: z.coerce.number().int().positive('A base amount is needed to work out a tax.'),
  currency: z.string().length(3).optional(),
  accountType: z.enum(['bank', 'cash', 'petty_cash', 'cheque', 'pass_through']).optional(),
  categoryId: z.coerce.number().int().positive().optional(),
  clientCountry: z.string().max(60).optional(),
  vendorId: z.coerce.number().int().positive().optional(),
});

taxRoutes.get('/taxes', requireAuth, async (req, res) => {
  const query = parseOrThrow(listQuery, req.query ?? {});
  res.json(await service.listTaxes({ date: query.date }));
});

// What the entry form offers for a draft situation. A suggestion, never a
// decision: every line it returns is editable and removable.
taxRoutes.get('/taxes/suggest', requireAuth, async (req, res) => {
  const query = parseOrThrow(suggestQuery, req.query ?? {});
  res.json(await service.suggestFor({
    date: query.date,
    direction: query.direction,
    baseAmount: query.base,
    currency: query.currency,
    accountType: query.accountType,
    categoryId: query.categoryId,
    clientCountry: query.clientCountry,
    vendorId: query.vendorId,
  }));
});
