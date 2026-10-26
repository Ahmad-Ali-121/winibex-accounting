// The business date: what day it is in Pakistan.
//
// Timestamps are stored in UTC. A transaction's `date` is different: it is the
// calendar day the money moved, as the people in the office see it. Checks
// such as "not in the future", "more than 90 days ago" and "this month" have
// to use that same calendar, or between midnight and 05:00 Pakistan time the
// server refuses today's date as a future date. Decision 057, defect D9.
//
// Pakistan has kept no daylight saving since 2009, but the time zone is still
// read from the zone database rather than written as +05:00, so the answer
// stays right if that ever changes.

export const BUSINESS_TIME_ZONE = 'Asia/Karachi';

const formatter = new Intl.DateTimeFormat('en-GB', {
  timeZone: BUSINESS_TIME_ZONE,
  year: 'numeric',
  month: '2-digit',
  day: '2-digit',
});

/** The Pakistan calendar date of an instant, as YYYY-MM-DD. */
export function businessDate(instant = new Date()) {
  const parts = Object.fromEntries(
    formatter.formatToParts(instant).map((part) => [part.type, part.value]),
  );
  return `${parts.year}-${parts.month}-${parts.day}`;
}

/** Today in Pakistan, as YYYY-MM-DD. */
export function businessToday() {
  return businessDate(new Date());
}

/** A YYYY-MM-DD date moved by a whole number of days. */
export function addDays(date, days) {
  const value = new Date(`${date}T00:00:00Z`);
  value.setUTCDate(value.getUTCDate() + days);
  return value.toISOString().slice(0, 10);
}

/** The first day of the month a YYYY-MM-DD date falls in. */
export function monthStart(date) {
  return `${date.slice(0, 7)}-01`;
}

/** The first day of the month after the one a YYYY-MM-DD date falls in. */
export function nextMonthStart(date) {
  const value = new Date(`${monthStart(date)}T00:00:00Z`);
  value.setUTCMonth(value.getUTCMonth() + 1);
  return value.toISOString().slice(0, 10);
}
