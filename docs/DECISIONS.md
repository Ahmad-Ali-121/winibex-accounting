# Decisions

Dated log. Add to the bottom. Do not rewrite history, supersede it.

---

### 001 — Replace the spreadsheet rather than extend it
2026-10-01

The sheet has a hand-typed balance column, five accounts sharing one balance,
twelve months of missing categories, and no exchange rates on USD receipts.
None of these are fixable with more columns.

---

### 002 — One ledger, fund-tagged, instead of two sheets
2026-10-01

The sheet keeps operations and investor spending separate. Accounting-wise that
split is not real: investor money is a liability, and what it buys is ordinary
company expense. The split had also already broken, with investor entries
appearing in the operations sheet.

Transactions carry `fund_source`. Investor reports are a filter, not a
second set of books.

---

### 003 — PKR base currency, rate derived from actual receipts
2026-10-01

All costs are PKR. Foreign receipts land at whatever rate the bank gives after
fees. A fixed or API rate would drift from the bank within a month. We store
the original amount, the PKR actually received, and derive the rate.

---

### 004 — Flutter over React
2026-10-01

Both web and Android were wanted from the start. Flutter gives both from one
codebase. React would mean either two codebases or a responsive web page that
is not an app.

Counted against it: Flutter web cannot support the browser's own Ctrl+F,
because canvaskit and skwasm paint text to a canvas. Mitigated by server-side
search plus the `find_in_page` package.

Risk accepted: if dense ledger views prove painful, only the frontend is
rebuilt. The API and database are unaffected.

---

### 005 — MariaDB, not MongoDB
2026-10-01

Double-entry accounting needs transactions, joins and referential integrity.
MariaDB is also what Hostinger provides as managed storage. MERN was considered
and the M was dropped.

Superseded in part by decision 041: the Hostinger server is MariaDB, not MySQL.
The reasoning above is unchanged.

---

### 006 — MCP server in Node, not Dart
2026-10-01

Dart MCP packages exist (`dart_mcp` from the Dart team, `mcp_dart` third party).
Rejected because the MCP server needs the same database layer, auth and
calculations as the API. In Dart those would be written and maintained twice.
Hostinger also runs Node, not Dart binaries.

---

### 007 — Soft delete only
2026-10-01

Not a preference. Accounting records must stay auditable, so transactions,
invoices and payroll are cancelled, never removed.

---

### 008 — Balances are computed, never stored
2026-10-01

A stored balance is how the spreadsheet drifted. Current balance is the opening
balance plus approved transactions, calculated on request. If this becomes slow
at volume, a cached snapshot with a rebuild command is the fix, not a column.

---

### 009 — Permission checks built now, enforcement later
2026-10-01

Everyone can currently see all salaries. Ahmad wants to restrict this later.
Every payroll endpoint checks `payroll_visible_to_all` from day one even though
it currently passes, because retrofitting permission checks means touching every
endpoint and missing one.

---

### 010 — Financial year July to June
2026-10-01

Matches the Pakistan tax year.

---

### 011 — Official accounting terminology, explained by tooltips
2026-10-01

Supersedes the plain-language approach in the first draft of UI-GUIDE.md.

The interface uses Debit, Credit, Journal Entry, Accounts Receivable and so on.
Every term carries a tooltip written in this company's own terms. Renaming
standard concepts would create a private vocabulary that transfers to no other
accounting software and makes handover harder.

---

### 012 — Posted entries are immutable
2026-10-01

Refines decision 007. Three states that matter: draft is editable, posted is
not, reversed means a reversing entry exists. No one can edit a posted entry,
including admin. Corrections are reversal plus re-entry, with a required reason.

Enforced in the service layer and again by a database trigger, because an
application-level rule is one bad script away from being bypassed.

---

### 013 — Layered validation rather than one blanket rule
2026-10-01

Blocked: unbalanced journal lines, missing category or account, zero or negative
amount, future date, payment with no linked cash transaction, any write to a
posted row.

Warned, proceed after confirming: possible duplicate, unusual amount for the
category, backdated more than 90 days, posting to a closed client.

Flagged for later review: no receipt, thin description, category unusual for
that client.

Warnings must name the specific record they matched against. A warning the user
cannot investigate becomes a warning they dismiss by reflex.

---

### 014 — No period locking for now, table built anyway
2026-10-01

Ahmad chose to keep months open. Acceptable only because decision 012 makes
posted entries immutable, so there is nothing to protect a closed month from.
The `period_locks` table and setting exist unused, so enabling locking later is
configuration rather than a migration.

If entries were editable and months were open, this would have been argued
against.

---

### 015 — Gapless numbering
2026-10-01

Journal entries and invoices draw from a `sequences` table, allocated inside the
same database transaction as the insert. A gap in a numbered series is the first
thing an auditor questions.

---

### 016 — Feature-module architecture
2026-10-01

Both API and app are organised by feature, not by technical layer. Adding a
module means adding a folder, not editing ten shared files.

API: `api/modules/<feature>/` holding routes, service, repository, schema.
App: `app/lib/features/<feature>/` holding data, domain, presentation.

Shared code lives in `core/` and is imported by features. Features never import
from each other directly, only through a documented service interface. This is
what keeps the thing extensible later.

---

### 017 — User-entered exchange rates
2026-10-01

Supersedes decision 003 in part. The user may enter the rate or the PKR figure
and the other is computed. Both are stored with `fx_rate_source`. When a bank
advice is available it wins, so the books still match the bank statement.

---

### 018 — Odoo-style tax engine, rates as data
2026-10-01

Taxes are rows with authority, law reference, kind, rate, adjustable flag,
ledger account and effective dates. Tax rules decide what the form suggests.
Each transaction snapshots the rate it used. Pakistan rates change every
budget, so nothing tax-related is a constant in code.

Research for tax year 2027 found conflicting figures for Section 153 and the
card payment levy. Those seeds are left for the accountant rather than guessed.

---

### 019 — Chart of accounts built for AFRS for SSEs and the FBR return
2026-10-01

There is no FBR-mandated chart. Winibex is a small-sized private company, so
the chart is structured to produce statements under ICAP's Revised AFRS for
Small-Sized Entities, and each account maps to an FBR return head. Export and
local revenue are separate accounts because they are taxed differently.

Rebillable spend posts to an asset (1123), not an expense, so it never touches
profit. Investor money posts to a liability.

---

### 020 — Paid by a person creates a payable
2026-10-01

When someone pays company costs personally, the entry credits a payable to that
person. Reimbursement clears it. The amount owed is computed, not stored. This
replaces the current practice of mixing personal accounts into the company
balance.

---

### 021 — Mandatory receipts by rule
2026-10-01

Required for all client receipts, all foreign currency transactions, all
reimbursement claims, and money out above a configurable threshold. Optional
elsewhere, flagged when missing.

---

### 022 — Riverpod 3 with code generation
2026-10-01

Riverpod 3.2 is stable with riverpod_generator 4. All providers are generated.
Async providers and AsyncNotifier for anything network-backed. Experimental
features such as offline persistence stay out of financial flows.

---

### 023 — Documents generated from data
2026-10-01

Quotation, invoice, payment receipt, payment voucher, salary slip, client
statement. All generated server-side from existing records, never typed
separately. Every generated PDF is kept with a version number.

---

### 024 — Idempotency keys on money-creating requests
2026-10-01

A double tap or a dropped mobile connection must never post the same expense
twice. The client generates a key per form, the server returns the stored
result on repeat.

---

### 025 — Same-person create and approve is allowed but flagged
2026-10-01

With a team of four, strict segregation of duties would block the admin from
recording their own entries. Allowed, always flagged, always visible.

---

### 026 — One theme file, one strings file
2026-10-01

All design values in `app_theme.dart`, all user-facing text in `app_en.arb`
through Flutter's standard gen-l10n. ARB rather than a hand-written Dart
constants file because it handles placeholders and plurals properly and makes
a second language a new file rather than a refactor.

---

### 027 — Ledger-paper visual direction, Onest typeface
2026-10-01

Red ink for negatives, ruled tables, hierarchy-based radius. From three
options (Ledger, Ink and brass, Graphite and petrol), Ahmad chose Graphite and
petrol: near-monochrome with one petrol accent, the most minimal option.

Trade-off accepted: with most of the interface grey, money in and money out
are less visually distinct. Direction must always also be carried by sign,
label or column, never by colour alone, which the UI guide already requires.

Typeface Onest, chosen by Claude at Ahmad's request for a pretty, minimal look.
Seven candidates were checked by opening the font files: all carried tabular
figures. IBM Plex Sans was the most legible but read technical. Inter and Geist
were rejected as the default of nearly every SaaS and developer tool. Onest had
the most open shapes at table sizes.

---

### 028 — Fonts bundled, not fetched
2026-10-01

Runtime font fetching adds latency and can be blocked by the COEP header the
Wasm build requires.

---

### 029 — Single company
2026-10-01

The AOP registered with Qasim in June 2025 was opened by mistake, belongs to the
same business, and is not used. No `company_id` on tables. If a genuinely
separate entity ever needs books, it gets its own database and deployment,
which is simpler and safer for a team of four than multi-tenancy.

Follow-up for the accountant: an unused AOP still registered with FBR may have
nil-return obligations until formally closed.

---

### 030 — ATL rates, decided by whoever the tax is about
2026-10-01

Every tax carries an ATL and a non-ATL rate. The external review proposed
reading Winibex's own ATL status for every rate. That is only right when tax is
deducted from Winibex. When Winibex withholds from a vendor, the vendor's status
decides, checked on the payment date. Each tax line records which party's status
was used and what it was.

---

### 031 — Vendors table
2026-10-01

Missing from the first schema. Needed for withholding rates, NTN and CNIC on the
quarterly s.165 statement, and certificates of tax deducted.

---

### 032 — Accepted from the external review
2026-10-01

Withholding certificate register, quarterly s.165 statement tracking, FBR
return heads table, year-end FX revaluation with reversal, bank reconciliation,
fixed asset register with depreciation runs, cheque register, petty cash imprest,
employee advances recovered through payroll, PDF data snapshots with hashes,
document types on attachments, composite indexes, CHECK constraints, API rate
limiting.

Corrected from the review: tax year 2027 specified services are 7% and 14%, not
6% and 12%. InnoDB already indexes foreign keys, so composite indexes were added
rather than single-column ones.

Rejected: none. Deferred: budgeting, audit log viewer.

---

### 033 — Ten-year retention
2026-10-01

Companies Act 2017 section 220. No purge job on any accounting table. The only
purged table is `idempotency_keys`, after 24 hours.

---

### 034 — Approval model
2026-10-01

Supersedes "Ahmad approves every entry" and decision 025.

- **Owner**: the winibexoffice account. Settings, users, roles, limits. It is
  shared by several people, so it cannot create, approve or reverse
  transactions. Chosen by Claude at Ahmad's request
- **Admins**: named personal logins. Everyone who shares winibexoffice gets
  one. Approve any amount. Own entries auto-approve if enabled
- **Approvers**: Ahmad, Fazal, Maryam. Approve others' entries up to 10,000 PKR
- Non-admin entries always need an approver. Above 10,000 PKR, an admin
- Nobody approves their own entry
- Auto-approved entries carry `approval_method = auto`. No review queue, at
  Ahmad's choice. The marker exists so an investigation can find them

Why the owner cannot transact: Ahmad's stated goal was that everything stays
tracked to a person. A shared account that posts money would defeat that.
Named admin logins give the same instant approval with the person recorded.
---

### 035 — One migration per phase
2026-10-01

A table is created in the migration of the phase that first uses it. Lets the
accountant's review change tax and chart tables before they exist. The
posted-row immutability trigger therefore moves to migration 002, with the
transactions table it protects.

---

### 036 — Roles revised: no approver role, shared owner login approves
2026-10-01

Supersedes decision 034 in part, at Ahmad's choice.

- Roles are owner, admin, staff. Only the owner and admins approve
- The winibexoffice owner login is shared by Ahmad and Maryam and can create,
  approve and reverse transactions. Its own entries post directly
- Maryam has a personal staff login for her own entries. Ahmad uses the owner
  login during the build, then a staff login
- Staff entries need the owner or an admin at any amount. The 10,000 PKR
  approver limit no longer applies

Risk raised and accepted: approvals from a shared login cannot always be tied
to one person, and Maryam can approve her own entry by switching login.
Mitigation: `possible_self_approval` is set silently when the owner login
approves an entry made by a user who shares it.

---

### 037 — Live from 1 July 2026, history entered later
2026-10-01

Supersedes decision 008's "opening balance plus transactions" and open item E.
Books go live on 2026-07-01 with an opening entry of real balances at
2026-06-30. Earlier entries are historical, excluded from live balances until a
merge check shows they reconcile with the opening entry, then the opening entry
is reversed. No row is ever edited to switch history in. `accounts` loses the
`opening_balance` column. Its `opening_date` becomes the earliest permitted
date, 2025-03-01.

---

### 038 — Server-side refresh tokens
2026-10-01

Stateless tokens cannot be logged out or revoked. Refresh tokens are stored
hashed, rotated on every use, and grouped in families so reuse of an old token
revokes the session.

---

### 039 — argon2id, bcryptjs as fallback
2026-10-01

argon2 is a native module and Hostinger gives no SSH to debug a failed build.
Proved with a throwaway deploy in step 0.1. If it fails, bcryptjs, decided
before login is built. With four users, changing later means four password
resets.

Superseded by decision 042.

---

### 040 — Schema additions from the Phase 0 review
2026-10-01

Raised by Claude Code before migration 001 and accepted:
`settings` gets real columns. `categories.main_head` gains `taxation` and
`balance_sheet`. `chart_of_accounts` gains `normal_balance`, `is_header` and
`is_active`. `users` gains `must_change_password` for the owner bootstrap.
`fbr_return_heads` seeds empty until the accountant supplies codes.

---

### 041 — The database is MariaDB 11.8, not MySQL 8
2026-10-01

Checked in phpMyAdmin at the start of step 0.1. Hostinger's managed database
reports `11.8.9-MariaDB-log`. Every document that said MySQL 8 was assuming.

Local development runs MariaDB 11.8 in Docker, the same major version.
Developing against MySQL and deploying to MariaDB would mean finding the differences
in production.

What actually differs, and what it costs us:

- MySQL's `utf8mb4_0900_ai_ci` does not exist. **Wrong, see decision 054.**
  It does exist on Hostinger's MariaDB 11.8.9, which provides the MySQL 8
  collations for compatibility and omits MariaDB's own uca1400 family. The default from MariaDB 11.6 is
  `utf8mb4_uca1400_ai_ci`, which is what we use
- `JSON` is an alias for LONGTEXT, stored as text. So `audit_log.before_json`,
  `audit_log.after_json`, `idempotency_keys.response_json` and
  `generated_documents.source_data_json` must be stringified on write and
  parsed on read. We only ever read them whole, so nothing is lost
- The `->` and `->>` JSON operators are not supported. We do not query inside
  those columns, so this costs nothing
- CHECK constraints and triggers behave the same. Both were tested against the
  real engine in step 0.1 before anything was built on them
- Global `sql_mode` and the server time zone cannot be set on Hostinger, so
  strict mode, UTC and READ-COMMITTED are set per connection when the pool
  opens one

Driver stays `mysql2`, from version 3.23.0, which added MariaDB type support
and runs its own tests against MariaDB.

Source: MariaDB documentation on character sets and collations, and on
incompatibilities with MySQL. Confidence: high, and the behaviour is asserted
by tests in `api/tests/database.test.js` rather than trusted.

---

### 042 — bcryptjs now, argon2id switchable later
2026-10-01

Supersedes decision 039.

argon2 is a native module that has to compile on the server at deploy time.
Hostinger's plan specification says nothing about whether that will work, and
finding out needed a test deploy that was blocking real progress.

Taken: bcryptjs at cost factor 12, which is pure JavaScript and cannot fail to
install anywhere. For four internal users behind a login this is a sound
choice, not a compromise.

argon2id stays available. `api/core/password.js` supports both, and
`verifyPassword` reads which method produced a stored hash from the hash
itself, so switching never locks anyone out. Switching is: install the `argon2`
package, change one line in `.env`. The tests for argon2 are already written
and skip themselves until the package is present.

Decided to switch on, or not, at the first real deploy at the end of Phase 0,
when there are no real passwords to reset either way.

Also settled here: a password over 72 bytes is refused rather than accepted,
because bcrypt silently ignores everything past that point.

---

### 043 — Node's own test runner, no test framework
2026-10-01

Tests use `node --test`, built into Node since version 20. Jest and Vitest were
not added.

Reason: one less dependency to maintain, nothing to break when Hostinger moves
Node version, and no configuration file. The test suite runs against the real
MariaDB container, never a mock, so the thing a framework usually buys us,
mocking, is deliberately unused.

ESLint 9 with flat config and no plugins is the only development dependency.
Two rules in it are about money rather than style: `Math.round` and
`parseFloat` are blocked, because money here is whole paisa and must never
become a decimal.

---

### 044 — supportBigNumbers on every database connection
2026-10-01

Found by a failing test in step 0.1, not by reading documentation.

JavaScript holds whole numbers exactly only up to 9,007,199,254,740,991. The
driver returned a BIGINT above that as a rounded number, changing the last four
digits with no error. Money is BIGINT paisa, so that behaviour is not
acceptable even though Winibex's real figures are around five orders of
magnitude below the limit.

Every connection sets `supportBigNumbers: true`. A value too large to hold
exactly then arrives as exact text instead of a rounded number. Normal amounts
still arrive as ordinary numbers.

The test that caught it stays, so removing the setting fails the build.

---

### 045 — Reserved-word columns renamed, and other schema shaping in migration 001
2026-10-01

Found while writing migration 001. `KEY` is reserved in MariaDB, so a column
named `key` works only if every query quotes it, and one missed quote is a
syntax error months later. Renamed before any data existed:
`settings.key` to `settings.setting_key`, `idempotency_keys.key` to
`idempotency_keys.idempotency_key`.

Also settled while turning the schema into real SQL:

- Timestamps are `DATETIME` holding UTC, not `TIMESTAMP`. TIMESTAMP breaks in
  2038 and silently shifts by session time zone; books are kept ten years and
  some dates are in the future, so neither is acceptable
- `accounts` gained a `coa_id` column. SCHEMA.md said a balance is the sum of
  posted journal lines on the account's ledger code, but no column linked an
  account to that code, so the balance could not have been computed
- A CHECK that an account is not its own parent was removed. MariaDB refuses a
  CHECK that mentions an AUTO_INCREMENT column, and the case cannot arise on
  insert anyway. It moves to the service layer
- Migration 001 uses `CREATE TABLE` without `IF NOT EXISTS`, so re-running it
  fails loudly. The runner, not the file, is what knows a migration is already
  applied

---

### 046 — Migration numbering: seed and bootstrap are their own files
2026-10-01

Reference data (currencies, chart of accounts, categories, settings,
sequences) is migration 002. Company bootstrap (the owner login, the company
profile, the company accounts) is migration 003, created from a template so
the two facts only Ahmad has, the owner email and password hash, are filled in
locally rather than committed. Phase 1's tables therefore become migration 004
and onwards. One migration per phase still holds; seeds are data, not a phase.

Taxes are deliberately not seeded. They wait for the accountant.

---

### 047 — The driver parses JSON columns; do not double-parse
2026-10-01

AGENTS.md, SCHEMA.md and decision 041 all say the `mysql2` driver returns a
JSON column as a string, so the code must parse it. That was true before
`mysql2` 3.23, which added MariaDB type support and now parses the value for
you. We pinned `^3.23.0` for exactly that support and inherited the change.

Four audit and idempotency tests failed on `JSON.parse` of an already-parsed
object. Fixed with one helper, `core/json.js`: `toJsonColumn` always
stringifies on write, `fromJsonColumn` parses only if handed a string. The
code no longer depends on which driver version is installed.

The three documents above are corrected to match.

---

### 048 — API shape: Express 5, token design, hand-written rate limiter
2026-10-01

Settled while building Phase 0's API.

- Express 5. Async route handlers forward a rejection to the error middleware
  on their own, so there is no wrapper around every handler
- Two-token auth. The access token is a short-lived JWT, held only in memory,
  not stored. The refresh token is a long random string; only its SHA-256 hash
  is stored, it rotates on every use, and reuse of a rotated token revokes the
  whole family. A wrong password and an unknown email return byte-identical
  responses, so the login cannot be used to discover which emails have accounts
- The login rate limiter is a small in-memory one in `core/rate-limit.js`, not
  a package. One Node process on Hostinger and four users do not need a shared
  store. It counts failed attempts only, so a normal run of successful logins
  never contributes to a lockout
- Malformed JSON and oversized bodies return 400 and 413, not 500, so the
  server log is not buried under client typos

Packages added, all noted here per the boundary rule: `express`, `helmet`,
`cors`, `cookie-parser`, `zod`, `jsonwebtoken`, `mysql2`.

---

### 049 — Flutter foundation: Riverpod 3, go_router, package versions
2026-10-01

The app scaffold. One theme file and one strings file were already decided
(026); this records what the build settled.

- The package versions that actually resolve together today: Riverpod
  (flutter_riverpod, riverpod_annotation) 3.x with riverpod_generator 4.x,
  go_router 18, dio 5, flutter_secure_storage 11, shared_preferences 2. Pinned
  by `flutter pub add`, never by hand
- `custom_lint` and `riverpod_lint` are left out for now. They pin an older
  analyzer than riverpod_generator wants, which blocks resolution. They add
  editor hints only, nothing the build needs, and can return when their
  versions line up
- Two breaking changes from the version jump, fixed in code: Riverpod 3 removed
  `AsyncValue.valueOrNull`, so use `.value`, which now returns null during
  loading and error alike; flutter_secure_storage 11 removed
  `encryptedSharedPreferences`, since Keystore-backed storage is the default
- The refresh token is stored in the Keystore on Android and not stored at all
  on web, where the httpOnly cookie carries it. This is why the API accepts the
  refresh token both in a cookie and in the body
- The API base URL is a `--dart-define`, so the same build points at localhost
  in development and the real domain in production

---

### 050 — Password bootstrap uses a temporary hash, forced to change
2026-10-01

The owner's first password is set by migration 003 as a bcrypt hash of a
temporary password, with `must_change_password = 1`. The real password is set
at first login and never touches a file. Ahmad, Maryam and Fazal are added by
the owner from the UI, so their passwords never pass through SQL at all.

---

### 051 — Step 1.1 corrections: journal number, migration 004, document repair
2026-10-02

Settled with Ahmad before the first line of Phase 1 code. Nothing here is a new
direction. It is the documents being made to agree with each other and with the
database that already exists.

**The owner login can transact.** Decision 036 stands and decision 034 stays
superseded. The role name remains `owner` in the `users` ENUM, because only one
account carries settings, users and roles. Confirmed by Ahmad on 2026-10-02
against a stale instruction that still quoted 034.

**Phase 1 is migration 004.** Decision 046 moved seed data to 002 and company
bootstrap to 003, so the Phase 1 tables shift to 004. Migrations 000 to 003 are
applied, and a number recorded in `schema_migrations` can never be reused.
SCHEMA.md's migration table and one line of the PROGRESS checklist still said
002 and are corrected here.

**`transactions` gains `journal_number`, allocated at posting.** Decision 015
requires gapless numbering but no column existed to hold the number. The
allocation point was the open part, and it is posting, not draft creation. A
rejected or abandoned draft holding a number would leave a permanent hole in
the series, which is the exact failure 015 exists to prevent. Drafts and pending
entries are excluded from every balance and report, so they are not yet part of
the book and do not need a book number. On screen a draft is identified by its
row id. The allocation still happens inside the same database transaction as the
posting, so a failed posting hands the number back.

**`accounts.coa_id` is documented.** Migration 001 built it `NOT NULL`,
`UNIQUE`, `BIGINT UNSIGNED`, with a foreign key to `chart_of_accounts`. Decision
045 recorded why it was added; SCHEMA.md's account table never listed it. One
ledger code per account, so a balance can never belong to two places at once.

**Integer types.** Migration 001 uses `BIGINT UNSIGNED` for every key. SCHEMA.md
said `BIGINT`. Migration 004 must match exactly or its foreign keys cannot be
created. Money columns stay signed.

**The opening entry was blocked by its own rule.** UI-GUIDE.md listed "an
opening or historical entry dated on or after 1 July 2026" as blocked, which
refuses the opening entry itself, since SCHEMA.md dates it exactly 2026-07-01.
Split into two rules: historical entries must be before 2026-07-01, and the
opening entry must be dated exactly 2026-07-01 and may exist only once.

**The driver is `mysql2`, pinned `^3.23.0`.** Confirmed from
`api/package.json`. Decisions 041, 047 and 048 and SCHEMA.md named it
`MariaDB2`, which is not a package that exists. `mysql2` is the correct driver
for a MariaDB server, and 3.23 is the version that added MariaDB type support,
which is the subject of decision 047.

**The MySQL and MariaDB sweep is repaired.** When decision 041 found the server
was MariaDB, the word MySQL was replaced globally across the documents. That
broke every sentence contrasting the two ("MariaDB, not MariaDB"), mislabelled
facts that belong to MySQL (`utf8mb4_0900_ai_ci` is MySQL's collation and does
not exist on MariaDB), and corrupted the driver's package name. Repaired in
DECISIONS 005, 041, 047 and 048, SCHEMA.md, OVERVIEW.md, DEPLOY.md and
PROGRESS.md. AGENTS.md was already correct and is unchanged.

**`riverpod_lint` is not installed.** FRONTEND.md's package table listed it as
though it were. Decision 049 left it out because it pins an older analyzer than
`riverpod_generator` needs. The table now says so.

Rules adopted to stop this recurring are in the Documentation rules section at
the end of this file.

---

### 052 — Phase 1 posting: account, withholding, rounding, and when a migration may be edited
2026-10-02

Settled while building migration 004 and the posting engine. Each item was
found by the database or a test refusing something that should have worked.

**`account_id` is nullable, with a CHECK both ways.** Three legitimate entries
move no company money: one a person paid personally (worked example 1b credits
2114 and touches no company account), the opening entry, which belongs to every
account at once, and a manual journal entry such as depreciation. The journal
lines carry the accounting in all three. `account_id` drives the ledger view and
the balance query, and does not apply. The CHECK requires an account exactly
when `paid_by_type = 'company'` and `entry_type` is `normal` or `historical`,
and forbids one otherwise.

**`transactions.withheld_total`, and the reconciliation rule splits in two.**
The old rule, `amount = gross + tax + charges` for money out, assumed every tax
is taken from Winibex. Tax Winibex withholds from a payee under s.153 or s.149
is held back rather than paid out: paying a vendor 100,000 with 4% withheld
sends 96,000 to the bank and credits 4,000 to 2132. The database would have
refused that entry. `withheld_total` is its own non-negative column, money out
only, and it is the figure the quarterly s.165 statement reports. The rule is
now `amount = gross + tax_total + charges_total - withheld_total` for money out
and `amount = gross - tax_total - charges_total` for money in.

**`entry_type` gains `journal`, `method` gains `card`.** UI-GUIDE requires a
manual Journal Entry screen for depreciation, FX revaluation and year-end
adjustments. Without a type of its own each would have to pretend to be a
normal entry on an arbitrary account. `card` was added because most foreign
payments leave on a card and s.236Y is specifically a tax on card payments, so
`online` was hiding the distinction the tax engine needs.

**Rounding is half away from zero.** 1.5 paisa becomes 2, -1.5 becomes -2.
Chosen over banker's rounding for two reasons: it is what a person doing the
sum by hand produces, so a system figure matches a hand-checked one, and it is
symmetric, so a reversal is exactly equal and opposite with no half paisa left
behind. Banker's rounding suits large statistical runs, which this is not.

**An applied migration may be edited only while every database holding it can
be rebuilt.** Migration 004 was edited twice after being applied locally,
because nothing is deployed and there is no real data. The rule that an applied
migration is never edited exists to protect a database that cannot be rebuilt.
From the first Hostinger deploy onwards, a correction is a new migration,
without exception.

**A reversal is flipped, never recalculated.** `reverseJournalLines` swaps debit
and credit on the stored lines. Recomputing from the form would use today's
exchange rate and today's tax rules, which may both have changed since posting,
and the pair would not net to zero.

**A reversing entry carries no tax or charge breakdown.** Found by a failing
test. For money in, `amount = gross - tax - charges`, so repeating the
original's split does not reconcile. The reversal carries
`gross_amount = amount` with no tax or charge lines, and its journal lines
mirror the original. Consequence for Phase 6: a tax report must exclude tax
lines belonging to entries whose status is `reversed`, or it will overstate what
is reported to FBR.

---

### 053 — Phase 1 build: transfers, validation tiers, and what the database refused
2026-10-02

Settled while building steps 1.5 to 1.12. As with 052, most of these were
found by something refusing to work rather than by being planned.

**A reversed entry still counts towards a balance.** The balance query filtered
`status = 'posted'`, so reversing an entry dropped its lines out of the
balance and the correction counted twice: once by removing the original's
effect, once by adding the reversal's. Both rows stay in the book and cancel
each other, decision 012, so both must be counted. Caught by a test asserting
that a reversal returns a balance to where it was, which no constraint could
have caught because the data was valid and the trial balance still summed to
zero. SCHEMA.md's lifecycle section is corrected.

**Transfers post through 1118 Funds in transit, internal.** SCHEMA.md says a
transfer is two rows sharing `transfer_group_id`; AGENTS.md says every
money-moving row writes balanced journal lines. Both legs posting a full entry
would record the movement twice. Each leg therefore passes through a transit
account: out of the source debits 1118 and credits the source, into the
destination debits the destination and credits 1118. 1118 returns to zero the
moment both land, so a half-finished transfer is visible rather than invisible.
Seeded in migration 002 as a system control account that nothing can post to by
hand, with two categories, Transfer in and Transfer out, which only the
transfer engine selects. A bank fee is a charge on the out leg, which is the
UI-GUIDE exception for legs that do not match.

**Manual journal lines are written once, with the draft, and never rewritten.**
The opening entry and any `journal` entry have no form to derive lines from, so
they are supplied and stored at draft time. The posting path originally deleted
and reinserted them, and the delete trigger from migration 004 refused. It now
validates that they balance and leaves them alone. The rule being enforced in
two places, as decision 012 requires, is what caught the service doing
something it should never have done.

**The merge check compares positions only.** Assets, liabilities and equity.
An opening entry carries what the company held and owed at 30 June, not what it
earned getting there: last year's income and expense are absorbed into equity,
so comparing an income account would report a permanent difference and the
merge could never happen. 3400 is excluded as well, being the balancing figure
with no history behind it.

**Opening balances are supplied on each account's normal side.** A bank holding
500,000 and a director loan of 300,000 are both given as positive figures. The
service reads `normal_balance` to decide the posting side, so nobody has to
think in debits and credits to open the books, and the balancing figure to 3400
is never supplied by a person because it is a consequence rather than a fact.

**Cross-feature calls go through `createDraftWithin` and `approveWithin`.**
Reimbursements, transfers and the opening entry all need to create and post an
entry inside their own database transaction, so a failure in their second half
leaves no orphan payment. Those two exports take a connection instead of
opening one. No module reaches into another's repository, which is the
interface decision 016 asks for.

**The cheque register posts nothing.** It records what was written and whether
it cleared; the money is an ordinary transaction with `method = cheque` linked
to it. Two sets of books would eventually disagree. Whether an uncleared cheque
should sit in 1114 until it clears is a question for the accountant, noted in
CHART-OF-ACCOUNTS.md.

**Vendors are never deleted, only deactivated,** and only the owner or an admin
may add or change one, because `atl_status` silently decides a withholding
rate. A vendor with unknown status gets the non-filer rate and a warning naming
them: guessing the lower rate leaves Winibex owing FBR the difference.

**Validation runs at create and at update, not at posting.** Blocked throws,
warned returns 409 with the matched records named and goes through when the
same request returns with `acknowledged_warnings`, and the acknowledgement is
written to `entry_flags` with who confirmed it. Editing a draft replaces its
warnings and flags, because the old ones described figures that no longer
exist.

**The property test carries a seed.** 150 random operations, with the seed
printed on every run and settable through `PROPERTY_SEED`, so a failure is
reproducible rather than a story about something that happened once. It also
asserts that a refused operation leaves the transaction count, the line count
and the debit total unchanged, which is the only check in the suite that would
catch a half-finished write.

---

### 054 — The first deploy, and the collation that was not there
2026-10-03

A throwaway deploy of `scripts/probe-deploy.js` to api-accounting.winibex.com,
before anything real was uploaded and before a single table was created on
production. It answered five questions and found one problem that would have
stopped migration 001 on its first statement.

**Every table is `utf8mb4_unicode_ci`, not `utf8mb4_uca1400_ai_ci`.** Decision
041 chose uca1400 as the MariaDB 11.6+ default. Hostinger's server reports
`11.8.9-MariaDB-log` and does not have it: 78 utf8mb4 collations, none of them
uca1400, and the server's own default is `utf8mb4_unicode_ci`. The local Docker
`mariadb:11.8` does have it, which is the same develop-here deploy-there trap
decision 041 was written to prevent, arriving from a different direction.

`utf8mb4_unicode_ci` was chosen over `utf8mb4_0900_ai_ci`, which is also
present, because 0900 is a MySQL collation that this MariaDB build provides for
compatibility and another build might not. `unicode_ci` exists everywhere and
is already this server's default, so a table created without an explicit
collation gets the same answer. Sorting differs from uca1400 only in edge cases
of accented and non-Latin text, which does not affect account names, vendor
names or descriptions.

Changed in migrations 001 and 004 and in the tests that assert it, before any
table existed on production. After the first real deploy this would have been a
rebuild of every table.

**Correction to decision 041.** It says MySQL's `utf8mb4_0900_ai_ci` does not
exist on MariaDB. On this server it does. The claim is corrected there and in
SCHEMA.md and DEPLOY.md.

**bcryptjs stays. Open item L is closed.** Hashing takes 295 ms on the real
server and verifying 282 ms, both well under the second that would make a login
feel broken. argon2id would be stronger, but it is a native module, and
decision 042 records that a module failing to compile fails the whole Hostinger
deploy with no readable log. There is no reason to take that risk for 295 ms.

**Confirmed on the real server:** Node 24.20.0, TZ UTC, NODE_ENV production.
MariaDB 11.8.9, the same major version as local. All three session statements
accepted, so strict mode, UTC and READ-COMMITTED apply. A BIGINT past
JavaScript's safe integer limit survives the round trip exactly, which is the
one that silently corrupts money if it fails. Decision 044. UPLOAD_DIR writable
at `/home/u871859756/winibex-uploads` and outside the web root.

**`max_connections` is 2000, not 75.** DEPLOY.md recorded 75 per database user.
The server reports 2000. The pool limit stays conservative regardless, since
the figure is shared and a Node app holding connections open helps nobody.

**`DB_TEST_NAME` is deliberately absent on production.** It names the database
the test suite drops and rebuilds. Set to anything real there, running the
tests would destroy it. Absent beats blank.

---

### 055 — Phase 1 closed: receipts, ledger UI, dashboard, flags, and the live deploy
2026-10-03

Covers everything from the tax engine onward. Phase 1 is built, tested and
deployed. 346 API tests and 62 Flutter tests pass.

**Receipt uploads use multer, storing files outside the web root.** Chosen over
busboy (more code to get wrong) and base64-in-JSON (33% larger, whole file in
memory, and the 1 MB JSON cap would have to rise). Files are written with a
random name, never the uploaded one, so a crafted name cannot choose where a
file lands. The database stores the path relative to UPLOAD_DIR, and reading a
file refuses any path that climbs out of that folder. Hashed with SHA-256 so a
later copy can be proved identical. Kept ten financial years from the entry
date, Companies Act 2017 s.220.

**A payment above receipt_required_above is blocked from posting without a
receipt, not merely warned.** Ahmad's call. The threshold is a setting. The
rule is checked at posting, not at draft, because the photo is usually taken
after the form is filled in. It exempts money in, transfers between the
company's own accounts, the opening entry, manual journals, and reimbursements:
none of those is a purchase and several never have a receipt. A receipt may be
attached after posting, because late evidence beats none.

**The app uses file_picker for attachments.** Chosen over image_picker because
the API accepts PDFs and a bank advice often arrives as one. Note: file_picker
changed its API shape in three consecutive majors (11, 12, 13). Pinned to
^13.1.0, and 13's pickFile returns one PlatformFile with bytes read on demand.
Most of what is written online describes version 11; read the changelog, not a
tutorial.

**The journal preview comes from the server, from the same buildJournalLines
the real posting uses.** The app shows the double entry before the person
commits but never computes it, per AGENTS.md. A preview built by a second code
path would be a second opinion, and the one on screen would be the one nobody
checked. A test asserts the preview and the posted entry produce identical
lines.

**The ledger searches on the server.** The app holds one page, so searching
what it holds would miss everything else. An unsubmitted draft is private to
whoever created it; everything from pending onward is visible to all, because a
ledger that hides posted rows from some people is two different books.

**Nobody approves their own entry under the same login,** and the approval inbox
says so on the row rather than letting someone press approve and get a 403.
Rejecting always carries a reason, which the person who entered it sees.

**The dashboard and flags figures are all the server's.** Nothing is added up in
the app, and after any write the screen asks again rather than adjusting a
number locally.

**Flutter reads the API base URL from a build-time define.** The source keeps a
localhost default; production is passed at build with
`--dart-define=API_BASE_URL=...`, so the same code serves both and nothing in
the repository names the production host.

---

## Open, not yet decided

| # | Question | Blocks |
| --- | --- | --- |
| A | Invoice numbering: continue 5026 or restart with a year prefix | Phase 3 |
| B | Email invoices from the system or download and send manually | Phase 3 |
| C | Does petty cash below a threshold skip approval | Phase 1 |
| D | Can staff see the company balance, or only their own submissions | Phase 0 |
| E | ~~Import timing~~ Answered by decision 037 | |
| F | Two-factor login, or password only | Phase 0 |
| G | How long before a pending submission is auto-rejected, if ever | Phase 1 |
| H | Should staff be able to post directly, or always through draft and approval | Phase 1 |
| I | Table package: free grid or Syncfusion community licence. Needs a spike | Phase 1 |
| J | Accountant review of TAXES.md and CHART-OF-ACCOUNTS.md | Phase 0 |
| K | ~~PRA registration~~ Answered: not registered. Whether it should be is for the accountant | Phase 1 |
| L | Switch to argon2id at first deploy, or stay on bcryptjs. See decision 042 | Phase 0 close. Still open: decided at the first real Hostinger deploy |
| M | Android emulator reaches the local API at 10.0.2.2, not localhost. Note for Phase 7 | Phase 7 |

---

## Documentation rules

Added 2026-10-02 after step 1.1 found eight places where the documents
disagreed with each other or with the database. The cause was the same every
time: one fact written in several files, and only one copy corrected.

1. **One home per fact.** Database engine facts live in decision 041. Permission
   rules live in SCHEMA.md under Permissions. Migration numbers live in
   SCHEMA.md's migration table. Package versions live in `package.json` and
   `pubspec.yaml`, never retyped into prose. Other documents point at the home,
   they do not restate it.
2. **Never find-and-replace across files.** One file at a time, reading every
   hit. The sweep that caused this damage would have been harmless done that
   way.
3. **Anything in backticks is code, not prose.** `mysql2`,
   `utf8mb4_0900_ai_ci`, `coa_id`. A rename sweep never touches it.
4. **Decisions are appended, never rewritten.** Add a new entry that supersedes
   the old one and says so. Editing a decision in place is how a document ends
   up disagreeing with the code that was written from it.
5. **A document that describes a table is checked against the migration that
   built it,** not against an earlier draft of the document.
6. **Instructions given in chat are not a source of truth.** The files are. When
   the two disagree, say so and ask, rather than following either one silently.
   Two conflicts in step 1.1 came from chat instructions quoting superseded
   decisions.
7. **A guard script, `api/scripts/check-docs.js`,** greps the documents for
   known contradictions and runs with the test suite. Not yet written; next
   step.
