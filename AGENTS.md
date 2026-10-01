# Winibex Accounting

Internal accounting system for Winibex Global. Replaces a spreadsheet ledger.
Four internal users. Real company books, so correctness beats speed of delivery.

## Stack

- `app/` Flutter (Dart) — web and Android from one codebase
- `api/` Node + Express + MariaDB — all business logic
- `mcp/` Node — MCP server exposing read-only tools over the same database
- Deployed on Hostinger Business (Node 24 runtime + managed MariaDB 11.8)

## Commands

```bash
# api
cd api && npm install && npm run dev        # local, port 3000
cd api && npm run test
cd api && npm run lint

# database, from the repo root
docker compose up -d                        # local MariaDB 11.8
docker compose down

# app
cd app && flutter pub get
cd app && flutter run -d chrome
cd app && flutter build web --wasm
cd app && flutter analyze
cd app && flutter test
```

Migrations are plain SQL files in `api/migrations/`, run in order.
Hostinger has no migration CLI, so they are applied through phpMyAdmin.

## The database is MariaDB, not MySQL

Confirmed 2026-10-01: Hostinger reports `11.8.9-MariaDB-log`. See decision 041.
Local development runs the same major version in Docker. What this changes:

- `JSON` is an alias for LONGTEXT. Stringify on write, parse on read. Never
  query inside a JSON column, and never use the `->` or `->>` operators
- Collation is `utf8mb4_uca1400_ai_ci`. MySQL's `utf8mb4_0900_ai_ci` does not
  exist here
- Global `sql_mode` and server time zone cannot be set on Hostinger. Every
  connection sets strict mode, `time_zone = '+00:00'` and READ-COMMITTED
  itself, in `api/core/db.js`
- Every connection sets `supportBigNumbers`. Without it the driver rounds a
  BIGINT past JavaScript's safe integer limit with no error, and money is
  BIGINT paisa. Decision 044

## Hard rules

- The Flutter app NEVER calculates a balance, total, or profit. It displays
  what the API returns. Anything computed on a client can be tampered with.
- Every money-moving transaction writes balanced journal lines. Debits must
  equal credits or the whole insert rolls back.
- Nothing is ever hard deleted from `transactions`, `invoices`, `payroll_*`.
  Accounting records must stay auditable.
- A `posted` transaction is immutable. No code path updates its money fields,
  not even an admin one. Corrections are a reversing entry plus a new entry.
  Enforced in the service layer AND by a database trigger.
- Journal and invoice numbers come from the `sequences` table, allocated inside
  the same DB transaction as the insert. Never from `MAX(id) + 1`.
- All money is stored in minor units as BIGINT (paisa), never FLOAT.
- Base currency is PKR. Foreign amounts store the original amount, the rate,
  and the PKR figure. User enters rate or PKR, the other is computed. A bank
  figure wins over a manual rate.
- Tax rates are rows in the `taxes` table with effective dates. Never a
  constant in code. Each transaction snapshots the rate it used.
- Every money-creating request carries an `Idempotency-Key`.
- Every write goes through a database transaction.
- Every table that holds money has `created_by` and an `audit_log` entry.

## Permissions

Roles: `owner` (the shared winibexoffice account), `admin`, `staff`. There is
no separate approver role. Full rules in `docs/SCHEMA.md`, Permissions.
Non-negotiable: nobody approves their own entry under the same login. Owner
and auto-approve admins post their own entries directly, recorded as
`approval_method = auto`. When the owner login approves an entry made by
someone who shares it, set `possible_self_approval`.

Books go live on 2026-07-01 with an opening entry. Entries dated earlier are
historical and excluded from live balances until history is merged. See
`docs/SCHEMA.md`, Opening entry and history.

Migrations are one per phase. Do not create a table before the phase that
uses it.

Payroll visibility is controlled by the `payroll_visible_to_all` setting, not
hardcoded. It currently defaults to true. Every payroll endpoint must check it
even though it is currently permissive. Do not skip the check because it passes.

## Architecture

Organised by feature, not by technical layer, so adding a module means adding a
folder rather than editing ten shared files.

```
api/modules/<feature>/   routes.js  service.js  repository.js  schema.js
api/core/                db, auth, audit, validation, errors, password
app/lib/features/<f>/    data/  domain/  presentation/
app/lib/core/            theme, glossary, http, widgets
```

Features never import from each other directly. Cross-feature needs go through
a service interface documented in `docs/API.md`. Shared code lives in `core/`.

## Code style

- API: async/await only. Validation with zod at the route boundary. Business
  logic in `service.js`, SQL in `repository.js`, nothing in route handlers.
- Flutter: Riverpod 3 with code generation only (`@riverpod`, AsyncNotifier).
  No StateNotifier, ChangeNotifier or StateProvider. Full rules and examples
  in `docs/FRONTEND.md`. No business logic in widgets.
- Every colour, size, spacing, radius and font comes from
  `app/lib/core/theme/app_theme.dart`. Every user-facing string comes from
  `app/lib/l10n/app_en.arb`. A literal of either in feature code fails review.
- SQL: snake_case, plural table names. No column named with a reserved word.
- Dates stored UTC, displayed Asia/Karachi.

## Testing

- `node --test`, Node's own runner. No Jest, no Vitest. Decision 043
- Tests run against the real MariaDB container, never a mock, because the
  guarantees being tested live in the database
- ESLint 9 flat config, no plugins. `Math.round` and `parseFloat` are blocked
  rules, because money is whole paisa and must never become a decimal
- Full rules in `docs/TESTING.md`

## UI rules

See `docs/UI-GUIDE.md`. Non-negotiable points:

- Official accounting terminology. Debit, Credit, Journal Entry, not
  simplified substitutes. Tooltips carry the explanation.
- Every accounting term has a tooltip, sourced from `app/lib/core/glossary/`.
  One definition per term, never two.
- Light and dark themes, both designed. Colour tokens in one file.
- Validation is layered: blocked, warned, flagged. A warning must name the
  record it matched against.

## Boundaries

- Do not add a package without noting it in `docs/DECISIONS.md`.
- Do not change the schema without updating `docs/SCHEMA.md` in the same commit.
- Do not introduce MongoDB, an ORM, or a state management library other than
  Riverpod. These were decided, see `docs/DECISIONS.md`.
- Do not generate PDFs with headless Chrome. It will not run on shared hosting.
- Do not write MySQL-only SQL. The server is MariaDB.

## Where to look

- `docs/OVERVIEW.md` — the whole project in one read
- `docs/SCHEMA.md` — tables, fields, relationships, posting rules
- `docs/CHART-OF-ACCOUNTS.md` — account codes and worked journal postings
- `docs/TAXES.md` — Pakistan tax types, rates pending accountant review
- `docs/FRONTEND.md` — Flutter structure and Riverpod conventions
- `docs/UI-GUIDE.md` — terminology, validation tiers, receipt rules
- `docs/TESTING.md` — what must pass before merge
- `docs/PROGRESS.md` — what is done, what is next. Read this first each session
- `docs/DECISIONS.md` — why things are the way they are
- `docs/API.md` — endpoint contracts
- `docs/DEPLOY.md` — Hostinger setup

## Session discipline

At the end of any work session, update `docs/PROGRESS.md`: move finished items,
note where work stopped, and record anything that surprised you.
