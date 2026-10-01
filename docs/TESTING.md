# Testing

The posting engine is the part that cannot be wrong. Most testing effort goes
there.

## API

Run against a real MySQL instance locally, in Docker. Never mock the database
for posting tests, because the guarantees being tested live in the database:
transactions, triggers, constraints.

```bash
cd api && npm run test
```

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

**Property test.** Generate a few hundred random valid operations: entries,
transfers, reversals, invoice payments, reimbursements. After each, assert the
trial balance is zero and every account balance matches its journal lines.
This finds the bugs nobody thought to write a case for.

**Validation.** One test per blocking rule, proving it blocks. One per warning,
proving it returns `409` and proceeds once acknowledged.

**Idempotency.** The same create request twice with one key produces one row.

**Permissions.** Staff cannot approve, cannot see others' submissions, cannot
read payroll when `payroll_visible_to_all` is false.

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

### Worked examples as tests

Every posting in `docs/CHART-OF-ACCOUNTS.md` is a test case asserting the exact
journal lines. If the chart document and the engine disagree, the test fails.

## Flutter

```bash
cd app && flutter test
cd app && flutter analyze
```

- Widget tests for the entry form: every step, every conditional field
- Golden tests for key screens in both light and dark themes
- Money formatting tests, including negatives and foreign amounts
- Provider tests with overridden API providers

## Before every deploy

- [ ] API tests green
- [ ] Flutter tests and analyze clean
- [ ] Migrations applied cleanly to a copy of production data
- [ ] Trial balance on the copy is zero
- [ ] Manual smoke test from the release checklist in `docs/DEPLOY.md`
