import { Router } from 'express';

import { parseOrThrow } from '../../core/errors.js';
import { requireAuth } from '../../core/auth.js';
import { idempotency } from '../../core/idempotency.js';
import * as service from './service.js';
import { z } from 'zod';

import {
  createTransactionSchema,
  updateTransactionSchema,
  reasonSchema,
  idParamSchema,
  transferSchema,
  toServiceInput,
} from './schema.js';

export const transactionRoutes = Router();

// req.user is the database row, so its fields are snake_case. The service
// speaks in camelCase and should not have to know where its caller came from,
// since the MCP server in Phase 9 will call it with no request at all.
function actorFrom(req) {
  const user = req.user;
  return {
    id: Number(user.id),
    role: user.role,
    approvalLimit:
      user.approval_limit === null || user.approval_limit === undefined
        ? null
        : Number(user.approval_limit),
    autoApproveOwn: Boolean(user.auto_approve_own),
  };
}

// Every request that creates or posts money carries an Idempotency-Key, so a
// double tap or a dropped mobile connection cannot post the same expense
// twice. Decision 024.
const money = idempotency({ required: true });

transactionRoutes.post('/transactions', requireAuth, money, async (req, res) => {
  const body = parseOrThrow(createTransactionSchema, req.body ?? {});
  const created = await service.createDraft({
    user: actorFrom(req),
    input: toServiceInput(body),
    ip: req.ip,
  });
  res.status(201).json({ transaction: created });
});

const ledgerQuery = z.object({
  search: z.string().trim().max(100).optional(),
  accountId: z.coerce.number().int().positive().optional(),
  categoryId: z.coerce.number().int().positive().optional(),
  status: z.enum(['draft', 'pending', 'posted', 'rejected', 'reversed']).optional(),
  direction: z.enum(['in', 'out']).optional(),
  from: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
  to: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
  page: z.coerce.number().int().positive().optional(),
  pageSize: z.coerce.number().int().positive().max(100).optional(),
});

// Search and filtering run on the server. The app holds one page, so
// searching what it holds would miss everything else. Decision 022.
transactionRoutes.get('/transactions', requireAuth, async (req, res) => {
  const filters = parseOrThrow(ledgerQuery, req.query ?? {});
  res.json(await service.listTransactions({ user: actorFrom(req), filters }));
});

transactionRoutes.get('/approvals', requireAuth, async (req, res) => {
  res.json(await service.listApprovals({ user: actorFrom(req) }));
});

const flagsQuery = z.object({
  resolved: z.enum(['true', 'false']).optional(),
  severity: z.enum(['warning', 'flag']).optional(),
});

transactionRoutes.get('/flags', requireAuth, async (req, res) => {
  const query = parseOrThrow(flagsQuery, req.query ?? {});
  res.json(await service.listFlags({
    resolved: query.resolved === 'true',
    severity: query.severity ?? null,
  }));
});

// The journal entry this draft would produce, worked out but not saved. The
// app shows it before the person commits; it never builds it itself.
transactionRoutes.post('/transactions/preview', requireAuth, async (req, res) => {
  const body = parseOrThrow(createTransactionSchema, req.body ?? {});
  res.json(await service.previewJournal({ input: toServiceInput(body) }));
});

transactionRoutes.patch('/transactions/:id', requireAuth, async (req, res) => {
  const { id } = parseOrThrow(idParamSchema, req.params);
  const body = parseOrThrow(updateTransactionSchema, req.body ?? {});

  const updated = await service.updateDraft({
    user: actorFrom(req),
    id,
    input: toServiceInput(body),
    ip: req.ip,
  });
  res.json({ transaction: updated });
});

transactionRoutes.post('/transactions/:id/submit', requireAuth, async (req, res) => {
  const { id } = parseOrThrow(idParamSchema, req.params);
  res.json(await service.submitForApproval({ user: actorFrom(req), id, ip: req.ip }));
});

transactionRoutes.post('/transactions/:id/approve', requireAuth, money, async (req, res) => {
  const { id } = parseOrThrow(idParamSchema, req.params);
  res.json(await service.approve({ user: actorFrom(req), id, ip: req.ip }));
});

transactionRoutes.post('/transactions/:id/reject', requireAuth, async (req, res) => {
  const { id } = parseOrThrow(idParamSchema, req.params);
  const { reason } = parseOrThrow(reasonSchema, req.body ?? {});
  res.json(await service.reject({ user: actorFrom(req), id, reason, ip: req.ip }));
});

transactionRoutes.post('/transactions/:id/reverse', requireAuth, money, async (req, res) => {
  const { id } = parseOrThrow(idParamSchema, req.params);
  const { reason } = parseOrThrow(reasonSchema, req.body ?? {});
  res.json(await service.reverse({ user: actorFrom(req), id, reason, ip: req.ip }));
});

// A transfer is two legs, created and posted together or not at all.
transactionRoutes.post('/transfers', requireAuth, money, async (req, res) => {
  const body = parseOrThrow(transferSchema, req.body ?? {});

  const transfer = await service.createTransfer({
    user: actorFrom(req),
    ip: req.ip,
    input: {
      date: body.date,
      fromAccountId: body.fromAccountId,
      toAccountId: body.toAccountId,
      amount: body.amount.minor,
      fee: body.fee ? body.fee.minor : 0,
      method: body.method,
      description: body.description,
      reference: body.reference,
      acknowledgedWarnings: body.acknowledged_warnings ?? [],
    },
  });

  res.status(201).json({ transfer });
});

transactionRoutes.get('/transfers/:groupId', requireAuth, async (req, res) => {
  res.json(await service.getTransfer(String(req.params.groupId)));
});

transactionRoutes.get('/transactions/:id', requireAuth, async (req, res) => {
  const { id } = parseOrThrow(idParamSchema, req.params);
  res.json(await service.getDetail(id));
});

// The journal preview and the read-only view behind "View journal entry" on
// every posted transaction, required by docs/UI-GUIDE.md.
transactionRoutes.get('/transactions/:id/journal', requireAuth, async (req, res) => {
  const { id } = parseOrThrow(idParamSchema, req.params);
  const detail = await service.getDetail(id);
  res.json({ journalNumber: detail.transaction.journal_number, lines: detail.lines });
});
