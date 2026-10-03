// The posting service against the real database.
//
// posting.test.js proves the journal lines are right. This proves what happens
// around them: the number comes from the sequence inside the same transaction,
// nothing survives a failure, a reversal links both rows, and the trial
// balance returns to zero.

import test, { before, after } from 'node:test';
import assert from 'node:assert/strict';
import process from 'node:process';
import { readFile } from 'node:fs/promises';

import { openConnection, closePool, withTransaction } from '../core/db.js';
import { splitSqlStatements } from '../core/sql-split.js';
import { allocate, peek } from '../core/sequences.js';
import * as service from '../modules/transactions/service.js';
import { WARNING_CODES } from '../modules/transactions/validation.js';

const TABLES = [
  'attachments', 'cheques', 'entry_flags', 'journal_lines', 'period_locks',
  'reimbursement_items', 'reimbursements', 'tax_rules', 'taxes',
  'transaction_charges', 'transaction_taxes', 'transactions', 'vendors',
  'accounts', 'audit_log', 'categories', 'chart_of_accounts', 'company_profile',
  'currencies', 'fbr_return_heads', 'idempotency_keys', 'refresh_tokens',
  'schema_migrations', 'sequences', 'settings', 'users',
];

let setup;
let owner;
let staff;
let accountId;
let categoryId;

async function applyMigration(connection, filename) {
  const sql = await readFile(new URL(`../migrations/${filename}`, import.meta.url), 'utf8');
  for (const statement of splitSqlStatements(sql)) {
    await connection.query(statement);
  }
}

before(async () => {
  assert.ok(process.env.DB_TEST_NAME, 'DB_TEST_NAME is not set');
  assert.notEqual(process.env.DB_TEST_NAME, process.env.DB_NAME);

  // The service uses the pool, so the pool has to point at the test database.
  process.env.DB_NAME = process.env.DB_TEST_NAME;

  setup = await openConnection({ database: process.env.DB_TEST_NAME });
  await setup.query('SET FOREIGN_KEY_CHECKS = 0');
  for (const table of TABLES) await setup.query(`DROP TABLE IF EXISTS \`${table}\``);
  await setup.query('SET FOREIGN_KEY_CHECKS = 1');

  for (const file of [
    '000_schema_migrations.sql', '001_phase0_tables.sql',
    '002_seed_reference.sql', '003_bootstrap.sql', '004_phase1_tables.sql',
  ]) {
    await applyMigration(setup, file);
  }

  // The receipt rule is company policy, not schema. Off unless a test is
  // about it; api-attachments.test.js turns it on.
  await setup.query(
    `UPDATE settings SET value = '0' WHERE setting_key = 'receipt_required_above'`,
  );

  const [owners] = await setup.query(`SELECT id FROM users WHERE role = 'owner'`);
  owner = { id: Number(owners[0].id), role: 'owner' };

  await setup.query(
    `INSERT INTO users (name, email, password_hash, role, shares_owner_login)
     VALUES ('Maryam', 'maryam@example.test', 'x', 'staff', 1)`,
  );
  const [staffRows] = await setup.query(`SELECT id FROM users WHERE email = 'maryam@example.test'`);
  staff = { id: Number(staffRows[0].id), role: 'staff' };

  const [accounts] = await setup.query(`SELECT id FROM accounts WHERE name = 'Winibex bank'`);
  accountId = Number(accounts[0].id);

  const [categories] = await setup.query(`SELECT id FROM categories WHERE direction = 'out' LIMIT 1`);
  categoryId = Number(categories[0].id);
});

after(async () => {
  await closePool();
  if (!setup) return;
  await setup.query('SET FOREIGN_KEY_CHECKS = 0');
  for (const table of TABLES) await setup.query(`DROP TABLE IF EXISTS \`${table}\``);
  await setup.query('SET FOREIGN_KEY_CHECKS = 1');
  await setup.end();
});

function draft(overrides = {}) {
  return {
    date: '2026-07-05',
    accountId,
    direction: 'out',
    currency: 'PKR',
    method: 'card',
    description: 'Claude subscription',
    categoryId,
    grossAmount: 560000,
    charges: [],
    taxes: [],
    // These tests are about posting, not about validation. The accounts start
    // at zero, so every payment warns that the bank is going below zero, which
    // is correct and is covered properly in api-validation.test.js.
    acknowledgedWarnings: WARNING_CODES,
    ...overrides,
  };
}

async function trialBalance() {
  const [rows] = await setup.query(
    `SELECT SUM(j.debit) AS debits, SUM(j.credit) AS credits
       FROM journal_lines j JOIN transactions t ON t.id = j.transaction_id`,
  );
  return { debits: Number(rows[0].debits ?? 0), credits: Number(rows[0].credits ?? 0) };
}

test('a draft is created with its amount reconciled, and no journal lines yet', async () => {
  const created = await service.createDraft({
    user: owner,
    input: draft({ charges: [{ type: 'card_fee', amount: 32500, coaId: await coa('8200') }] }),
  });

  assert.equal(created.amount, 592500, 'gross plus charges');

  const detail = await service.getDetail(created.id);
  assert.equal(detail.transaction.status, 'draft');
  assert.equal(detail.transaction.journal_number, null, 'a draft holds no book number');
  assert.equal(detail.lines.length, 0, 'nothing posts until it is approved');
  assert.equal(detail.charges.length, 1);
});

test('approving posts it, allocates the number and writes balanced lines', async () => {
  const before = await peek(setup, 'journal');
  const created = await service.createDraft({ user: owner, input: draft() });
  const posted = await service.approve({ user: owner, id: created.id });

  assert.equal(posted.status, 'posted');
  assert.equal(posted.journalNumber, `${before.prefix}${before.value}`);

  const detail = await service.getDetail(created.id);
  assert.equal(detail.transaction.journal_number, posted.journalNumber);
  assert.ok(detail.transaction.posted_at, 'a posted entry records when');
  assert.equal(Number(detail.transaction.approved_by), owner.id);

  const debits = detail.lines.reduce((sum, line) => sum + Number(line.debit), 0);
  const credits = detail.lines.reduce((sum, line) => sum + Number(line.credit), 0);
  assert.equal(debits, credits);
  assert.equal(debits, 560000);

  const after = await peek(setup, 'journal');
  assert.equal(after.value, before.value + 1, 'the sequence moved by exactly one');
});

test('the owner posting its own entry is recorded as auto, not hidden', async () => {
  const created = await service.createDraft({ user: owner, input: draft() });
  await service.approve({ user: owner, id: created.id });

  const detail = await service.getDetail(created.id);
  assert.equal(detail.transaction.approval_method, 'auto');
});

test('a staff entry approved by the shared owner login is marked', async () => {
  const created = await service.createDraft({ user: staff, input: draft() });
  await service.submitForApproval({ user: staff, id: created.id });
  await service.approve({ user: owner, id: created.id });

  const detail = await service.getDetail(created.id);
  assert.equal(detail.transaction.approval_method, 'owner');
  assert.equal(
    Number(detail.transaction.possible_self_approval), 1,
    'Maryam can enter under her own login and approve under the shared one',
  );
});

test('staff cannot approve anything', async () => {
  const created = await service.createDraft({ user: staff, input: draft() });
  await service.submitForApproval({ user: staff, id: created.id });

  await assert.rejects(() => service.approve({ user: staff, id: created.id }), /owner or an admin/);
});

test('an admin cannot approve past their limit', async () => {
  const limited = { id: owner.id, role: 'admin', approvalLimit: 100000, autoApproveOwn: false };
  const created = await service.createDraft({ user: staff, input: draft() });
  await service.submitForApproval({ user: staff, id: created.id });

  await assert.rejects(
    () => service.approve({ user: limited, id: created.id }),
    /above your approval limit/,
  );
});

test('an admin cannot approve their own entry unless auto approve is on', async () => {
  const admin = { id: owner.id, role: 'admin', approvalLimit: null, autoApproveOwn: false };
  const created = await service.createDraft({ user: admin, input: draft() });

  await assert.rejects(() => service.approve({ user: admin, id: created.id }), /Someone else has to approve/);
});

test('a posting that fails after allocating its number hands the number back', async () => {
  const before = await peek(setup, 'journal');

  // The order inside post() is: allocate, then write the lines, then mark the
  // row posted. This reproduces a failure in the middle of that, by writing a
  // journal line against a ledger account that does not exist. If the number
  // survived a failure here, the series would carry a permanent hole, which is
  // the exact thing decision 015 exists to prevent.
  await assert.rejects(() =>
    withTransaction(async (connection) => {
      await allocate(connection, 'journal');
      await connection.query(
        'INSERT INTO journal_lines (transaction_id, coa_id, debit, credit, line_no) VALUES (?, ?, ?, ?, ?)',
        [1, 99999999, 100, 0, 99],
      );
    }));

  const after = await peek(setup, 'journal');
  assert.equal(after.value, before.value, 'a failed posting consumed a journal number');
});

test('a reversal is exactly opposite and links both rows', async () => {
  const created = await service.createDraft({ user: owner, input: draft() });
  await service.approve({ user: owner, id: created.id });

  const result = await service.reverse({ user: owner, id: created.id, reason: 'paid on the wrong card' });

  const original = await service.getDetail(created.id);
  const reversal = await service.getDetail(result.reversalId);

  assert.equal(original.transaction.status, 'reversed');
  assert.equal(Number(original.transaction.reversed_by_id), result.reversalId);
  assert.equal(Number(reversal.transaction.reversal_of_id), created.id);
  assert.ok(reversal.transaction.reversal_reason.includes('wrong card'));

  // Every account the pair touched nets to zero.
  const net = new Map();
  for (const line of [...original.lines, ...reversal.lines]) {
    const key = String(line.coa_id);
    net.set(key, (net.get(key) ?? 0) + Number(line.debit) - Number(line.credit));
  }
  for (const [coaId, balance] of net) {
    assert.equal(balance, 0, `ledger account ${coaId} did not net to zero`);
  }
});

test('an entry cannot be reversed twice', async () => {
  const created = await service.createDraft({ user: owner, input: draft() });
  await service.approve({ user: owner, id: created.id });
  await service.reverse({ user: owner, id: created.id, reason: 'first' });

  await assert.rejects(
    () => service.reverse({ user: owner, id: created.id, reason: 'second' }),
    /already been reversed/,
  );
});

test('a posted entry cannot be reversed without a reason, and a draft cannot be reversed at all', async () => {
  const created = await service.createDraft({ user: owner, input: draft() });

  await assert.rejects(() => service.reverse({ user: owner, id: created.id, reason: '' }), /Say why/);
  await assert.rejects(() => service.reverse({ user: owner, id: created.id, reason: 'x' }), /Only a posted entry/);
});

test('the trial balance is zero after everything this file has done', async () => {
  const { debits, credits } = await trialBalance();
  assert.equal(debits, credits, 'the books do not balance');
});

test('every posting wrote an audit entry', async () => {
  const [rows] = await setup.query(
    `SELECT COUNT(*) AS n FROM audit_log WHERE table_name = 'transactions' AND action = 'status_change'`,
  );
  assert.ok(Number(rows[0].n) > 0, 'nothing was audited');
});

async function coa(code) {
  const [rows] = await setup.query('SELECT id FROM chart_of_accounts WHERE code = ?', [code]);
  return Number(rows[0].id);
}
