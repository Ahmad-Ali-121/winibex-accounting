import { Router } from 'express';
import { z } from 'zod';

import { requireAuth } from '../../core/auth.js';
import { badRequest, ErrorCode } from '../../core/errors.js';
import * as service from './service.js';

export const userRoutes = Router();

// req.user is the database row, snake_case. The service speaks camelCase.
function actorFrom(req) {
  return { id: Number(req.user.id), role: req.user.role };
}

function parseOrThrow(schema, value) {
  const result = schema.safeParse(value);
  if (!result.success) {
    const issue = result.error.issues[0];
    throw badRequest(ErrorCode.VALIDATION_FAILED, issue.message, {
      field: issue.path.join('.') || null,
    });
  }
  return result.data;
}

const idParam = z.object({ id: z.coerce.number().int().positive() });

// Money is always an object, docs/API.md. Null means no limit.
const limitSchema = z
  .object({
    minor: z.number().int().positive('An approval limit must be above zero, or empty for no limit.'),
    currency: z.literal('PKR'),
  })
  .nullable();

// A refine rather than z.enum, so the message is ours on any zod version.
const roleSchema = z
  .string()
  .refine((value) => value === 'admin' || value === 'staff', {
    message: 'Choose Admin or Staff. There is only one owner, the office login.',
  });

const addSchema = z.object({
  name: z.string().trim().min(1, 'Give their name.').max(100),
  email: z.string().trim().email('That email does not look right.').max(190),
  role: roleSchema,
  temporaryPassword: z.string().min(1, 'Set a temporary password. They change it at first sign-in.'),
  approvalLimit: limitSchema.optional(),
  autoApproveOwn: z.boolean().optional(),
  sharesOwnerLogin: z.boolean().optional(),
});

const changeSchema = z.object({
  name: z.string().trim().min(1, 'Give their name.').max(100).optional(),
  role: roleSchema.optional(),
  approvalLimit: limitSchema.optional(),
  autoApproveOwn: z.boolean().optional(),
  sharesOwnerLogin: z.boolean().optional(),
  isActive: z.boolean().optional(),
});

const resetSchema = z.object({
  temporaryPassword: z.string().min(1, 'Set a temporary password. They change it at first sign-in.'),
});

const limitMinor = (value) => (value === undefined ? undefined : value === null ? null : value.minor);

// Who can be named on an entry: the person who paid a cost personally, the
// person money was received by, the person being reimbursed.
//
// Deliberately thin. No email, no approval limit, no password fields, because
// a picker needs a name and nothing else, and anything extra here would be
// handed to every signed-in user.
userRoutes.get('/users', requireAuth, async (req, res) => {
  res.json({ users: await service.listPickable() });
});

// Everything below is the owner's. The service checks the role.
userRoutes.get('/people', requireAuth, async (req, res) => {
  res.json({ people: await service.listPeople({ user: actorFrom(req) }) });
});

userRoutes.post('/people', requireAuth, async (req, res) => {
  const body = parseOrThrow(addSchema, req.body ?? {});
  const person = await service.addPerson({
    user: actorFrom(req),
    input: { ...body, approvalLimit: limitMinor(body.approvalLimit) ?? null },
    ip: req.ip,
  });
  res.status(201).json({ person });
});

userRoutes.patch('/people/:id', requireAuth, async (req, res) => {
  const { id } = parseOrThrow(idParam, req.params);
  const body = parseOrThrow(changeSchema, req.body ?? {});
  const person = await service.changePerson({
    user: actorFrom(req),
    id,
    input: { ...body, approvalLimit: limitMinor(body.approvalLimit) },
    ip: req.ip,
  });
  res.json({ person });
});

userRoutes.post('/people/:id/reset-password', requireAuth, async (req, res) => {
  const { id } = parseOrThrow(idParam, req.params);
  const { temporaryPassword } = parseOrThrow(resetSchema, req.body ?? {});
  const person = await service.resetPassword({ user: actorFrom(req), id, temporaryPassword, ip: req.ip });
  res.json({ person });
});
