// Who is calling, and are they allowed to.
//
// Roles are owner, admin, staff. Decision 036. There is no approver role.
// The owner login is shared by Ahmad and Maryam and can do everything,
// including approving, which is why `possible_self_approval` exists elsewhere.

import { AppError, ErrorCode, forbidden } from './errors.js';
import { verifyAccessToken } from './tokens.js';
import { getPool } from './db.js';

export const ROLES = Object.freeze(['owner', 'admin', 'staff']);

function bearerToken(req) {
  const header = req.get('authorization');
  if (!header) return null;
  const [scheme, value] = header.split(' ');
  if (!value || scheme.toLowerCase() !== 'bearer') return null;
  return value.trim();
}

export async function requireAuth(req, res, next) {
  const token = bearerToken(req);
  if (!token) {
    return next(
      new AppError(401, ErrorCode.NOT_AUTHENTICATED, 'Sign in to continue.'),
    );
  }

  const claims = verifyAccessToken(token);

  // The token says who they were when it was issued. The database says who
  // they are now. A user deactivated two minutes ago must not still get in on
  // a token that has not expired yet.
  const [rows] = await getPool().query(
    'SELECT id, name, email, role, is_active, must_change_password, approval_limit, auto_approve_own, shares_owner_login FROM users WHERE id = ?',
    [claims.sub],
  );

  const user = rows[0];
  if (!user) {
    return next(new AppError(401, ErrorCode.TOKEN_INVALID, 'That session is not valid.'));
  }
  if (!user.is_active) {
    return next(
      new AppError(403, ErrorCode.ACCOUNT_INACTIVE, 'This account has been deactivated.'),
    );
  }

  req.user = user;
  return next();
}

export function requireRole(...allowed) {
  for (const role of allowed) {
    if (!ROLES.includes(role)) {
      throw new Error(`Unknown role in requireRole: ${role}`);
    }
  }

  return function roleGuard(req, res, next) {
    if (!req.user) {
      return next(new AppError(401, ErrorCode.NOT_AUTHENTICATED, 'Sign in to continue.'));
    }
    if (!allowed.includes(req.user.role)) {
      return next(forbidden('You do not have permission to do that.'));
    }
    return next();
  };
}

export const requireOwner = requireRole('owner');
export const requireApprover = requireRole('owner', 'admin');

// Whether this user may approve an entry of this size. Staff never can. An
// admin with no limit is unlimited. The owner is always unlimited.
export function canApproveAmount(user, amountPaisa) {
  if (user.role === 'owner') return true;
  if (user.role !== 'admin') return false;
  if (user.approval_limit === null || user.approval_limit === undefined) return true;
  return Number(user.approval_limit) >= Number(amountPaisa);
}
