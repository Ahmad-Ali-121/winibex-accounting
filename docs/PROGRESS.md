# Progress

Read this first. Update it before ending any session.

**Last updated:** 2026-10-01
**Current phase:** 0, foundation
**Where we stopped:** Step 0.1 complete and committed. Repo structure, local
MariaDB 11.8 in Docker, password module, lint and test setup. 23 tests, 20
passing, 3 skipped pending argon2. Next is step 0.2, the migration runner.

---

## Next three things

1. Sweep MySQL out of the docs. `AGENTS.md`, `docs/OVERVIEW.md`,
   `docs/SCHEMA.md` and `docs/DEPLOY.md` all say MySQL 8. The server is
   MariaDB 11.8, see decision 041
2. Step 0.2: migration runner, `schema_migrations` table, applied in order
   locally and through phpMyAdmin in production
3. Step 0.3: migration 001 per the table in `docs/SCHEMA.md`, Migrations

Accountant reviews TAXES and CHART-OF-ACCOUNTS in parallel, not blocking.

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

### Remaining

- [ ] Migration runner and `schema_migrations`
- [ ] Migration 001 written and applied
- [ ] Seed data: currencies, chart of accounts, categories, accounts, settings
- [ ] Seed taxes and tax rules. Deliberately not in Phase 0, waits for the accountant
- [ ] Company profile: NTN, PSEB number, logo, address
- [ ] Express app with MariaDB pool and health check
- [ ] Login, access tokens, refresh token rotation, logout
- [ ] Owner bootstrap with forced password change
- [ ] Role middleware: owner, admin, staff
- [ ] Audit log helper used by every write
- [ ] `sequences` table and gapless allocator
- [ ] Idempotency middleware and the 24 hour purge
- [ ] Flutter app scaffold with Riverpod and router
- [x] Theme file: `app/lib/core/theme/app_theme.dart`, Graphite and petrol, Onest
- [x] Strings file drafted: `app/lib/l10n/app_en.arb` and `l10n.yaml`
- [ ] Bundle Onest static font files under `app/assets/fonts/`
- [x] Glossary map drafted: `app/lib/core/glossary/glossary.dart`
- [ ] Reusable tooltip widget used by every term and column header
- [ ] Login screen wired to the API

## Phase 1 — Money in and out

- [ ] Accounts list with live balances
- [ ] Guided entry form: direction, currency, amount, paid by, rate or PKR,
      taxes and charges, category, receipt, review with journal preview
- [ ] Tax suggestion from tax rules, editable lines, rate snapshot
- [ ] Charges: bank, forex, platform, card fees
- [ ] Paid by a person, payable created, reimbursement flow
- [ ] Receipt rules enforced
- [ ] Vendors with NTN, CNIC, ATL status and check date
- [ ] ATL-based rate selection by the right party
- [ ] Cheque register
- [ ] Petty cash imprest and top-up suggestion
- [ ] Posted-row immutability trigger, in migration 002
- [ ] Opening entry at 2026-07-01, owner only, once
- [ ] Historical entries excluded from live balances until merged
- [ ] Optional approval limit on admins
- [ ] Auto-approve for admins, recorded as approval_method auto
- [ ] possible_self_approval marker for the shared owner login
- [ ] Idempotency keys on create
- [ ] Category picker grouped by main head
- [ ] Journal posting with debit and credit balance check
- [ ] Draft, pending, posted, reversed lifecycle
- [ ] Approval inbox for admin
- [ ] Approve, reject with reason
- [ ] Reverse a posted entry, reason required, both rows linked
- [ ] Blocking validation: unbalanced, missing fields, future date, zero amount
- [ ] Warning validation: duplicate, unusual amount, backdated, closed client
- [ ] Flags: no receipt, thin description. Review list for flagged entries
- [ ] View journal entry panel on any posted transaction
- [ ] Ledger list: search, filter by account, category, client, date range
- [ ] Server-side search across all rows
- [ ] `find_in_page` for on-screen find
- [ ] Transfers between accounts, two linked legs
- [ ] Receipt upload, optional
- [ ] Edit history visible on each transaction
- [ ] Reverse instead of delete, no edit after posting

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
Planning finished. Stack decided: Flutter, Node, Express, MySQL, on Hostinger
Business. Wrote AGENTS.md, CLAUDE.md, SCHEMA.md, PROGRESS.md, DECISIONS.md,
UI-GUIDE.md. Nothing built yet. Schema is draft and needs review before the
first migration.
