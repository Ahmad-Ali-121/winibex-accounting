import { AppError, ErrorCode, unauthorized, badRequest } from '../../core/errors.js';
import { verifyPassword, hashPassword } from '../../core/password.js';
import {
  signAccessToken,
  createRefreshToken,
  hashRefreshToken,
  refreshExpiryDate,
  newFamilyId,
} from '../../core/tokens.js';
import * as repo from './repository.js';

function publicUser(user) {
  return {
    id: Number(user.id),
    name: user.name,
    email: user.email,
    role: user.role,
    mustChangePassword: Boolean(user.must_change_password),
    approvalLimit: user.approval_limit === null ? null : Number(user.approval_limit),
    autoApproveOwn: Boolean(user.auto_approve_own),
  };
}

const INVALID = () =>
  unauthorized(ErrorCode.INVALID_CREDENTIALS, 'That email or password is not right.');

export async function login({ email, password, ip, userAgent }) {
  const user = await repo.findUserByEmail(email);

  // A missing user and a wrong password give the same answer, so the response
  // cannot be used to find out which addresses have accounts. The hash is
  // still verified for a missing user so the timing matches too.
  if (!user) {
    await verifyPassword('$2b$12$invalidinvalidinvalidinvalidinvalidinvalidinvalidinvalidinv', password);
    throw INVALID();
  }

  const correct = await verifyPassword(user.password_hash, password);
  if (!correct) throw INVALID();

  if (!user.is_active) {
    throw new AppError(403, ErrorCode.ACCOUNT_INACTIVE, 'This account has been deactivated.');
  }

  return issueSession({ user, familyId: newFamilyId(), ip, userAgent });
}

async function issueSession({ user, familyId, ip, userAgent, replacesId = null }) {
  const refresh = createRefreshToken();
  const expiresAt = refreshExpiryDate();

  const newId = await repo.insertRefreshToken({
    userId: user.id,
    tokenHash: refresh.hash,
    familyId,
    expiresAt,
    ip,
    userAgent,
  });

  if (replacesId) await repo.markReplaced(replacesId, newId);

  return {
    accessToken: signAccessToken(user),
    refreshToken: refresh.token,
    refreshExpiresAt: expiresAt,
    user: publicUser(user),
  };
}

export async function refresh({ refreshToken, ip, userAgent }) {
  const hash = hashRefreshToken(refreshToken);
  const stored = await repo.findRefreshTokenByHash(hash);

  if (!stored) {
    throw unauthorized(ErrorCode.TOKEN_INVALID, 'That session is not valid. Sign in again.');
  }

  // Already rotated or logged out. Presenting it again means a copy is in
  // circulation, so the whole family goes.
  if (stored.revoked_at) {
    await repo.revokeFamily(stored.family_id);
    throw unauthorized(
      ErrorCode.TOKEN_INVALID,
      'This session was ended for safety because an old sign-in was reused. Sign in again.',
    );
  }

  if (new Date(stored.expires_at) <= new Date()) {
    throw unauthorized(ErrorCode.TOKEN_EXPIRED, 'Your session has expired. Sign in again.');
  }

  const user = await repo.findUserById(stored.user_id);
  if (!user || !user.is_active) {
    await repo.revokeFamily(stored.family_id);
    throw new AppError(403, ErrorCode.ACCOUNT_INACTIVE, 'This account has been deactivated.');
  }

  return issueSession({
    user,
    familyId: stored.family_id,
    ip,
    userAgent,
    replacesId: stored.id,
  });
}

export async function logout({ refreshToken }) {
  if (!refreshToken) return { revoked: 0 };

  const stored = await repo.findRefreshTokenByHash(hashRefreshToken(refreshToken));
  if (!stored) return { revoked: 0 };

  // Logout ends the session, not just the one token, so a refresh token kept
  // on another device cannot quietly continue it.
  return { revoked: await repo.revokeFamily(stored.family_id) };
}

/**
 * Change a password.
 *
 * The current password is required and verified even for the bootstrapped
 * owner who is being forced to change: it proves the person at the keyboard is
 * the one who logged in, not someone who walked up to an unlocked screen.
 *
 * On success every other session for this user is revoked, because anyone
 * holding the old password has refresh tokens that must stop working. The
 * caller's own session is left alone so they are not logged out of the change
 * they just made.
 */
export async function changePassword({ userId, currentPassword, newPassword, ip = null }) {
  const user = await repo.findUserById(userId);
  if (!user) throw unauthorized(ErrorCode.NOT_AUTHENTICATED, 'Sign in to continue.');

  const correct = await verifyPassword(user.password_hash, currentPassword);
  if (!correct) {
    throw badRequest(ErrorCode.INVALID_CREDENTIALS, 'Your current password is not right.', {
      field: 'currentPassword',
    });
  }

  // A new password that equals the old one is not a change. Checked after the
  // current-password check so the message order makes sense.
  const sameAsOld = await verifyPassword(user.password_hash, newPassword);
  if (sameAsOld) {
    throw badRequest(ErrorCode.VALIDATION_FAILED, 'The new password must be different from the old one.', {
      field: 'newPassword',
    });
  }

  const hash = await hashPassword(newPassword);
  await repo.updatePassword(userId, hash);

  // Everyone who had the old password is now holding dead tokens.
  await repo.revokeAllForUser(userId);

  const fresh = await repo.findUserById(userId);
  return { user: publicUser(fresh) };
}

export { publicUser };
