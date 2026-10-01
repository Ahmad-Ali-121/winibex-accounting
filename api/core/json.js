// JSON columns, in one place.
//
// MariaDB's JSON type is an alias for LONGTEXT with a validity check. What
// comes back across the wire depends on the driver version: mysql2 from 3.23
// reads MariaDB's extended type metadata and parses the value for you, while
// older versions hand over the raw string.
//
// Rather than depend on which, both are handled. Writing is always an explicit
// stringify, which is correct either way.

export function toJsonColumn(value) {
  if (value === null || value === undefined) return null;
  if (typeof value === 'string') return value;
  return JSON.stringify(value);
}

export function fromJsonColumn(value) {
  if (value === null || value === undefined) return null;
  if (typeof value !== 'string') return value;

  try {
    return JSON.parse(value);
  } catch {
    // A column that cannot be parsed is corrupt rather than absent. Returning
    // it raw keeps the audit trail readable instead of throwing away evidence.
    return value;
  }
}
