import { Router } from 'express';
import { z } from 'zod';

import { parseOrThrow } from '../../core/errors.js';
import { requireAuth } from '../../core/auth.js';
import * as service from './service.js';

export const chequeRoutes = Router();

const idParam = z.object({ id: z.coerce.number().int().positive() });
const dateString = z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Use a date like 2026-07-05.');

const listQuery = z.object({
  accountId: z.coerce.number().int().positive().optional(),
  status: z.enum(['issued', 'presented', 'cleared', 'bounced', 'cancelled']).optional(),
});

const issueBody = z.object({
  accountId: z.number().int().positive(),
  chequeNumber: z.string().trim().min(1, 'A cheque has a number.').max(30),
  payee: z.string().trim().min(1, 'Say who it is made out to.').max(150),
  amount: z.object({
    minor: z.number().int('An amount must be a whole number of paisa.').positive(),
    currency: z.string().length(3),
  }),
  issueDate: dateString,
  transactionId: z.number().int().positive().optional(),
  note: z.string().trim().max(255).optional(),
});

const statusBody = z.object({
  status: z.enum(['presented', 'cleared', 'bounced', 'cancelled']),
  clearedOn: dateString.optional(),
});

const linkBody = z.object({ transactionId: z.number().int().positive() });

function actorFrom(req) {
  return { id: Number(req.user.id), role: req.user.role };
}

chequeRoutes.get('/cheques', requireAuth, async (req, res) => {
  const query = parseOrThrow(listQuery, req.query ?? {});
  res.json(await service.listCheques({
    accountId: query.accountId ?? null,
    status: query.status ?? null,
  }));
});

chequeRoutes.get('/cheques/:id', requireAuth, async (req, res) => {
  const { id } = parseOrThrow(idParam, req.params);
  res.json({ cheque: await service.getCheque(id) });
});

chequeRoutes.post('/cheques', requireAuth, async (req, res) => {
  const body = parseOrThrow(issueBody, req.body ?? {});
  const cheque = await service.issueCheque({
    user: actorFrom(req),
    ip: req.ip,
    input: { ...body, amount: body.amount.minor },
  });
  res.status(201).json({ cheque });
});

chequeRoutes.patch('/cheques/:id/status', requireAuth, async (req, res) => {
  const { id } = parseOrThrow(idParam, req.params);
  const body = parseOrThrow(statusBody, req.body ?? {});
  const cheque = await service.changeStatus({
    user: actorFrom(req), id, status: body.status, clearedOn: body.clearedOn ?? null, ip: req.ip,
  });
  res.json({ cheque });
});

chequeRoutes.patch('/cheques/:id/transaction', requireAuth, async (req, res) => {
  const { id } = parseOrThrow(idParam, req.params);
  const body = parseOrThrow(linkBody, req.body ?? {});
  const cheque = await service.linkToTransaction({
    user: actorFrom(req), id, transactionId: body.transactionId, ip: req.ip,
  });
  res.json({ cheque });
});
