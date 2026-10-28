# Progress

Read this first. Update it before ending any session.

**Last updated:** 2026-10-27
**Current phase:** Phase 1 complete and live; D15 screens being added in batches.
**Where we stopped:** The full Phase 1 test ran locally (50 steps) and a
12-step re-test ran on production; every figure matched. All findings from it
are fixed and deployed: 389 API tests (386 pass, 3 argon2 skips), 87 Flutter
tests, analyze clean. Production was then wiped and rebuilt with migrations
000 to 006; the owner must set a new password at first sign-in. The books are
empty and ready for the real opening entry. What remains before real entries
is in "Pending before Phase 2" below; D15 is the main piece of work. Batch A
of D15 (people and permissions, decisions 062 and 063) is written and waits
passed and deployed on 2026-10-28, with migration 007 on production. Batch B
(tax and charge lines, six currencies, decision 064) is written and waits for
Ahmad's test run: 411 API tests, 108 Flutter tests expected. It needs no
migration.

The API runs on
Hostinger at api-accounting.winibex.com; the web app is at
accounting.winibex.com. Both deploy automatically: the API via Hostinger Git
integration on push, the web app via GitHub Actions building Flutter web and
uploading over FTP. Migrations 000 to 006 are applied on production. The
accountant review document is with the accountant.

## Deployed

- API at api-accounting.winibex.com, Node 24, MariaDB 11.8.9
- Web app at accounting.winibex.com, Flutter web with wasm, path URLs
- bcryptjs stays at ~295ms (decision 054, open item L closed)
- Collation: utf8mb4_unicode_ci everywhere (decision 054)
- Migrations applied through phpMyAdmin (Hostinger SSH has no Node)
- Owner password hash set directly on production, never committed
- CI/CD: API auto-deploys on push via Hostinger Git integration; web app
  deploys via GitHub Actions building `flutter build web --wasm` and uploading
  to Hostinger over FTP
- .htaccess handles force HTTPS, SPA fallback for path URLs, COOP/COEP headers
  for wasm, and cache headers for hashed assets

## Pending before Phase 2

These are not Phase 1 features. They are setup tasks and external dependencies.

1. **Accountant's answers.** Tax rates (Section 154A, 236Y, s.153), AFRS
   framework confirmation, and open questions in CHART-OF-ACCOUNTS.md and
   TAXES.md. Blocks: seeding tax rates (migration 005 or a seed run) and
   entering real tax entries. Does NOT block using the system for non-tax
   entries
2. **Opening balances at 30 June 2026.** Ahmad to supply real figures from bank
   statements, plus open invoices and the director loan balance at that date.
   Blocks: the opening entry
3. **Done 2026-10-27. Full Phase 1 test.** Locally, all 50 steps; on
   production, a 12-step re-test of the fixes; then production reset and
   rebuilt with migrations 000 to 006. Kit in `docs/PHASE1-TEST.md` and
   `api/scripts/test/`
4. **Done 2026-10-27. Owner password on production.** Set during the reset,
   with `must_change_password = 1`
5. **Done 2026-10-27. Onest font files** in `app/assets/fonts/`
6. **Dropped. check-docs.js guard script.** Decision 062
7. **PSEB certificate expiry date.** For the expiry warning flag. Ahmad to
   supply
8. **Defects found while writing the test.** D1 to D14 are fixed or
   settled, locally (decisions 056 to 058). `docs/PHASE1-TEST.md` says where
   each fix shows. Still open: D15, the Phase 1 features with no screen in the
   app yet (opening entry, transfers, reversal, reimbursements, people
   balances, vendors, cheques, tax and charge lines on the form, petty cash
   status, history merge, adding users, editing a draft, resubmitting a
   rejected entry, currencies other than USD on the form). Being built in
   batches: A people and permissions (written 2026-10-27); B tax and charge
   lines and all six currencies on the form; C transfers, reversal, paying
   someone back, the opening entry; D vendors and the cheque register; E
   editing a draft, resubmitting a rejected entry, and the taxes screen
9. **Done 2026-10-26.** Roll the fixes out to production, in this order. The API deploys
   itself on push, and the new code reads columns that only migration 005
   creates, so the order matters:
   1. phpMyAdmin, accounting database, SQL tab: paste
      `api/migrations/005_flag_resolution.sql`, Go.
      `SELECT * FROM schema_migrations;` shows six rows
   2. Commit and push the API and app changes from batches 1 to 3
   3. Wait for both deploys, then sign in at accounting.winibex.com and check
      the dashboard opens
   4. Run the full test (item 3) on production, then reset it

## Findings from the full Phase 1 test (2026-10-27)

Local run, all 50 steps. Books, dashboard and counts all matched. Fix F7 first
(decision 059), then the rest, then re-test only the affected steps, then the
production run and reset. Production has the same code but holds only test
data; no real entries until F7 is fixed.

| # | Finding | Severity | Status |
| --- | --- | --- | --- |
| F7 | A changed entry after a refused posting posts the old figures. Idempotency compares user and endpoint, not content | Critical | Fixed and deployed 2026-10-27: migration 006 on production, 381 API and 79 Flutter tests, re-tested in the app (one entry, 6,500) and with 6.17e (409) |
| F6a | `/approvals` rows had no `status`, so the app could not read the inbox | High | Fixed and pushed, 374 API tests |
| F6b | A reply the app cannot read is shown as "Could not reach the server" | High | Fix written: `isNetwork` by code, new `UNREADABLE` code and message, printed to the console |
| F5 | Tax lines not checked for direction, dates, active flag or size against their base (confirmed from the code) | High | Fix written: blocked with the tax named. The tax screen is open item P |
| F2 | Exchange rate and rupee amount may disagree | Medium | Fix written: refused beyond PKR 1, with the right figure |
| F1 | Wrong password shows no message on the sign-in screen | Medium | Fix written: sign-in no longer sets loading; the splash shows once only |
| F4 | Refresh or a typed address lands on the dashboard | Medium | Fix written: one MaterialApp.router from the first frame |
| F3 | The date picker does not open; dates are typed | Medium | Fix written: calendar button, typing still works |
| O1 | Two ways to record rebillable spend, one category named "absorbed" | Low | Decided, decision 062. Migration 007 and the new wording in batch A |
| O2 | "A issued cheque" should be "An issued cheque" | Low | Fix written |
| O3 | Technical messages an accountant cannot read, idempotency first | Low | Done for every message the app shows in normal use. Developer-only messages stay technical. Decision 061 |
| O4 | "Send it back" and "Mark as reviewed" dialogs too narrow, hints cut off | Low | Fix written: shared reason dialog, `AppSizes.dialogWidth` |
| O5 | A too-short review note closes the dialog silently | Low | Fix written: the dialog stays open and says why, for rejection too |
| O7 | 6100 Salaries and 6110 Staff welfare easy to mis-pick; 1,200 went to the wrong one in the test | Low, affects P&L | Fix written: searchable picker, code first, code order |

Test kit glitch: requests 8.9a to 8.9c could not read the flag id from 8.8d;
typing the id worked. To fix in the `.http` file. The guide writes JV-0014
where the system shows JV-14.

## Phase 2 scope

Clients and projects: client CRUD, projects (fixed/retainer/hourly), earning
accounts with partner splits, per-client profit. Should wait until Phase 1 is
used with real entries first.

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

API — all done:

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
- [x] Ledger list: search, filter by account, category, client, date range
- [x] Server-side search across all rows
- [x] Category picker grouped by main head
- [x] Approval inbox endpoint
- [x] Review list for flagged entries
- [x] Receipt upload and the receipt rules enforced (multer, 10 MB, images and PDF)
- [x] Edit history visible on each transaction (from audit_log)
- [x] Dashboard: cash held, money in/out this month, pending and flag counts
- [x] Change password endpoint with forced-change guard
- [x] Journal preview (POST /transactions/preview)
- [x] Thin users list for the people picker

Flutter — done:

- [x] Accounts list with live balances
- [x] Guided entry form: direction, currency, amount, paid by, rate or PKR,
      taxes and charges, category, receipt, review with journal preview
- [x] View journal entry panel on any posted transaction
- [x] Ledger list and approval inbox
- [x] Receipt upload field with camera/file picker
- [x] Dashboard with live figures
- [x] Flags review list
- [x] Change password screen with forced-change guard
- [x] Edit history panel on transactions
- [x] Path URL strategy (no hash routing) with .htaccess SPA fallback
- [ ] `find_in_page` for on-screen find (deferred, not blocking)

Deploy — done:

- [x] API on Hostinger via Git integration, auto-deploys on push
- [x] Web app on Hostinger via GitHub Actions + FTP
- [x] .htaccess: force HTTPS, SPA fallback, COOP/COEP, cache headers
- [x] CORS_ORIGINS set to the https origin
- [x] Migrations 000-004 applied via phpMyAdmin
- [x] Migration 005 applied via phpMyAdmin, 2026-10-26
- [x] Migration 006 applied via phpMyAdmin, 2026-10-27
- [x] Defect fixes pushed and deployed, 2026-10-26
- [x] Owner password hash set on production

347 API tests. 62 Flutter widget tests. Flutter analyze clean.

Defect fixes, 2026-10-26, deployed to production the same day:

- [x] D1 "No receipt" only on money out with no receipt
- [x] D2 flags clear themselves, and can be marked reviewed. Migration 005
- [x] D3 refused saves and approvals shown on screen
- [x] D4 only those allowed to post their own entries see "Save and post"
- [x] D5 rate-deviation warning
- [x] D6 transfer with no fee
- [x] D7 withholding from a vendor with no NTN or CNIC refused
- [x] D8 duplicate cheque number answers 409
- [x] D9 Pakistan business date
- [x] D10 the entry form starts again after a save
- [x] D11 dashboard month counts real money movement
- [x] D12 journal panel shows codes and names
- [x] D13 decision 055 kept, UI-GUIDE corrected
- [x] D14 unusual-amount warning with a fractional average
- [ ] D15 screens for the API-only features
  - [x] Batch A, deployed 2026-10-28: People screen (owner adds people, sets
        roles and limits, resets passwords, switches people off), decision 062
        rules, migration 007, "Client will pay this back"
  - [ ] Batch B, written 2026-10-28: tax and charge lines on the form, the
        payee for tax kept back, PKR, USD, GBP, AED, QAR, EUR. Decision 064
  - [ ] Batch C: transfers, reversal, paying someone back, opening entry
  - [ ] Batch D: vendors, cheque register
  - [ ] Batch E: edit a draft, resubmit a rejected entry, taxes screen

373 API tests (370 pass, 3 argon2 skips). 78 Flutter tests. Flutter analyze
clean.

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

The basic dashboard (cash per account, money in/out, pending and flag counts)
was built in Phase 1. This phase adds the full reporting suite.

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

### 2026-10-28 (D15 batch B written: taxes, charges, currencies)
Batch A and the People redesign passed (403 API, 99 Flutter), migration 007
applied on production, pushed. Ahmad chose a separate tax step after the
category, both a usual account and a picked one for charges, and the payee
asked in the tax step (decision 064). Server: `/taxes?direction=`,
`/taxes/suggest?taxIds=`, charge `coaId` optional with the usual account by
type and only cost accounts accepted, the tax module on Pakistan's date. App:
the seven-step form with the tax and charges step, six currencies, a shared
money field. 8 new API tests (411), 9 new Flutter tests (108). Taxes are not
on production yet, so suggestions show only locally with the test seed.

### 2026-10-28 (People screen redesign)
Batch A passed locally: 403 API tests, 95 Flutter tests, and the screen
checked in the browser. Ahmad asked for it to be easier to understand and
feel premium. Now: three role tiles always visible with a who-can-do-what
table one tap away; people grouped by role with counts, two per row on wide
screens; initials, role badges and icon chips on each card; Reset password
and Switch off in a menu, with a confirmation before switching off; the add
and edit dialog in sections with role cards, rupee separators while typing,
and a "Make one for me" temporary password with show and copy. Seven new
theme tokens. 4 more Flutter tests (99).

### 2026-10-27 (D15 batch A: people and permissions)
Ahmad decided the order of the D15 work and asked Claude to decide N, O and
O1 (decision 062) and to build adding people first. API: `/people` for the
owner (list, add, change, reset password), every change audited, sessions
revoked on switch off and reset; withholding without a vendor refused;
rejecting clears the entry's flags; migration 007. App: People screen under
Settings with the roles explained in plain words, add and edit dialogs, reset
password, switch off. "Rebillable to client" now reads "Client will pay this
back". Ahmad confirmed again that the office login keeps every right
(decision 063). 14 new API tests (403), 8 new Flutter tests (95). To run:
`migrate:up` locally, the tests, then 007 on production before pushing.

### 2026-10-27 (production re-test and reset)
Batch with F5, F2, O3, O7 passed (389 API, 87 Flutter) and was pushed with the
app fixes batch; the category list got a capped height (`AppSizes.menuMaxHeight`).
Production re-test, 12 steps, all matched: test data seeded, F1 sign-in
message, opening entry, calendar date, F7 (one entry at 6,500), F2 refusal,
approvals with three people and the reason dialog, transfers, a reversal, the
F5 wrong-direction refusal, the reused-key 409, mark reviewed, F4 refresh and
typed address, dashboard 684,450 = 560,000 + 140,000 - 15,550, trial balance
zero, JV-1 to JV-12 with no gaps. Then reset: backup, `phase1-reset.sql`,
migrations 000 to 006, owner hash with forced change, test receipts deleted.
Lesson: phpMyAdmin's "Enable foreign key checks" box overrides
`SET FOREIGN_KEY_CHECKS = 0` in a pasted script; untick it for the reset only.

### 2026-10-27 (F5, F2, O3, O7 written)
App fixes batch passed: 381 API tests, 86 Flutter tests, checks 1 to 4 in the
app. Then F5: each tax line is refused if its tax is unknown, switched off,
not in force on the entry date, for the other direction, or larger than its
base. F2: foreign amount x rate must be within PKR 1 of the rupees. O7: the
category picker is searchable, code first, in code order. O3 closed with a
stated scope. Decision 061. 8 new API tests (389), 1 new Flutter test (87).

### 2026-10-27 (app fixes written: F1, F4, F6b, F3, O2, O4, O5)
F1 and F4 had one cause: `app.dart` swapped in a second MaterialApp as a
splash whenever the session was loading, on launch and on every sign-in. Now
one MaterialApp.router exists from the first frame, the splash shows once
while the session is restored, and sign-in does not set loading. F6b: an
unreadable answer gets its own code and message instead of "network". F3: a
calendar button on the date. O4 and O5: one reason dialog for rejecting and
for marking reviewed, wider, and it says when the reason is too short. O2:
"An issued cheque". Decision 060. 8 new Flutter tests, 86 expected.

### 2026-10-27 (F7 deployed)
Migration 006 applied in phpMyAdmin, `schema_migrations` shows seven rows. Fix
pushed; Approvals and To review open on the live site. Locally the F7 scenario
now posts one entry at 6,500, and 6.17e answers 409 in plain words. Next batch:
F1, F4, F6b, F3, with O4 and O5.

### 2026-10-27 (F7 fix written)
Server: migration 006 adds `request_hash` to `idempotency_keys`; the
middleware stores a SHA-256 of the canonical request body and refuses the same
key with a different body, in plain words. Rows from before 006 are replayed
on person and address only and expire within a day. App: `EntrySave`
remembers the draft it created and edits it with `PATCH` when the entry
changed after a refusal, uploads a receipt only once, then posts. Tests: 4 in
`core-services.test.js`, 3 in `defect-fixes.test.js`, 1 new and 1 rewritten
widget test. API.md, SCHEMA.md, FRONTEND.md, PHASE1-TEST.md and the `.http`
file corrected; they had described a refusal the server never made. The guide
now writes journal numbers as the system does, JV-14 not JV-0014.

### 2026-10-27 (full Phase 1 test, local)
All 50 steps run with Ahmad, one at a time. Trial balance 144305900 both
sides, numbering 1 to 31 with no gaps, every ledger balance and flag count as
modelled. Findings in the table above. The serious one, F7, appeared only on
the last step, which deliberately tried the documented "known limit" and
showed the limit was not what the docs said. F6a was fixed during the run so
the approvals steps could continue. Decision 059 records the F7 and F2 fixes.

### 2026-10-26 (fixes rolled out to production)
Migration 005 applied in phpMyAdmin; `schema_migrations` shows six rows. The
fixes pushed to `main`, then the commit amended to drop a co-author line Ahmad
did not want and pushed again with `--force-with-lease`. Checked after the
deploy: GitHub Actions green, `/api/v1/health` up, sign-in, dashboard and To
review open without an error. Full Phase 1 test started locally. Test kit
lives in `api/scripts/test/`, with the three dummy upload files kept out of
git by `.gitignore`.

### 2026-10-26 (defect fixes, batches 1 to 4)
Fixed every code defect from the test guide, in four batches, each checked
by Ahmad's own test run before the next. Batch 1, the server: D5 to D9, D11,
D12, D14, with `core/dates.js` new and 15 tests in
`tests/defect-fixes.test.js`. Batch 2: D1 and D2, migration 005, `POST
/flags/:id/resolve`, receipts resolving their own flag, 8 more tests; 373 API
tests, 370 pass, 3 skip. Batch 3, the app: D3, D4, D10 and the Mark reviewed
button, `error_message.dart` new, 16 more Flutter tests; analyze clean, all
pass. Batch 4: API, SCHEMA, UI-GUIDE, FRONTEND, CODEMAP and TESTING updated,
and `docs/PHASE1-TEST.md` and its four files rewritten with figures from a
model of the fixed rules. The model checks itself: cash at the start of the
month plus In minus Out equals cash held, at every checkpoint. Decision 058
records what was settled while building, and two new open questions, N and O.

Lessons: the tests that existed did not exercise a refused save, a fee-less
transfer or the rate warning, which is how D3, D5 and D6 shipped. Each now has
a test. A local edit to an already applied migration (003) made `migrate:up`
refuse with "CHANGED SINCE APPLIED"; that is the checksum guard from decision
052 working, not a fault.

### 2026-10-20 (fix order, decision 056)
Agreed order: confirm the defects with a short local run of the test (D1, D3,
D5, D6, D7, D12), then fix D3 first, then D5, D6, D7 and D12, then D1, D2 and
D9, then run the full test locally and on production, then reset production.
Decision 056 settles how flags are cleared (D2): they clear themselves when
the cause is fixed, and the owner or an admin can mark one reviewed with a
note. Needs migration 005.

### 2026-10-19 (Phase 1 test guide)
Wrote `docs/PHASE1-TEST.md` and the four files in `api/scripts/test/`,
checked against the code as built rather than the plan. Every expected
balance, count and journal number was computed from a model of the posting
rules, and the two models (by entry and by journal line) agree. Writing it
turned up fifteen defects, D1 to D15, now pending item 8. The worst: the app
hides every server refusal (D3), and the rate-deviation percentage is off by
a factor of 100, so the warning never fires (D5). Neither was caught by the
test suites: the widget tests do not exercise a refused save, and no API test
appears to check the rate warning.

### 2026-10-19 (documentation audit for Phase 2 handoff)
Reviewed all 13 project documents against what was actually built. Updated
PROGRESS.md, CODEMAP.md, OVERVIEW.md, API.md, DEPLOY.md, SCHEMA.md,
TESTING.md and AGENTS.md to reflect Phase 1 completion. Added a clear
"Pending before Phase 2" section for the next session.

### 2026-10-03 (Phase 1 finished and deployed)
Steps 1.8 to 1.15, receipts, dashboard, flags, and the first real deploy.
Recorded in decisions 052 to 055.

API: taxes, vendors, cheques, petty cash, reimbursements, transfers, the
opening entry and history merge, the ledger with server-side search, approvals,
flags, the dashboard summary, the journal preview, categories, a thin users
list, and receipt upload. Nine feature modules in all.

App: the accounts list, the guided entry form with the journal preview and the
warnings dialog, the ledger with the journal panel, the approval inbox, the
dashboard, the flags review list, the change-password screen, and the edit
history panel. Receipt upload with file_picker. Path URLs with .htaccess SPA
fallback. Money never passes through a double on either side of the wire.

Deploy: a throwaway probe to the real server first, which caught that the
collation every migration used does not exist on Hostinger's MariaDB, before a
single table was created. Fixed to utf8mb4_unicode_ci. bcrypt timing on the
real server closed the argon2 question. Migrations applied by hand through
phpMyAdmin because the SSH shell has no Node. Web app deployed with GitHub
Actions building Flutter web and uploading over FTP. .htaccess configured for
force HTTPS, SPA fallback, COOP/COEP and cache headers.

Three package choices, each recorded: multer for uploads, file_picker for the
app (with a warning that it breaks its own API every major version), and the
collation change.

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
