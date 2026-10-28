# Overview

A complete picture of what is being built and why, in one read. Details live
in the other docs, linked throughout.

---

## What

An internal double-entry accounting system for Winibex PVT LTD, replacing the
spreadsheet the company has used since March 2025. It records every rupee in
and out, produces proper financial statements, handles multi-currency income
with Pakistani tax, and generates the documents the business sends to clients.

Web for daily use on desktop, Android for submitting expenses and approving
from a phone. One Flutter codebase for both.

## Why

The spreadsheet has reached its limits, and the limits are structural:

- The balance column is typed by hand, so one wrong row corrupts every row
  after it
- Five different accounts, including two employees' personal accounts, share
  one running balance that matches no bank statement
- Categories stopped being filled around mid 2025, so a year of spending
  cannot be reported
- USD receipts carry no exchange rate
- Investor money is shown as an opening balance, hiding that it is a debt
- Upwork income is recorded net, after the platform fee and the ID owner's
  share, so real revenue and real costs are both invisible
- No document generation, no approvals, no audit trail

The company also paused Odoo because of the monthly cost, so this system
becomes the book of record.

## The company

| | |
| --- | --- |
| Legal entity | Winibex PVT LTD, registered with SECP as a private limited company |
| Location | Lahore, Punjab |
| Registrations | SECP, PSEB active, FBR and on the Active Taxpayers List. Not registered with PRA. An AOP registered by mistake in June 2025 is unused and not part of these books |
| Financial year | 1 July to 30 June |
| Size | Paid-up capital up to PKR 1 million. Small-sized entity, and per SECP guidance exempt from statutory audit, though annual statements are still required |
| Business | Web and app development, digital marketing, design, AI tools |
| Clients | Local Pakistani clients and foreign clients in UAE, Qatar, USA and UK |
| Income channels | Direct bank transfers, and Upwork accounts owned by individuals who keep a share of profit |
| Funding | Director loan from Hammad Malik, plus operating income |
| People | Ahmad Ali Khan, Maryam Nawaz (bookkeeping), Fazal. Adeen exited end of August 2026 |

## Who uses it

| Person | Role in the system |
| --- | --- |
| Winibex office account | Owner, shared by the directors. Creates, approves and reverses entries, and is the only login that sees Settings. Decisions 036 and 063 |
| Admins | Named logins the owner adds under Settings, People |
| Maryam | Staff login for her own entries. Also approves through the shared owner login |
| Ahmad | Uses the owner login during the build, then a staff login |
| Fazal | Staff. Receives some client money into his personal account |
| The company accountant | Reads reports, reviews the chart of accounts and taxes, and can send changes to both as spreadsheet files that the owner imports |

## What it does

### Money
Accounts with balances calculated from posted entries, never stored. Company
accounts plus pass-through accounts for the personal accounts where client
money lands first. Transfers as two linked legs. Paying people back, the
petty cash top-up and the opening balances are done from the Accounts screen.

### Entry
A guided form: direction, currency, amount, who paid, rate or PKR figure, tax
and charge lines, category, client, receipt, then a review showing the journal
entry before submitting. Example: a $20 Claude subscription paid on Ahmad's
card asks the currency, records that Ahmad paid personally so the company owes
him, takes the rate, adds the card tax and forex fee lines, and posts a
balanced entry. A draft can be edited, a submitted entry taken back by its
sender, and a rejected one fixed and sent again. See `docs/UI-GUIDE.md`.

### Control
- Draft, pending, posted, reversed. Posted entries cannot be edited by anyone,
  only reversed with a reason
- Staff entries are approved by the owner login or an admin. Owner and
  admins' own entries post directly
- Validation in three tiers: blocked, warned, flagged. About 25 rules
- A receipt is required before posting any payment at or above a threshold
  (5,000 PKR). Smaller payments without one are flagged for review. Money in,
  transfers and reimbursements need none. Decisions 055 and 057
- Gapless numbering, a full audit log, and an idempotency key on every
  money-creating request

### Multi-currency and tax
PKR books. Foreign transactions store the original amount, the rate, and the
PKR figure. An Odoo-style tax engine: taxes are configured records with
authority, law section, rate and effective dates, suggested per situation and
editable, with ATL and non-ATL rates chosen by the status of the party the tax
is about. Each transaction snapshots the rate and status used. Covers Section
154A at 0.25% on IT exports, Section 153 withholding (4% IT, 7% specified,
15% independent developers, for filers), Section 236Y at 0.5% on foreign card
payments, FED on bank charges, salary withholding. Produces the quarterly
Section 165 withholding statement. Taxes, their rates and when each is
suggested are kept by the owner under Settings, Taxes, or imported from a
spreadsheet file. See `docs/TAXES.md`.

### Settings
A home of cards for the owner: People, Taxes, Ledger codes, and Import and
export. Ledger codes and headings can be added, renamed, moved and switched
off, never deleted. Ledger codes and taxes go in and out as CSV files that
open in Excel; an import shows what every row will change before anything is
saved. Decisions 063 and 067 to 069.

### Clients and earnings
Clients with status, projects as fixed, retainer or hourly, rebillable versus
absorbed spend, per-client profit. Earning accounts for Upwork IDs with a
partner split percentage, recording gross, platform fee, partner share and net.

### Documents
Quotation, invoice, payment receipt, payment voucher, salary slip, client
statement. Generated from data, with company details, PDF output and version
history.

### Payroll
Employees with salary history and exit dates, monthly runs approved once, tax
deduction lines. Visibility controlled by a setting that is permissive now and
can be restricted later.

### Recurring costs
Subscriptions and fixed costs that create pending entries on their due date
for confirmation.

### Reports
The basic dashboard (cash per account, money in/out, pending and flag counts)
is built. The full reporting suite (Profit and Loss, Balance Sheet, Cash Flow,
Trial Balance, General Ledger, receivables aging, tax summary, runway, client
profit, bank reconciliation, fixed assets, FX revaluation) is Phase 6.
Export to PDF, CSV and Excel.

### AI access
An MCP server so Claude and similar tools can answer questions from the live
books. Read only at first.

## Accounting design

- Double-entry underneath every screen. Users see a simple form, the system
  writes the journal
- Chart of accounts structured for AFRS for SSEs and mapped to FBR return
  heads, since Pakistan has no mandated chart. See `docs/CHART-OF-ACCOUNTS.md`
- Rebillable spend is an asset until invoiced, so it never distorts profit
- Investor money is a liability
- Personal payments create a payable to that person
- Export and local revenue in separate accounts because they are taxed
  differently

## Technical design

| Layer | Technology | Responsibility |
| --- | --- | --- |
| App | Flutter, Dart, Riverpod 3 with code generation | Everything users see. Never calculates a balance |
| API | Node 24, Express 5 | Every business rule, the posting engine, CSV import and export, PDFs, auth, cron |
| Database | MariaDB 11.8 | Storage, constraints, transactions, immutability trigger |
| MCP | Node | Reuses the API's service layer directly |
| Hosting | Hostinger Business | Node app, managed MariaDB, static web hosting |

Organised by feature module on both sides, so a new feature is a new folder.
Money is always integer minor units. One theme file and one strings file in
the app. See `AGENTS.md`, `docs/API.md`, `docs/FRONTEND.md`.

The database is MariaDB rather than MySQL, confirmed against the live server.
It matters in a small number of places, listed in `AGENTS.md` and decision 041.
Local development runs the same version in Docker.

## Design

Professional accounting terminology with tooltips explaining every term in the
company's own words. Light and dark themes. Visual direction drawn from ledger
paper: red ink for negatives, ruled tables. Onest typeface, Graphite and
petrol palette. See `docs/UI-GUIDE.md`.

## Phases

| Phase | Scope | Status |
| --- | --- | --- |
| 0 | Foundation: schema, auth, roles, audit, theme, strings | Complete |
| 1 | Money in and out, taxes, approvals, validation, reimbursements | Complete, deployed, every feature on screen |
| 2 | Clients, projects, earning accounts | Next, after Phase 1 is used with real entries |
| 3 | Quotations, invoices, receipts, documents | |
| 4 | Payroll | |
| 5 | Recurring costs | |
| 6 | Dashboard and reports (full suite; basic dashboard already built in Phase 1) | |
| 7 | Android app | |
| 8 | History before 1 July 2026, entered and merged | |
| 9 | MCP server | |

## Status

Phase 1 is complete and live, and every Phase 1 feature has a screen. Settings
has a home of cards, ledger codes with headings, and import and export of
ledger codes and taxes. 463 API tests (460 pass, 3 argon2 skips) and 172
Flutter widget tests pass. The API runs at api-accounting.winibex.com and the
web app at accounting.winibex.com. CI/CD is in place: the API auto-deploys on
push via Hostinger Git integration, and the web app deploys via GitHub Actions
building Flutter web and uploading over FTP. Production holds empty books.
Before real entries: the real 30 June 2026 balances and the accountant's tax
rates, both entered from the app. See `docs/PROGRESS.md`.

## Known risks

| Risk | Mitigation |
| --- | --- |
| Tax rates for tax year 2027 conflicted across sources | Rates are data, accountant sets them, bank figures win |
| Flutter web cannot use the browser's Ctrl+F | Server search, plus find on this screen built into the app (decision 068) |
| A spreadsheet import changes many records at once | A preview of every row before anything is saved, all or nothing on confirm, nothing ever deleted (decision 069) |
| Hostinger shared constraints: no SSH npm, no migration CLI, no headless Chrome | Documented in `docs/DEPLOY.md` and designed around |
| MariaDB differs from MySQL in JSON handling and collation | Differences listed in decision 041 and asserted by tests against the real engine |
| JavaScript rounds integers past 2^53 | `supportBigNumbers` on every connection, guarded by a test. Decision 044 |
| The shared owner login approves, so an approval cannot always be tied to one person | Silent marker when it approves an entry made by someone who shares it. Accepted by Ahmad |
| Books start mid-history | Opening entry on 1 July 2026, history entered later and merged only when it reconciles |
| Spreadsheet history is incomplete and miscategorised | Import has a verification step against sheet totals and bank balances |
| A team of four cannot fully segregate duties | Nobody approves their own entry except admin, which is flagged |
| Books must be kept ten years | No purge on accounting tables, exports to PDF, CSV and Excel |
