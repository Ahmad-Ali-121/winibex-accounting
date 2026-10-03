import { Router } from 'express';
import { z } from 'zod';

import { parseOrThrow } from '../../core/errors.js';
import { requireAuth } from '../../core/auth.js';
import { idempotency } from '../../core/idempotency.js';
import * as service from './service.js';

export const reimbursementRoutes = Router();

const idParam = z.object({ id: z.coerce.number().int().positive() });

const createSchema = z.object({
  personUserId: z.number().int().positive(),
  accountId: z.number().int().positive(),
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Use a date like 2026-07-05.'),
  method: z.enum(['cash', 'account', 'card', 'cheque', 'online']).optional(),
  reference: z.string().trim().max(50).optional(),
  note: z.string().trim().max(255).optional(),
  items: z
    .array(z.object({
      transactionId: z.number().int().positive(),
      amount: z.object({
        minor: z.number().int('An amount must be a whole number of paisa.'),
        currency: z.string().length(3),
      }),
    }))
    .min(1, 'Say which costs this is paying back.')
    .max(50),
  acknowledged_warnings: z.array(z.string().max(50)).max(20).optional(),
});

function actorFrom(req) {
  return {
    id: Number(req.user.id),
    role: req.user.role,
    approvalLimit:
      req.user.approval_limit === null || req.user.approval_limit === undefined
        ? null
        : Number(req.user.approval_limit),
    autoApproveOwn: Boolean(req.user.auto_approve_own),
  };
}

reimbursementRoutes.get('/people/balances', requireAuth, async (req, res) => {
  res.json(await service.listBalances());
});

reimbursementRoutes.get('/people/:id/outstanding', requireAuth, async (req, res) => {
  const { id } = parseOrThrow(idParam, req.params);
  res.json(await service.outstandingFor(id));
});

reimbursementRoutes.post(
  '/reimbursements',
  requireAuth,
  idempotency({ required: true }),
  async (req, res) => {
    const body = parseOrThrow(createSchema, req.body ?? {});

    const created = await service.createReimbursement({
      user: actorFrom(req),
      ip: req.ip,
      input: {
        personUserId: body.personUserId,
        accountId: body.accountId,
        date: body.date,
        method: body.method,
        reference: body.reference,
        note: body.note,
        items: body.items.map((item) => ({
          transactionId: item.transactionId,
          amount: item.amount.minor,
        })),
        acknowledgedWarnings: body.acknowledged_warnings ?? [],
      },
    });

    res.status(201).json({ reimbursement: created });
  },
);
