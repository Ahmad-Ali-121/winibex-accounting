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

403 API tests after people and permissions, 2026-10-27: 400 pass, 3 skip
(the argon2 tests, until that package is installed). 95 Flutter widget tests.
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
- Widget tests for the approval inbox, including a refused approval
- Widget tests for the review list and Mark reviewed
- Widget tests for the People screen: the owner row has no actions, a limit
  typed in rupees is sent in paisa, a short temporary password sends nothing,
  a refusal is shown, switch off and reset password
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
