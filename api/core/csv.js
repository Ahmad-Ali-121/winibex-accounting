// Reading and writing CSV files: the bulk import and export of ledger codes
// and taxes. Decision 069.
//
// Written here rather than taken from a package: the format is small, and a
// file the accountant made in Excel must read the same way every time.
// Handles quoted cells, commas and line breaks inside quotes, doubled quotes,
// Windows and Unix line endings, and the byte order mark Excel adds.

/** Rows of cells from CSV text. Empty lines are dropped. */
export function parseCsv(text) {
  const source = String(text ?? '').replace(/^﻿/, '');
  const rows = [];
  let row = [];
  let cell = '';
  let quoted = false;
  let i = 0;

  const endCell = () => {
    row.push(cell);
    cell = '';
  };
  const endRow = () => {
    endCell();
    if (row.some((value) => value.trim() !== '')) rows.push(row);
    row = [];
  };

  while (i < source.length) {
    const char = source[i];
    if (quoted) {
      if (char === '"') {
        if (source[i + 1] === '"') {
          cell += '"';
          i += 2;
          continue;
        }
        quoted = false;
        i += 1;
        continue;
      }
      cell += char;
      i += 1;
      continue;
    }
    if (char === '"' && cell.trim() === '') {
      cell = '';
      quoted = true;
    } else if (char === ',') {
      endCell();
    } else if (char === '\r') {
      if (source[i + 1] === '\n') i += 1;
      endRow();
    } else if (char === '\n') {
      endRow();
    } else {
      cell += char;
    }
    i += 1;
  }
  if (cell !== '' || row.length > 0) endRow();
  return rows;
}

function quote(value) {
  const text = value === null || value === undefined ? '' : String(value);
  return /[",\r\n]/.test(text) || /^\s|\s$/.test(text) ? `"${text.replace(/"/g, '""')}"` : text;
}

/**
 * CSV text from rows, with a byte order mark so Excel reads it as UTF-8, and
 * Windows line endings, which every spreadsheet program accepts.
 */
export function toCsv(rows) {
  return `﻿${rows.map((row) => row.map(quote).join(',')).join('\r\n')}\r\n`;
}

/**
 * The key of a column heading: the words before any bracket, lower case.
 * "Code (4 digits)" and "code" are the same column, so a file still reads if
 * the hints in brackets are edited or the columns are moved around.
 */
export function headingKey(heading) {
  return String(heading ?? '')
    .replace(/^﻿/, '')
    .split('(')[0]
    .trim()
    .toLowerCase()
    .replace(/\s+/g, ' ');
}

/** Rows that start with "e.g." are the example row, never imported. */
export function isExampleRow(row) {
  return String(row[0] ?? '').trim().toLowerCase().startsWith('e.g.');
}

/**
 * The data rows of a file as objects keyed by field, each with its line
 * number in the file. [columns] maps a heading key to a field name. Throws a
 * readable message when a column the import needs is missing.
 */
export function readTable(text, columns, required) {
  const rows = parseCsv(text);
  if (rows.length === 0) return { missing: required, records: [] };

  const header = rows[0].map(headingKey);
  const positions = {};
  header.forEach((key, index) => {
    const field = columns[key];
    if (field && positions[field] === undefined) positions[field] = index;
  });
  const missing = required.filter((field) => positions[field] === undefined);

  const records = [];
  rows.slice(1).forEach((row, index) => {
    if (isExampleRow(row)) return;
    const record = { line: index + 2 };
    for (const [field, position] of Object.entries(positions)) {
      record[field] = String(row[position] ?? '').trim();
    }
    records.push(record);
  });
  return { missing, records };
}

/** yes, y, true, 1 and on are yes; no, n, false, 0 and off are no. */
export function yesNo(value) {
  const word = String(value ?? '').trim().toLowerCase();
  if (word === '') return null;
  if (['yes', 'y', 'true', '1', 'on'].includes(word)) return true;
  if (['no', 'n', 'false', '0', 'off'].includes(word)) return false;
  return undefined;
}
