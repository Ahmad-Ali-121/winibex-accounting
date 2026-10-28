// People and what each may do.
//
// Only the owner adds people or changes their permissions, and every change is
// written to the audit log with both sides, SCHEMA.md Permissions rule 5.
// Nobody is ever deleted: a person who leaves is switched off, so every entry
// they made still names them.
//
// What the roles mean, in the words the screen uses (UI-GUIDE, People):
//   owner  the shared office login. Everything, including people and settings.
//          Exactly one, created by migration 003, never made here
//   admin  approves other people's entries and does the money moves. Optional
//          approval limit, and optionally posts their own entries directly
//   staff  records money in and out and sends it for approval

import { getPool, withTransaction } from '../../core/db.js';
import { writeAudit, AuditAction } from '../../core/audit.js';
import { AppError, ErrorCode, badRequest, forbidden, notFound } from '../../core/errors.js';
import { hashPassword, passwordPolicy } from '../../core/password.js';
import { money } from '../../core/money.js';
import * as repo from './repository.js';

const BASE_CURRENCY = 'PKR';

function present(row) {
  return {
    id: Number(row.id),
    name: row.name,
    email: row.email,
    role: row.role,
    approvalLimit: row.approval_limit === null ? null : money(Number(row.approval_limit), BASE_CURRENCY),
    autoApproveOwn: Boolean(row.auto_approve_own),
    sharesOwnerLogin: Boolean(row.shares_owner_login),
    isActive: Boolean(row.is_active),
    mustChangePassword: Boolean(row.must_change_password),
    createdAt: row.created_at,
  };
}

// What is written to the audit log. Never the password or its hash.
function auditView(row) {
  return {
    name: row.name,
    role: row.role,
    approvalLimit: row.approval_limit === null ? null : Number(row.approval_limit),
    autoApproveOwn: Boolean(row.auto_approve_own),
    sharesOwnerLogin: Boolean(row.shares_owner_login),
    isActive: Boolean(row.is_active),
  };
}

function assertOwner(user) {
  if (user.role !== 'owner') {
    throw forbidden('Only the owner can add people or change what they can do.');
  }
}

// An approval limit and posting their own entries only mean anything for an
// admin. Staff never approve and never post directly, so for staff both are
// cleared rather than kept as settings that silently do nothing.
function permissionsFor(role, { approvalLimit = null, autoApproveOwn = false }) {
  if (role !== 'admin') return { approvalLimit: null, autoApproveOwn: false };
  return { approvalLimit, autoApproveOwn: Boolean(autoApproveOwn) };
}

async function hashTemporary(plain) {
  try {
    return await hashPassword(plain);
  } catch (error) {
    if (error instanceof TypeError) throw error;
    const tooShort = typeof plain === 'string' && plain.length < passwordPolicy.minLength;
    throw badRequest(
      ErrorCode.VALIDATION_FAILED,
      tooShort
        ? `Use at least ${passwordPolicy.minLength} characters for the temporary password.`
        : 'Use a shorter temporary password.',
      { field: 'temporaryPassword' },
    );
  }
}

export async function listPickable() {
  const rows = await repo.listPickable(getPool());
  return rows.map((row) => ({ id: Number(row.id), name: row.name, role: row.role }));
}

export async function listPeople({ user }) {
  assertOwner(user);
  const rows = await repo.listAll(getPool());
  return rows.map(present);
}

export async function addPerson({ user, input, ip = null }) {
  assertOwner(user);

  const email = input.email.trim().toLowerCase();
  const passwordHash = await hashTemporary(input.temporaryPassword);
  const permissions = permissionsFor(input.role, input);

  const id = await withTransaction(async (connection) => {
    if (await repo.emailTaken(connection, email)) {
      throw new AppError(409, ErrorCode.ALREADY_EXISTS, 'Someone already signs in with that email.', {
        field: 'email',
      });
    }

    const newId = await repo.insert(connection, {
      name: input.name.trim(),
      email,
      passwordHash,
      role: input.role,
      ...permissions,
      sharesOwnerLogin: Boolean(input.sharesOwnerLogin),
    });

    const created = await repo.findById(connection, newId);
    await writeAudit(connection, {
      userId: user.id, ip, table: 'users', recordId: newId,
      action: AuditAction.INSERT,
      after: { ...auditView(created), email },
    });
    return newId;
  });

  return present(await repo.findById(getPool(), id));
}

export async function changePerson({ user, id, input, ip = null }) {
  assertOwner(user);

  await withTransaction(async (connection) => {
    const current = await repo.lockById(connection, id);
    if (!current) throw notFound('That person does not exist.');
    if (current.role === 'owner') {
      throw new AppError(
        409,
        ErrorCode.INVALID_STATUS,
        'The office login is the owner and always has every permission. It cannot be changed here.',
      );
    }

    const role = input.role ?? current.role;
    const permissions = permissionsFor(role, {
      approvalLimit: input.approvalLimit !== undefined
        ? input.approvalLimit
        : (current.approval_limit === null ? null : Number(current.approval_limit)),
      autoApproveOwn: input.autoApproveOwn ?? Boolean(current.auto_approve_own),
    });
    const next = {
      name: input.name?.trim() ?? current.name,
      role,
      ...permissions,
      sharesOwnerLogin: input.sharesOwnerLogin ?? Boolean(current.shares_owner_login),
      isActive: input.isActive ?? Boolean(current.is_active),
    };

    await repo.update(connection, id, next);

    // A login switched off stops working at once, not at the next sign-in.
    if (current.is_active && !next.isActive) await repo.revokeSessions(connection, id);

    const after = await repo.findById(connection, id);
    await writeAudit(connection, {
      userId: user.id, ip, table: 'users', recordId: Number(id),
      action: AuditAction.PERMISSION_CHANGE,
      before: auditView(current),
      after: auditView(after),
    });
  });

  return present(await repo.findById(getPool(), id));
}

export async function resetPassword({ user, id, temporaryPassword, ip = null }) {
  assertOwner(user);
  const passwordHash = await hashTemporary(temporaryPassword);

  await withTransaction(async (connection) => {
    const current = await repo.lockById(connection, id);
    if (!current) throw notFound('That person does not exist.');
    if (current.role === 'owner') {
      throw new AppError(
        409,
        ErrorCode.INVALID_STATUS,
        'The office login changes its own password, from its own sign-in.',
      );
    }

    await repo.setTemporaryPassword(connection, id, passwordHash);
    await repo.revokeSessions(connection, id);
    await writeAudit(connection, {
      userId: user.id, ip, table: 'users', recordId: Number(id),
      action: AuditAction.UPDATE,
      after: { passwordReset: true, mustChangePassword: true },
    });
  });

  return present(await repo.findById(getPool(), id));
}
