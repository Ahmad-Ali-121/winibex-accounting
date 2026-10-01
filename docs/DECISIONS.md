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

### 005 — MySQL, not MongoDB
2026-10-01

Double-entry accounting needs transactions, joins and referential integrity.
MySQL is also what Hostinger provides as managed storage. MERN was considered
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
Developing against MySQL and deploying to MariaDB means finding the differences
in production.

What actually differs, and what it costs us:

- `utf8mb4_0900_ai_ci` does not exist. The default from MariaDB 11.6 is
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
| L | Switch to argon2id at first deploy, or stay on bcryptjs. See decision 042 | Phase 0 close |
