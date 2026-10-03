import { Router } from 'express';
import { z } from 'zod';

import { parseOrThrow } from '../../core/errors.js';
import { requireAuth } from '../../core/auth.js';
import { idempotency } from '../../core/idempotency.js';
import * as service from './service.js';

export const historyRoutes = Router();

const openingBody = z.object({
  description: z.string().trim().max(255).optional(),
  balances: z
    .array(z.object({
      code: z.string().trim().min(1).max(10),
      // Positive on the account's own normal side: a bank holding money, a
      // loan owed. Negative only for the unusual case of an account sitting on
      // the wrong side, such as an overdrawn bank account.
      amount: z.number().int('A balance must be a whole number of paisa.'),
    }))
    .min(1, 'The opening entry needs the balances it is opening with.')
    .max(200),
  acknowledged_warnings: z.array(z.string().max(50)).max(20).optional(),
});

function actorFrom(req) {
  return { id: Number(req.user.id), role: req.user.role };
}

historyRoutes.post('/opening-entry', requireAuth, idempotency({ required: true }), async (req, res) => {
  const body = parseOrThrow(openingBody, req.body ?? {});

  const created = await service.createOpeningEntry({
    user: actorFrom(req),
    ip: req.ip,
    input: {
      description: body.description,
      balances: body.balances,
      acknowledgedWarnings: body.acknowledged_warnings ?? [],
    },
  });

  res.status(201).json({ openingEntry: created });
});

historyRoutes.get('/history/merge-check', requireAuth, async (req, res) => {
  res.json(await service.mergeCheck());
});

historyRoutes.post('/history/merge', requireAuth, idempotency({ required: true }), async (req, res) => {
  res.json(await service.merge({ user: actorFrom(req), ip: req.ip }));
});
