import { Router } from 'express';
import { z } from 'zod';

import { parseOrThrow } from '../../core/errors.js';
import { requireAuth } from '../../core/auth.js';
import * as service from './service.js';

// The owner's ledger codes screen and its bulk import. Decisions 068, 069.
export const ledgerCodeRoutes = Router();

const idParam = z.object({ id: z.coerce.number().int().positive() });

const nameField = z
  .string()
  .trim()
  .min(3, 'Give it a name of at least 3 letters.')
  .max(100, 'Keep the name under 100 letters.');

const codeField = z.string().trim().regex(/^[1-9]\d{3}$/, 'Use four digits that do not start with 0, such as 6960.');

const createBody = z.object({
  code: codeField,
  name: nameField,
  kind: z.enum(['code', 'heading']).optional().default('code'),
  parentCode: codeField.nullable().optional(),
  addToEntryForm: z.boolean().optional().default(true),
});

const updateBody = z
  .object({ name: nameField.optional(), parentCode: codeField.optional() })
  .refine((body) => body.name !== undefined || body.parentCode !== undefined, 'Say what to change.');

const activeBody = z.object({ isActive: z.boolean() });

const importBody = z.object({
  csv: z.string().min(1, 'The file is empty.').max(900000, 'The file is too large. Split it into smaller files.'),
  apply: z.boolean().optional().default(false),
});

function actorFrom(req) {
  return { id: Number(req.user.id), role: req.user.role };
}

ledgerCodeRoutes.get('/ledger-codes', requireAuth, async (req, res) => {
  res.json(await service.listCodes({ user: actorFrom(req) }));
});

ledgerCodeRoutes.get('/ledger-codes/template', requireAuth, (req, res) => {
  res.json(service.templateCsv({ user: actorFrom(req) }));
});

ledgerCodeRoutes.get('/ledger-codes/export', requireAuth, async (req, res) => {
  res.json(await service.exportCsv({ user: actorFrom(req) }));
});

ledgerCodeRoutes.post('/ledger-codes/import', requireAuth, async (req, res) => {
  const { csv, apply } = parseOrThrow(importBody, req.body ?? {});
  res.json(await service.importCodes({ user: actorFrom(req), csv, apply, ip: req.ip }));
});

ledgerCodeRoutes.post('/ledger-codes', requireAuth, async (req, res) => {
  const input = parseOrThrow(createBody, req.body ?? {});
  res.status(201).json({ code: await service.createCode({ user: actorFrom(req), input, ip: req.ip }) });
});

ledgerCodeRoutes.patch('/ledger-codes/:id', requireAuth, async (req, res) => {
  const { id } = parseOrThrow(idParam, req.params);
  const input = parseOrThrow(updateBody, req.body ?? {});
  res.json({ code: await service.updateCode({ user: actorFrom(req), id, input, ip: req.ip }) });
});

ledgerCodeRoutes.post('/ledger-codes/:id/active', requireAuth, async (req, res) => {
  const { id } = parseOrThrow(idParam, req.params);
  const { isActive } = parseOrThrow(activeBody, req.body ?? {});
  res.json({ code: await service.setCodeActive({ user: actorFrom(req), id, isActive, ip: req.ip }) });
});
