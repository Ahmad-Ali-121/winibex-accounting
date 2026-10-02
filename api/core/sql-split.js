// Splits a migration file into individual statements.
//
// Needed because the connection runs with multipleStatements off, so each
// statement is sent on its own. Splitting on every semicolon would break the
// first trigger we write, since a trigger body is full of them. Migration
// files therefore use the same DELIMITER directive phpMyAdmin understands, and
// this splitter honours it, so one file works in both places.
//
// Semicolons inside quotes and comments are left alone.
//
// A bare `--` line, with nothing after the dashes, is a comment in MariaDB.
// LINE_COMMENT accepts one. isOnlyComments did not, so a block of comments
// containing a bare `--` line was judged to hold real SQL, and the empty
// string left after stripping it was sent to the server, which answered
// "Query was empty". Found by migration 004, the first file where a comment
// block stands alone between two statements, because DELIMITER forces a push.
// Both functions now agree on what a comment is, and push refuses to emit an
// empty statement even if they ever disagree again.

const LINE_COMMENT = /^--[ \t\r\n]/;

export function splitSqlStatements(sql) {
  const statements = [];
  let delimiter = ';';
  let buffer = '';
  let index = 0;
  const length = sql.length;

  const push = () => {
    const trimmed = buffer.trim();
    if (trimmed.length > 0 && !isOnlyComments(trimmed)) {
      // Leading comments belong to the file, not the statement. Dropping them
      // keeps error messages about the SQL that actually failed.
      const statement = stripLeadingComments(trimmed);
      // Belt and braces: never hand the server an empty string.
      if (statement.length > 0) statements.push(statement);
    }
    buffer = '';
  };

  while (index < length) {
    const atLineStart = index === 0 || sql[index - 1] === '\n';

    // DELIMITER only counts at the start of a line, as in phpMyAdmin.
    if (atLineStart && /^delimiter[ \t]/i.test(sql.slice(index, index + 10))) {
      const lineEnd = sql.indexOf('\n', index);
      const line = sql.slice(index, lineEnd === -1 ? length : lineEnd);
      const match = line.match(/^delimiter[ \t]+(\S+)/i);
      if (match) {
        push();
        delimiter = match[1];
        index = lineEnd === -1 ? length : lineEnd + 1;
        continue;
      }
    }

    const char = sql[index];

    if (LINE_COMMENT.test(sql.slice(index, index + 3)) || char === '#') {
      const lineEnd = sql.indexOf('\n', index);
      const end = lineEnd === -1 ? length : lineEnd + 1;
      buffer += sql.slice(index, end);
      index = end;
      continue;
    }

    if (char === '/' && sql[index + 1] === '*') {
      const close = sql.indexOf('*/', index + 2);
      const end = close === -1 ? length : close + 2;
      buffer += sql.slice(index, end);
      index = end;
      continue;
    }

    if (char === "'" || char === '"' || char === '`') {
      const quote = char;
      let cursor = index + 1;
      while (cursor < length) {
        if (sql[cursor] === '\\' && quote !== '`') {
          cursor += 2;
          continue;
        }
        if (sql[cursor] === quote) {
          if (sql[cursor + 1] === quote) {
            cursor += 2;
            continue;
          }
          cursor += 1;
          break;
        }
        cursor += 1;
      }
      buffer += sql.slice(index, cursor);
      index = cursor;
      continue;
    }

    if (sql.startsWith(delimiter, index)) {
      push();
      index += delimiter.length;
      continue;
    }

    buffer += char;
    index += 1;
  }

  push();
  return statements;
}

export function stripLeadingComments(text) {
  let result = text.trimStart();

  for (;;) {
    if (LINE_COMMENT.test(result.slice(0, 3)) || result.startsWith('#')) {
      const lineEnd = result.indexOf('\n');
      if (lineEnd === -1) return '';
      result = result.slice(lineEnd + 1).trimStart();
      continue;
    }

    // /*! ... */ is an executable comment and must survive.
    if (result.startsWith('/*') && !result.startsWith('/*!')) {
      const close = result.indexOf('*/');
      if (close === -1) return '';
      result = result.slice(close + 2).trimStart();
      continue;
    }

    return result;
  }
}

export function isOnlyComments(text) {
  const stripped = text
    .replace(/\/\*(?!!)[\s\S]*?\*\//g, '')
    // `--([ \t].*)?` so that a line of nothing but dashes counts as a comment,
    // matching LINE_COMMENT above.
    .replace(/^[ \t]*(--([ \t].*)?|#.*)$/gm, '')
    .trim();
  return stripped.length === 0;
}
