import { Router } from 'express';
import { z } from 'zod';

import { parseOrThrow } from '../../core/errors.js';
import { requireAuth } from '../../core/auth.js';
import * as service from './service.js';
import * as manage from './manage.js';
import * as bulk from './import.js';

export const taxRoutes = Router();

const dateString = z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Use a date like 2026-07-05.');

const directionEnum = z.enum(['in', 'out']);

// direction narrows the list to taxes that can sit on that kind of entry, so
// the form never offers a sales tax on a payment. Decision 064.
const listQuery = z.object({ date: dateString.optional(), direction: directionEnum.optional() });

const suggestQuery = z.object({
  date: dateString.optional(),
  direction: directionEnum,
  base: z.coerce.number().int().positive('A base amount is needed to work out a tax.'),
  currency: z.string().length(3).optional(),
  accountType: z.enum(['bank', 'cash', 'petty_cash', 'cheque', 'pass_through']).optional(),
  categoryId: z.coerce.number().int().positive().optional(),
  clientCountry: z.string().max(60).optional(),
  vendorId: z.coerce.number().int().positive().optional(),
  // Work out these taxes instead of the suggested ones: "12" or "12,15".
  // Used when the person adds a tax by hand, so the app never computes one.
  taxIds: z.string().regex(/^\d+(,\d+)*$/, 'List tax ids separated by commas.').optional(),
});

taxRoutes.get('/taxes', requireAuth, async (req, res) => {
  const query = parseOrThrow(listQuery, req.query ?? {});
  res.json(await service.listTaxes({ date: query.date, direction: query.direction }));
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
    taxIds: query.taxIds ? query.taxIds.split(',').map(Number) : null,
  }));
});

// --- the taxes screen: the owner's, decision 067 ------------------------------

const rateString = z.string().regex(/^\d+(\.\d{1,4})?$/, 'A rate is a number with up to four decimal places.');
const idParam = z.object({ id: z.coerce.number().int().positive() });

const createBody = z.object({
  name: z.string().trim().min(1, 'Give the tax a name.').max(150),
  shortCode: z.string().trim().min(1, 'Give it a short code, such as 153-IT.').max(20),
  authority: z.enum(['fbr', 'pra', 'srb', 'ict', 'bank', 'other']),
  lawReference: z.string().trim().max(50).optional(),
  kind: z.enum(['withholding', 'final', 'advance', 'sales_tax', 'fed', 'other']),
  appliesTo: z.enum(['sales', 'purchases', 'both']),
  computation: z.enum(['percent', 'fixed']),
  rateAtl: rateString,
  rateNonAtl: rateString,
  statusBasis: z.enum(['company', 'counterparty']),
  returnSection: z.string().trim().max(20).optional(),
  isAdjustable: z.boolean().optional(),
  ledgerCode: z.string().trim().min(1, 'Choose the ledger account it posts to.').max(10),
  effectiveFrom: dateString,
  notes: z.string().trim().max(1000).optional(),
});

const newRateBody = z.object({
  effectiveFrom: dateString,
  rateAtl: rateString,
  rateNonAtl: rateString,
  note: z.string().trim().max(1000).optional(),
});

const endBody = z.object({ lastDay: dateString });

const ruleBody = z.object({
  direction: z.enum(['in', 'out']),
  currencyIsForeign: z.boolean().nullable().optional(),
  accountType: z.enum(['bank', 'cash', 'petty_cash', 'cheque', 'pass_through']).nullable().optional(),
  categoryId: z.number().int().positive().nullable().optional(),
  priority: z.number().int().min(1).max(1000).optional(),
});

const ruleChange = z.object({ isActive: z.boolean() });

function actorFrom(req) {
  return { id: Number(req.user.id), role: req.user.role };
}

taxRoutes.get('/taxes/all', requireAuth, async (req, res) => {
  res.json(await manage.listAll());
});

taxRoutes.post('/taxes', requireAuth, async (req, res) => {
  const input = parseOrThrow(createBody, req.body ?? {});
  res.status(201).json({ tax: await manage.createTax({ user: actorFrom(req), input, ip: req.ip }) });
});

taxRoutes.post('/taxes/:id/new-rate', requireAuth, async (req, res) => {
  const { id } = parseOrThrow(idParam, req.params);
  const input = parseOrThrow(newRateBody, req.body ?? {});
  res.status(201).json({ tax: await manage.newRate({ user: actorFrom(req), id, input, ip: req.ip }) });
});

taxRoutes.post('/taxes/:id/end', requireAuth, async (req, res) => {
  const { id } = parseOrThrow(idParam, req.params);
  const { lastDay } = parseOrThrow(endBody, req.body ?? {});
  res.json({ tax: await manage.endTax({ user: actorFrom(req), id, lastDay, ip: req.ip }) });
});

taxRoutes.post('/taxes/:id/rules', requireAuth, async (req, res) => {
  const { id } = parseOrThrow(idParam, req.params);
  const input = parseOrThrow(ruleBody, req.body ?? {});
  res.status(201).json({ tax: await manage.addRule({ user: actorFrom(req), taxId: id, input, ip: req.ip }) });
});

taxRoutes.patch('/tax-rules/:id', requireAuth, async (req, res) => {
  const { id } = parseOrThrow(idParam, req.params);
  const { isActive } = parseOrThrow(ruleChange, req.body ?? {});
  res.json({ tax: await manage.setRuleActive({ user: actorFrom(req), ruleId: id, isActive, ip: req.ip }) });
});

// --- bulk import and export, the owner's, decision 069 ---------------------------

const importBody = z.object({
  csv: z.string().min(1, 'The file is empty.').max(900000, 'The file is too large. Split it into smaller files.'),
  apply: z.boolean().optional().default(false),
});

taxRoutes.get('/taxes/template', requireAuth, (req, res) => {
  res.json(bulk.templateCsv({ user: actorFrom(req) }));
});

taxRoutes.get('/taxes/export', requireAuth, async (req, res) => {
  res.json(await bulk.exportCsv({ user: actorFrom(req) }));
});

taxRoutes.post('/taxes/import', requireAuth, async (req, res) => {
  const { csv, apply } = parseOrThrow(importBody, req.body ?? {});
  res.json(await bulk.importTaxes({ user: actorFrom(req), csv, apply, ip: req.ip }));
});
