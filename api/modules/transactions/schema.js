// What a transaction request may contain.
//
// Validation happens at the route boundary and nowhere else. By the time the
// service is called the shape is already known good, so it can spend its
// attention on the rules that need the database.
//
// Money is always an object, never a bare number, as in docs/API.md:
//   { "minor": 560000, "currency": "PKR" }
// `minor` is a whole number of paisa. A float in a money field is refused
// here rather than quietly rounded somewhere later.

import { z } from 'zod';

const CURRENCY = z.string().trim().toUpperCase().length(3, 'Use a three letter currency code.');

export const moneySchema = z.object({
  minor: z
    .number({ invalid_type_error: 'An amount must be a whole number of paisa.' })
    .int('An amount must be a whole number of paisa, never a decimal.'),
  currency: CURRENCY,
});

const positiveMoney = moneySchema.refine((value) => value.minor > 0, {
  message: 'An amount must be above zero. Direction carries the sign.',
});

// DECIMAL(18,6) in the database. Sent as a string so it never passes through a
// float on the way here.
const rateSchema = z
  .string()
  .regex(/^\d+(\.\d{1,6})?$/, 'A rate is a number with up to six decimal places.')
  .refine((value) => Number(value) > 0, { message: 'A rate must be above zero.' });

const dateSchema = z
  .string()
  .regex(/^\d{4}-\d{2}-\d{2}$/, 'Use a date like 2026-07-05.');

export const taxLineSchema = z.object({
  taxId: z.number().int().positive(),
  baseAmount: positiveMoney,
  rateApplied: z.string().regex(/^\d+(\.\d{1,4})?$/, 'A tax rate has up to four decimal places.'),
  atlStatusUsed: z.enum(['atl', 'non_atl']),
  atlParty: z.enum(['company', 'vendor', 'client', 'employee', 'cardholder']),
  amount: moneySchema,
  isOverride: z.boolean().optional(),
  deductedBy: z.enum(['bank', 'customer', 'us', 'platform']),
});

export const chargeLineSchema = z.object({
  type: z.enum(['bank_charge', 'forex_fee', 'platform_fee', 'card_fee', 'other']),
  amount: positiveMoney,
  coaId: z.number().int().positive(),
  note: z.string().trim().max(255).optional(),
});

export const createTransactionSchema = z
  .object({
    date: dateSchema,
    direction: z.enum(['in', 'out']),
    method: z.enum(['cash', 'account', 'card', 'cheque', 'online']),
    description: z.string().trim().min(1, 'Describe what this was for.').max(255),
    categoryId: z.number().int().positive(),

    accountId: z.number().int().positive().nullable().optional(),
    paidByType: z.enum(['company', 'person']).optional(),
    paidByUserId: z.number().int().positive().nullable().optional(),
    receivedByUserId: z.number().int().positive().nullable().optional(),

    gross: positiveMoney,
    foreign: positiveMoney.optional(),
    fxRate: rateSchema.optional(),
    fxRateSource: z.enum(['manual', 'bank_advice', 'derived']).optional(),

    clientId: z.number().int().positive().nullable().optional(),
    projectId: z.number().int().positive().nullable().optional(),
    vendorId: z.number().int().positive().nullable().optional(),
    chequeId: z.number().int().positive().nullable().optional(),
    isRebillable: z.boolean().optional(),
    fundSource: z.enum(['operations', 'investor']).optional(),
    entryType: z.enum(['normal', 'opening', 'historical', 'journal']).optional(),
    reference: z.string().trim().max(50).optional(),

    taxes: z.array(taxLineSchema).max(10).optional(),
    charges: z.array(chargeLineSchema).max(10).optional(),

    // Warnings the user has seen and confirmed. The same request comes back
    // with these filled in, and goes through. docs/API.md.
    acknowledged_warnings: z.array(z.string().max(50)).max(20).optional(),
  })
  // A foreign entry carries its original amount and its rate, or the books
  // cannot show what the bank actually did. The database refuses a half-filled
  // conversion too; this just says so in words a person can act on.
  .refine(
    (value) => !value.foreign || Boolean(value.fxRate),
    { message: 'A foreign amount needs the rate, or the PKR figure the bank gave.', path: ['fxRate'] },
  )
  .refine(
    (value) => value.paidByType !== 'person' || Boolean(value.paidByUserId),
    { message: 'Say who paid, so the company knows who it owes.', path: ['paidByUserId'] },
  )
  .refine(
    (value) => value.paidByType === 'person' || Boolean(value.accountId) || value.entryType === 'opening' || value.entryType === 'journal',
    { message: 'Say which account the money moved on.', path: ['accountId'] },
  );

// A draft may be changed entirely, so the update takes the same shape.
export const updateTransactionSchema = createTransactionSchema;

export const transferSchema = z.object({
  date: dateSchema,
  fromAccountId: z.number().int().positive(),
  toAccountId: z.number().int().positive(),
  amount: positiveMoney,
  // A bank fee on the transfer. The source loses the amount plus the fee, the
  // destination receives the amount, and the difference is recorded rather
  // than left as two legs that mysteriously disagree.
  fee: positiveMoney.optional(),
  method: z.enum(['cash', 'account', 'card', 'cheque', 'online']).optional(),
  description: z.string().trim().max(255).optional(),
  reference: z.string().trim().max(50).optional(),
  acknowledged_warnings: z.array(z.string().max(50)).max(20).optional(),
});

export const reasonSchema = z.object({
  reason: z.string().trim().min(3, 'Say why, in a few words at least.').max(255),
});

export const idParamSchema = z.object({
  id: z.coerce.number().int().positive(),
});

// Turns the request body into what the service expects: plain paisa integers.
export function toServiceInput(body) {
  return {
    date: body.date,
    direction: body.direction,
    method: body.method,
    description: body.description,
    categoryId: body.categoryId,
    accountId: body.accountId ?? null,
    paidByType: body.paidByType ?? 'company',
    paidByUserId: body.paidByUserId ?? null,
    receivedByUserId: body.receivedByUserId ?? null,
    grossAmount: body.gross.minor,
    currency: body.foreign ? body.foreign.currency : 'PKR',
    foreignAmount: body.foreign ? body.foreign.minor : null,
    fxRate: body.fxRate ?? null,
    fxRateSource: body.foreign ? body.fxRateSource ?? 'manual' : null,
    clientId: body.clientId ?? null,
    projectId: body.projectId ?? null,
    vendorId: body.vendorId ?? null,
    chequeId: body.chequeId ?? null,
    isRebillable: body.isRebillable ?? false,
    fundSource: body.fundSource ?? 'operations',
    entryType: body.entryType ?? 'normal',
    reference: body.reference ?? null,
    taxes: (body.taxes ?? []).map((tax) => ({
      taxId: tax.taxId,
      baseAmount: tax.baseAmount.minor,
      rateApplied: tax.rateApplied,
      atlStatusUsed: tax.atlStatusUsed,
      atlParty: tax.atlParty,
      amount: tax.amount.minor,
      isOverride: tax.isOverride ?? false,
      deductedBy: tax.deductedBy,
    })),
    acknowledgedWarnings: body.acknowledged_warnings ?? [],
    charges: (body.charges ?? []).map((charge) => ({
      type: charge.type,
      amount: charge.amount.minor,
      coaId: charge.coaId,
      note: charge.note ?? null,
    })),
  };
}
