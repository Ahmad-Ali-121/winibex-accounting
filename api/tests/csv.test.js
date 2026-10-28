// The CSV reader and writer behind bulk import and export. Decision 069.

import test from 'node:test';
import assert from 'node:assert/strict';

import { parseCsv, toCsv, headingKey, readTable, yesNo } from '../core/csv.js';

test('069: quoted cells, commas, quotes and line breaks survive a round trip', () => {
  const rows = [['Code', 'Name'], ['6600', 'Office, "supplies"'], ['6700', 'two\nlines'], ['6800', ' padded ']];
  assert.deepEqual(parseCsv(toCsv(rows)), rows);
});

test('069: Excel files read the same: byte order mark, Windows line endings, blank lines', () => {
  const text = '﻿Code,Name\r\n6600,Office\r\n\r\n6700,Repairs\r\n';
  assert.deepEqual(parseCsv(text), [['Code', 'Name'], ['6600', 'Office'], ['6700', 'Repairs']]);
});

test('069: a column is found by the words before its bracket, in any order', () => {
  assert.equal(headingKey('Code (4 digits; the first digit is the kind)'), 'code');
  assert.equal(headingKey('  Show on   entry form (yes or no)'), 'show on entry form');
  const { missing, records } = readTable(
    'Name (what to call it),Code (4 digits)\ne.g. Courier,e.g. 6960\nOffice,6600\n',
    { code: 'code', name: 'name' },
    ['code', 'name'],
  );
  assert.deepEqual(missing, []);
  assert.deepEqual(records, [{ line: 3, code: '6600', name: 'Office' }], 'the example row is skipped');
});

test('069: yes and no in the words people type', () => {
  assert.equal(yesNo('Yes'), true);
  assert.equal(yesNo('n'), false);
  assert.equal(yesNo(''), null);
  assert.equal(yesNo('maybe'), undefined);
});
