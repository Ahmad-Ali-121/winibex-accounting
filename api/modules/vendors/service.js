// Vendors.
//
// Needed before a withholding rate can be chosen at all, because the rate
// depends on the payee's filer status rather than Winibex's. Decision 030, and
// decision 031 for why the table exists.
//
// Two facts here have consequences outside this module. `atl_status` picks the
// rate on every Section 153 line, and `ntn` or `cnic` is what the quarterly
// Section 165 statement reports. A vendor with neither cannot be withheld from
// at all, which is a blocking rule in docs/UI-GUIDE.md.

import { withTransaction, getPool } from '../../core/db.js';
import { writeAudit, AuditAction } from '../../core/audit.js';
import { ErrorCode, badRequest, forbidden, notFound } from '../../core/errors.js';
import * as repo from './repository.js';

const EDITABLE_BY = new Set(['owner', 'admin']);
const STALE_AFTER_DAYS = 30;

function present(vendor) {
  return {
    id: Number(vendor.id),
    name: vendor.name,
    kind: vendor.kind,
    ntn: vendor.ntn,
    cnic: vendor.cnic,
    strn: vendor.strn,
    atlStatus: vendor.atl_status,
    atlCheckedOn: vendor.atl_checked_on,
    atlCheckIsStale: isStale(vendor),
    canBeWithheldFrom: hasTaxIdentity(vendor),
    defaultTaxId: vendor.default_tax_id === null ? null : Number(vendor.default_tax_id),
    country: vendor.country,
    email: vendor.email,
    phone: vendor.phone,
    notes: vendor.notes,
    isActive: Boolean(vendor.is_active),
  };
}

// A foreign payee has no Pakistani tax number and none is expected. A local
// one must have at least one, or the s.165 statement has nothing to report
// them under.
export function hasTaxIdentity(vendor) {
  if (vendor.kind === 'foreign') return true;
  return Boolean(vendor.ntn || vendor.cnic);
}

export function isStale(vendor) {
  if (vendor.atl_status === 'unknown') return true;
  if (!vendor.atl_checked_on) return true;
  const days = (Date.now() - new Date(vendor.atl_checked_on).getTime()) / (24 * 60 * 60 * 1000);
  return days > STALE_AFTER_DAYS;
}

export async function listVendors({ search = null, includeInactive = false } = {}) {
  const rows = await repo.list(getPool(), { search, includeInactive });
  return { vendors: rows.map(present) };
}

export async function getVendor(id) {
  const vendor = await repo.findById(getPool(), id);
  if (!vendor) throw notFound('That vendor does not exist.');
  return present(vendor);
}

function assertConsistent(input) {
  // The database enforces this too. Saying it in words here means the person
  // gets told what to do rather than reading a constraint name.
  if (input.atlStatus && input.atlStatus !== 'unknown' && !input.atlCheckedOn) {
    throw badRequest(
      ErrorCode.VALIDATION_FAILED,
      'Record the date the filer status was checked, so a stale check can be spotted later.',
      { field: 'atlCheckedOn' },
    );
  }
}

export async function createVendor({ user, input, ip = null }) {
  if (!EDITABLE_BY.has(user.role)) {
    throw forbidden('Only the owner or an admin can add a vendor.');
  }
  assertConsistent(input);

  const result = await withTransaction(async (connection) => {
    const id = await repo.insert(connection, {
      name: input.name,
      kind: input.kind,
      ntn: input.ntn ?? null,
      cnic: input.cnic ?? null,
      strn: input.strn ?? null,
      atlStatus: input.atlStatus ?? 'unknown',
      atlCheckedOn: input.atlCheckedOn ?? null,
      defaultTaxId: input.defaultTaxId ?? null,
      country: input.country ?? null,
      email: input.email ?? null,
      phone: input.phone ?? null,
      notes: input.notes ?? null,
      createdBy: user.id,
    });

    await writeAudit(connection, {
      userId: user.id, ip, table: 'vendors', recordId: id,
      action: AuditAction.INSERT,
      after: { name: input.name, kind: input.kind, atlStatus: input.atlStatus ?? 'unknown' },
    });

    return id;
  });

  return getVendor(result);
}

export async function updateVendor({ user, id, changes, ip = null }) {
  if (!EDITABLE_BY.has(user.role)) {
    throw forbidden('Only the owner or an admin can change a vendor.');
  }

  const result = await withTransaction(async (connection) => {
    const before = await repo.findById(connection, id);
    if (!before) throw notFound('That vendor does not exist.');

    assertConsistent({
      atlStatus: changes.atlStatus ?? before.atl_status,
      atlCheckedOn: changes.atlCheckedOn ?? before.atl_checked_on,
    });

    // Deactivating is the only kind of removal. A vendor named on a filed
    // withholding statement has to stay findable for ten years.
    if (changes.isActive === false && await repo.isReferenced(connection, id)) {
      // Allowed, but it is a deactivation and never a delete.
      changes.isActive = 0;
    }

    await repo.update(connection, id, {
      ...changes,
      isActive: changes.isActive === undefined ? undefined : (changes.isActive ? 1 : 0),
    });

    await writeAudit(connection, {
      userId: user.id, ip, table: 'vendors', recordId: Number(id),
      action: AuditAction.UPDATE,
      before: { atlStatus: before.atl_status, atlCheckedOn: before.atl_checked_on, ntn: before.ntn },
      after: changes,
    });

    return Number(id);
  });

  return getVendor(result);
}

// Used by the posting path: a local vendor with no NTN and no CNIC cannot be
// withheld from, because there is nothing to file the deduction against.
export async function assertCanWithholdFrom(runner, vendorId) {
  const vendor = await repo.findById(runner, vendorId);
  if (!vendor) throw badRequest(ErrorCode.VALIDATION_FAILED, 'That vendor does not exist.');

  if (!hasTaxIdentity(vendor)) {
    throw badRequest(
      ErrorCode.MISSING_VENDOR_TAX_ID,
      `${vendor.name} has no NTN or CNIC recorded, so tax withheld from them cannot be reported.`,
      { field: 'vendorId' },
    );
  }
  return vendor;
}
