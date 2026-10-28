# Testing

The posting engine is the part that cannot be wrong. Most testing effort goes
there.

## API

Run against a real MariaDB instance locally, in Docker. Never mock the database
for posting tests, because the guarantees being tested live in the database:
transactions, triggers, constraints.

```bash
cd api && npm run test
```

463 API tests after batch G, 2026-10-29: 460 pass, 3 skip (the argon2
tests, until that package is installed). 172 Flutter widget tests.
Flutter analyze clean.

### Must always pass

**Posting invariants**, tested on every posting path:
- Debits equal credits for every transaction
- Trial balance sums to zero after any sequence of operations
- A posted transaction cannot be updated, by service or by direct SQL. The
  trigger test runs raw SQL to prove it
- Reversal produces exactly opposite journal lines and links both rows
- `amount` reconciles with gross, tax and charges
- Balances computed from journal lines equal balances computed from
  transactions

**Property test.** 150 random valid operations: entries, transfers, reversals,
reimbursements. After each, assert the trial balance is zero and every account
balance matches its journal lines. This finds the bugs nobody thought to write
a case for.

**Validation.** One test per blocking rule, proving it blocks. One per warning,
proving it returns `409` and proceeds once acknowledged.

**Idempotency.** The same create request twice with one key produces one row.

**Permissions.** Staff cannot approve, cannot see others' submissions, cannot
read payroll when `payroll_visible_to_all` is false. Only the owner can list,
add or change people; there is never a second owner; switching someone off or
resetting their password ends their sessions and the old password fails
(`tests/users.test.js`, decision 063).

**Sequences.** Concurrent invoice creation produces no gaps and no duplicates.

**Tax snapshot.** Changing a tax rate does not change any existing transaction.

**ATL basis.** A tax deducted from Winibex uses Winibex's status. A tax Winibex
withholds uses the vendor's status on the payment date. A vendor with unknown
status gets the non-ATL rate and a warning.

**Constraints.** Raw SQL inserting a journal line with both debit and credit
fails. A negative amount fails.

**Opening and history.** Historical entries do not change any live balance
while `history_merged` is false. The merge check reports the exact difference
per account. Merge is refused while any difference is non-zero. After merge,
every balance equals what it was before merge, and 3400 is zero.

**Sessions.** Reusing a rotated refresh token revokes its whole family. Logout
revokes the family.

**Shared login.** The owner approving an entry made by a `shares_owner_login`
user sets `possible_self_approval`.

**FX revaluation.** Revaluation and its reversal net to zero, and the gain or
loss on settlement equals the difference from the original rate.

**Dashboard.** Cash balances, money in/out totals, pending and flag counts
match what the individual endpoints report. Cash held at the start of the
month plus money in minus money out equals cash held now, through transfers,
reversals and a cost paid personally. Decision 057.

**Receipts.** Upload, size limit, file type validation. Receipt requirement
enforced at posting time for money out at or above the threshold. Money in,
transfers, reimbursements, the opening entry and manual journals are exempt.
Decisions 055 and 057.

**Flags.** "No receipt" only on money out with no receipt. Attaching a receipt
resolves it. The owner or an admin can mark a flag reviewed with a note; staff
cannot; a resolved flag cannot be resolved twice. Decision 056.

**Defect regressions.** `tests/defect-fixes.test.js` holds one or more tests
for every defect found while writing `docs/PHASE1-TEST.md` (D1, D2, D5 to D9,
D11, D12, D14), so none can come back unnoticed.

**Ledger codes.** `tests/ledger-codes.test.js`: only the owner; a new code
takes its type and side from its first digit; income and expense codes join
the entry form, balance sheet codes never; a code or name is never used
twice; built-in codes and headings are left alone; a code with money on it,
or one a current tax posts to, stays on; every change is audited. Decision
068.

**Headings and import.** `tests/ledger-codes.test.js` also covers headings
(named or nearest, the same kind, before the code, renamed and moved, on while
anything under them is on) and the import: the template, owner only, a
preview that saves nothing, confirming, an exported file importing back with
nothing to change, switching off by file, a missing column.
`tests/taxes-import.test.js`: grouping rows into one tax, skips with reasons,
a new rate only from a later date with the old one ended the day before,
words in place, rules following the file. `tests/csv.test.js`: quoting, Excel's
byte order mark and line endings, columns found by name, the example row.
Decision 069.

**Edit history.** The audit log records every change, and the history endpoint
returns them in order with before and after values.

### Worked examples as tests

Every posting in `docs/CHART-OF-ACCOUNTS.md` is a test case asserting the exact
journal lines. If the chart document and the engine disagree, the test fails.

## Flutter

```bash
cd app && flutter test
cd app && flutter analyze
```

- Widget tests for the entry form: every step, every conditional field, journal
  preview, warnings dialog, a refused save shown on screen, a retry that reuses
  the idempotency key, the form starting again after a save
- Widget tests for the tax and charges step: suggestions sent with the
  entry, a changed figure marked as changed, a tax added by hand worked out
  by the server, the payee required for tax kept back, a charge on the usual
  account or a picked one, and taxes thrown away when the amount changes
- Widget tests for the six currencies
- Widget tests for the taxes screen and for fixing drafts, taken-back and
  sent-back entries
- Widget tests for the Settings home (cards, live summaries, each opening its
  page, the way back, owner only), the ledger codes screen (grouping, built-in
  codes without a menu, adding a code under a picked heading, adding a
  heading, editing, switching off, a refusal kept in the dialog), and import
  and export (downloads, the preview, confirming, nothing to save) and for
  find on this screen (Ctrl+F, the count, Enter and Shift+Enter, hidden text
  and the bar's own words not matched, Escape)
- Widget tests for vendors and cheques: what each card says, the forms, the
  allowed cheque moves, cancelling asks first, linking a payment
- Widget tests for batch C: moving money and its warnings, the petty cash
  top-up, paying back, reversing from the journal panel, and the opening
  balances, owner and admin
- Widget tests for the approval inbox, including a refused approval
- Widget tests for the review list and Mark reviewed
- Widget tests for the People screen: the owner row has no actions, a limit
  typed in rupees is sent in paisa, a short temporary password sends nothing,
  a refusal is shown, people grouped by role, the full table one tap away,
  switch off asks first, reset password, a generated password readable
- Unit tests for who may post their own entries (`auth_user_test.dart`)
- Widget tests for the accounts list with balances
- Money formatting tests, including negatives, foreign amounts and zero
- Provider tests with overridden API providers

## Before every deploy

- [ ] API tests green
- [ ] Flutter tests and analyze clean
- [ ] Migrations applied cleanly to a copy of production data
- [ ] Trial balance on the copy is zero
- [ ] Manual smoke test from the release checklist in `docs/DEPLOY.md`

## The full Phase 1 test

`docs/PHASE1-TEST.md` is the end-to-end run with dummy data and the expected
result of every step. Run it locally, then on production, then reset
production before real entries go in.
