# Progress

Read this first. Update it before ending any session.

**Last updated:** 2026-10-02
**Current phase:** Phase 1, money in and out. Steps 1.1 to 1.12 done. The API
side of Phase 1 is complete; what remains is Flutter.
**Where we stopped:** The whole API side of Phase 1 is built and tested. 313
tests pass (3 argon2 skips). Nine modules: transactions with the posting
engine, accounts, taxes, vendors, cheques, reimbursements, history, auth and
health. An entry created over HTTP moves the balance the accounts endpoint
reports, every worked posting in CHART-OF-ACCOUNTS.md is a test, and a property
test runs 150 random operations checking the books after every one. Next is
Flutter: the accounts list, the guided entry form, then the ledger and the
approval inbox.

---

## Next three things

1. Step 1.13, Flutter: the accounts list with live balances from `GET /accounts`
2. Step 1.14, Flutter: the guided entry form, step by step, with the journal
   preview before submitting
3. Step 1.15, Flutter: the ledger list with server-side search, the journal
   panel, and the approval inbox

Then what is still missing from the Phase 1 API: `GET /transactions` with
search and pagination, `GET /categories`, `GET /flags`, `GET /approvals`, and
attachments.

Done this session, for reference:

1. Step 1.2, migration 004: transactions, journal_lines, transaction_taxes,
   transaction_charges, entry_flags, attachments, vendors, reimbursements,
   reimbursement_items, cheques, with the posted-row immutability trigger,
   CHECK constraints and indexes. Keys are `BIGINT UNSIGNED` to match
   migration 001. Proved by raw SQL tests before anything is built on it
2. Step 1.3 and 1.4, `core/money.js` and the posting engine. Every worked
   posting in CHART-OF-ACCOUNTS.md becomes a test asserting exact journal lines
3. First real Hostinger deploy. Throwaway `probe-deploy.js` to a subdomain to
   confirm Node 24 runs the code, then decide argon2 versus bcryptjs with no
   real passwords at stake. Open item L

---

## Phase 0 — Foundation

### Step 0.1 — done 2026-10-01

- [x] Repo structure: `api/`, `app/`, `mcp/`, `docs/`
- [x] Local MariaDB 11.8 in Docker, strict mode, UTC, utf8mb4
- [x] Separate `winibex_test` database so tests never touch development data
- [x] `api/core/password.js`, bcryptjs with argon2id switchable
- [x] Lint and test commands, no test framework. Decision 043
- [x] Database behaviour proved by test: CHECK constraints enforced, strict
      mode on, rollback complete, JSON round trips, BIGINT exact
- [x] argon2 decision settled without a blocking deploy. Decision 042

### Steps 0.2 to 0.14 — done 2026-10-01

- [x] Migration runner and `schema_migrations`, with a DELIMITER-aware SQL
      splitter so the Phase 1 trigger survives in one piece
- [x] Migration 001: the twelve Phase 0 tables, with constraints proven by test
- [x] Migration 002: seed currencies, chart of accounts, categories, settings,
      sequences
- [x] Taxes deliberately NOT seeded. Waits for the accountant
- [x] Migration 003: owner bootstrap, company profile, company accounts
- [x] Company profile holds the legal name; NTN, PSEB, logo, address are
      edited from the UI later
- [x] Express app, MariaDB pool, standard error shape, `/health`
- [x] Login, access tokens, refresh rotation with families, logout
- [x] Owner bootstrap with forced password change. Decision 050
- [x] Role middleware: owner, admin, staff
- [x] `withTransaction`, and the audit log helper that rolls back with it
- [x] `sequences` table and gapless allocator, proven under concurrency
- [x] Idempotency middleware and the 24 hour purge
- [x] Flutter scaffold: ProviderScope, MaterialApp.router, go_router, gen-l10n
- [x] Theme file wired: `app/lib/core/theme/app_theme.dart`
- [x] Strings file: `app/lib/l10n/app_en.arb`, 201 keys
- [ ] Bundle Onest static font files under `app/assets/fonts/` — Ahmad to
      download the four weights from Google Fonts
- [x] Glossary and the `TermTooltip` widget, with tests that no term repeats
      its label and no two terms share an explanation
- [x] Login screen wired to the API, with refresh-on-401 and a session guard

## Phase 1 — Money in and out

API, done:

- [x] Accounts list with live balances
- [x] Tax suggestion from tax rules, editable lines, rate snapshot
- [x] Charges: bank, forex, platform, card fees
- [x] Paid by a person, payable created, reimbursement flow
- [x] Vendors with NTN, CNIC, ATL status and check date
- [x] ATL-based rate selection by the right party
- [x] Cheque register
- [x] Petty cash imprest and top-up suggestion
- [x] Posted-row immutability trigger, in migration 004
- [x] Opening entry at 2026-07-01, owner only, once
- [x] Historical entries excluded from live balances until merged
- [x] Merge check and merge, refused while any account differs
- [x] Optional approval limit on admins
- [x] Auto-approve for admins, recorded as approval_method auto
- [x] possible_self_approval marker for the shared owner login
- [x] Idempotency keys on create
- [x] Journal posting with debit and credit balance check
- [x] Draft, pending, posted, reversed lifecycle
- [x] Approve, reject with reason
- [x] Reverse a posted entry, reason required, both rows linked
- [x] Blocking validation: unbalanced, missing fields, future date, zero amount,
      inactive account, cash below zero, date rules around go-live
- [x] Warning validation: duplicate, repeated description, unusual amount,
      backdated, bank below zero, large cash, rate deviation
- [x] Flags: no receipt, thin description
- [x] Transfers between accounts, two linked legs through 1118
- [x] Reverse instead of delete, no edit after posting
- [x] Property test: 150 random operations, books checked after every one

API, still to do:

- [ ] Ledger list: search, filter by account, category, client, date range
- [ ] Server-side search across all rows
- [ ] Category picker grouped by main head
- [ ] Approval inbox endpoint
- [ ] Review list for flagged entries
- [ ] Receipt upload and the receipt rules enforced
- [ ] Edit history visible on each transaction

Flutter:

- [ ] Accounts list with live balances
- [ ] Guided entry form: direction, currency, amount, paid by, rate or PKR,
      taxes and charges, category, receipt, review with journal preview
- [ ] View journal entry panel on any posted transaction
- [ ] Ledger list and approval inbox
- [ ] `find_in_page` for on-screen find

## Phase 2 — Clients and projects

- [ ] Client CRUD with status
- [ ] Projects: fixed, retainer, hourly
- [ ] Time entries for hourly clients
- [ ] Rebillable flag and default per client
- [ ] Earning accounts with split percent
- [ ] Earning receipt entry: gross, fee, partner share, net
- [ ] Per-client profit view

## Phase 3 — Quotations, invoices, documents

- [ ] Company document template
- [ ] Quotations, convert to invoice
- [ ] Invoice create with line items and tax lines
- [ ] PDF generation in Node, not headless Chrome
- [ ] Record payment, linked to a real transaction
- [ ] Partial payments
- [ ] Status derived from payments and due date
- [ ] Aging buckets
- [ ] Rebillable spend pulled onto an invoice
- [ ] Payment receipts issued to clients
- [ ] Payment vouchers
- [ ] Client statement of account
- [ ] Generated documents kept with versions

## Phase 4 — Payroll

- [ ] Employee records with join and exit dates
- [ ] Salary history, never overwritten
- [ ] Monthly run generation
- [ ] Approve once, post all lines
- [ ] Tax deduction lines
- [ ] Employee advances recovered through payroll
- [ ] `payroll_visible_to_all` setting enforced on every endpoint

## Phase 5 — Recurring costs

- [ ] Recurring cost catalog
- [ ] Daily cron creating pending instances
- [ ] Confirm with real amount
- [ ] Skip an instance
- [ ] Yearly cost per tool view

## Phase 6 — Dashboard and reports

- [ ] Cash per account
- [ ] Income against spending, current month
- [ ] Runway: months of fixed cost covered
- [ ] Client profit
- [ ] Receivables summary
- [ ] Profit and Loss
- [ ] Cash Flow
- [ ] Balance Sheet
- [ ] Trial Balance
- [ ] General Ledger
- [ ] Tax summary by section
- [ ] Quarterly s.165 withholding statement export and filing tracker
- [ ] Withholding certificates received register
- [ ] Bank statement import and reconciliation
- [ ] Fixed asset register and monthly depreciation
- [ ] Year-end FX revaluation with automatic reversal
- [ ] FBR return head mapping working paper
- [ ] CSV and Excel export

## Phase 7 — Android app

- [ ] Build target configured
- [ ] Submit expense with camera photo
- [ ] My submissions list with status
- [ ] Approve from phone
- [ ] Offline queue, sync when online

## Phase 8 — History before 1 July 2026

- [ ] Sheet brought current by Maryam
- [ ] Historical entries entered or imported from both sheets, invoices, clients
- [ ] Category back-fill for the uncategorised months
- [ ] Merge check shows zero difference on every account
- [ ] History merged, opening entry reversed, 3400 at zero

## Phase 9 — MCP server

- [ ] Server scaffold reusing the API's data layer
- [ ] Tools: balances, transactions, client profit, receivables, runway
- [ ] Read-only, no write tools initially
- [ ] Auth

---

## Blocked, waiting on Ahmad

- [x] PSEB active, on ATL, not PRA registered, paid-up capital up to PKR 1 million
- [x] Hostinger database engine: MariaDB 11.8.9. Node 24.x
- [ ] PSEB certificate expiry date, for the expiry warning
- [ ] Current monthly salary for Ahmad Ali Khan, Maryam, Fazal
- [ ] Upwork IDs and split percent for each
- [ ] Real balances on 30 June 2026 for every account, from bank statements,
      plus open invoices and the director loan balance at that date
- [ ] Which past ad spend was rebilled, which was absorbed
- [ ] Open items in `docs/DECISIONS.md`

---

## Session log

### 2026-10-02 (steps 1.5 to 1.12, the rest of the Phase 1 API)
Nine modules, about forty endpoints, 190 tests became 313. Everything recorded
in decision 053. What the build taught us, in the order it hurt:

1. The balance query counted only `posted` rows, so reversing an entry moved
   the balance by twice the amount. No constraint could have caught it: the
   data was valid and the trial balance still summed to zero. A test asserting
   a business fact caught it
2. A transfer could not be posted at all with the chart as it stood. Both legs
   balancing meant recording the movement twice. 1118 Funds in transit is the
   answer, seeded in migration 002
3. The posting path deleted and rewrote the journal lines of a manual entry,
   and the trigger from migration 004 refused. The rule being in two places is
   what caught the service misbehaving
4. The merge check compared income and expense accounts, which can never
   reconcile against an opening entry, so the merge could never have happened
5. `LINES` is reserved in MariaDB. Found by the property test on its first
   refused operation, four seconds in
6. mysql2 refuses an `undefined` bind parameter, which surfaced as a 500 on a
   perfectly valid PATCH

Migration 002 was edited three times and the database rebuilt each time, which
is only acceptable because nothing is deployed. Decision 052 says that stops at
the first Hostinger deploy.

Still open: the accountant's review, the first deploy and the argon2 call
(item L), the Onest font download, the `check-docs.js` guard script, and open
item D, whether staff should see company balances at all.


### 2026-10-02 (steps 1.2 to 1.4a, the schema and the posting engine)
Migration 004 applied: thirteen tables, four triggers, every constraint proved
by raw SQL in `tests/schema-004.test.js`. `core/money.js` holds every figure in
integer paisa with no float path. `modules/transactions/posting.js` builds the
journal lines, and every worked posting in CHART-OF-ACCOUNTS.md is a test
asserting the exact lines. 124 tests became 190.

Five things the database or a test refused, all recorded in decision 052:
`account_id` cannot be NOT NULL, the reconciliation rule needed `withheld_total`
for tax Winibex deducts, `entry_type` needed `journal` and `method` needed
`card`, a reversal carries no tax breakdown, and rounding is half away from zero.

Three defects found in the Phase 0 foundation along the way:

1. `core/sql-split.js` emitted an empty statement when a comment block
   containing a bare `--` line stood alone between two statements. Migration 004
   is the first file where that happens, because DELIMITER forces a push.
   `isOnlyComments` and `LINE_COMMENT` disagreed about what a comment is
2. `core/audit.js`, `core/idempotency.js` and `core/json.js` had been deleted by
   commit 4112879 and nobody noticed, because the test that imports them could
   not run. Restored from the commit before it
3. Git was rewriting line endings on checkout, which changes a file's checksum,
   so the migration runner reported an unedited file as edited. `.gitattributes`
   now forces LF on `*.sql`

Also learned: the MariaDB container accepts connections before its first-boot
setup has finished, and anything written in that window is wiped when it
completes. Wait with `mariadb-admin ping --wait`, never by eye.

### 2026-10-02 (step 1.1, documentation pass before Phase 1 code)
No code written. Read every document against the others and against the
migrations already applied, and found eight disagreements. All are recorded in
decision 051, with the rules adopted to stop them recurring at the end of
DECISIONS.md.

What was wrong:

1. The MySQL to MariaDB sweep after decision 041 had replaced the word
   everywhere, including in sentences contrasting the two, in facts that belong
   to MySQL, and in the driver's package name. Repaired in DECISIONS 005, 041,
   047 and 048, SCHEMA.md, OVERVIEW.md, DEPLOY.md and PROGRESS.md
2. The driver is `mysql2` at `^3.23.0`, confirmed from `api/package.json`. Four
   documents called it `MariaDB2`, which does not exist. AGENTS.md was right
3. A stale chat instruction said the owner login cannot transact, which is
   decision 034. Ahmad confirmed decision 036 stands: it can
4. `transactions` had no column for the journal number that decision 015
   requires. Added, allocated at posting rather than at draft creation
5. `accounts.coa_id` exists in migration 001 but was absent from SCHEMA.md, so
   the account balance had no documented join
6. Migration 001 uses `BIGINT UNSIGNED` keys while SCHEMA.md says `BIGINT`.
   Migration 004 must match or its foreign keys will not create
7. SCHEMA.md's migration table and one Phase 1 checklist line still numbered
   Phase 1 as migration 002, which decision 046 had already reassigned to seed
   data. Phase 1 is migration 004
8. UI-GUIDE.md's blocking rules forbade an opening entry dated on or after
   1 July 2026, which is the only date the opening entry may carry. Split into
   two rules
9. FRONTEND.md listed `riverpod_lint` as a package in use. Decision 049 left it
   out on purpose. Marked as not installed

Still open: the guard script `api/scripts/check-docs.js`, the first Hostinger
deploy and the argon2 call (item L), the Onest font download, and the accountant
review of TAXES.md and CHART-OF-ACCOUNTS.md.


### 2026-10-01 (Phase 0 complete)
Steps 0.2 through 0.15 in one run. The whole foundation: migration runner,
migrations 001 to 003, the API (health, auth, roles), the core services the
posting engine will sit on (transactions, audit, sequences, idempotency), the
Flutter scaffold, the tooltip system, and a login screen that works end to end.

124 API tests pass (3 argon2 skips). Flutter analyze clean, widget tests pass.
Login confirmed working against the live local API.

Things the version bumps taught us, all now in decisions 045 to 050:

1. mysql2 3.23 parses JSON columns itself. Three docs said otherwise and the
   code double-parsed. Fixed with one `core/json.js` helper. Decision 047
2. MariaDB refuses a CHECK that mentions an AUTO_INCREMENT column. The
   "not its own parent" rule moved to the service layer. Decision 045
3. Riverpod 3 removed `valueOrNull` (use `.value`), flutter_secure_storage 11
   removed `encryptedSharedPreferences` (Keystore is the default now),
   go_router is at 18. Decision 049
4. Node runs test files in parallel, and the database tests share one database,
   so the suite runs with `--test-concurrency=1`
5. `node --test tests/` breaks on Windows PowerShell; dropping the path works
6. A browser login needs CORS_ORIGINS to match the Flutter web port exactly;
   run on a fixed `--web-port`

Reserved-word column renames and the DATETIME-over-TIMESTAMP choice are in
decision 045. Still open: the first Hostinger deploy and the argon2 call
(item L), the Onest font download, and the accountant review.

### 2026-10-01 (step 0.1)
First code written. Repo structure, local MariaDB in Docker, password module,
lint and tests.

Three things surprised us, all caught by tests before anything was built on
top of them:

1. The Hostinger database is MariaDB 11.8, not MySQL 8. Every document said
   MySQL. Decision 041 records what actually differs. The docs still need the
   sweep
2. A test proved the driver silently rounds a BIGINT past JavaScript's safe
   integer limit, changing the last four digits with no error. Fixed with
   `supportBigNumbers`, decision 044. The test stays as the guard
3. The argon2 question was blocking progress for no good reason. Settled by
   building the password module to support both methods and reading the method
   from the stored hash, so the choice can be made or changed at any time.
   Decision 042

Also learned: `node --test tests/` breaks on Windows PowerShell, which strips
the trailing slash and makes Node treat the folder as a file. Dropping the path
entirely works everywhere.

### 2026-10-01 (sixth pass)
Claude Code reviewed the docs before migration 001 and found real gaps. Fixed:
per-phase migrations, trigger moved to 002, refresh tokens table, settings
columns, chart and category columns, owner bootstrap. Ahmad revised roles:
no approver role, shared owner login approves. Books go live 1 July 2026
with an opening entry, history merged later.

### 2026-10-01 (fifth pass)
Applied the external review. Verified tax year 2027 rates against the FBR rate
card: s.153 IT 4% and 8%, specified services 7% and 14%, independent
developers 15% and 30%, s.236Y 0.5% and 1%. Corrected the review on specified
services and on ATL basis, which depends on the party the tax is about. Added
vendors, compliance, banking, assets, advances and FX tables, retention,
indexes and constraints. Fixed the personal card posting example.

### 2026-10-01 (fourth pass)
Wrote OVERVIEW.md and the external review prompt. Drafted the single theme
file, the strings ARB, l10n config and glossary map. Palette and typeface are
proposals awaiting confirmation.

### 2026-10-01 (third pass)
Added multi-currency with user-entered rates, Odoo-style tax engine, paid-by and
reimbursements, mandatory receipt rules, expanded validation, documents
(quotations, receipts, vouchers, statements). Wrote CHART-OF-ACCOUNTS.md for
AFRS for SSEs, TAXES.md with tax year 2027 research and open questions,
FRONTEND.md with Riverpod 3 conventions, API.md, DEPLOY.md, TESTING.md,
README.md.

### 2026-10-01 (second pass)
Reversed the plain-language UI decision: official accounting terms with tooltip
explanations instead. Added posted-entry immutability, layered validation,
gapless numbering, feature-module architecture, light and dark theming.
Period locking built but off by default.

### 2026-10-01
Planning finished. Stack decided: Flutter, Node, Express, MariaDB, on Hostinger
Business. Wrote AGENTS.md, CLAUDE.md, SCHEMA.md, PROGRESS.md, DECISIONS.md,
UI-GUIDE.md. Nothing built yet. Schema is draft and needs review before the
first migration.
