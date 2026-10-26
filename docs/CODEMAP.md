# Code map

What every file does, in plain words. Written for someone who knows Flutter
but is new to Node. Read this when you come back to a file and cannot remember
why it exists.

Kept current as the project grows. If a file is not here, it was added after
this was last updated.

Last updated: 2026-10-26 (Phase 1 defect fixes).

---

## How the three parts fit

- **`app/`** is the Flutter app. Everything people see. It never does maths on
  money. It asks the API and shows the answer.
- **`api/`** is the server, written in Node. Every rule about money lives here.
  Nothing else is allowed to touch the database.
- **`mcp/`** is empty until Phase 9. It will let AI tools read the books.

The app talks to the API over HTTP. The API talks to the database. The app
never talks to the database directly.

---

## A Node vocabulary, once

If you know Flutter, you already know the ideas. Only the words differ.

| Node word | Flutter equivalent | What it is |
| --- | --- | --- |
| `package.json` | `pubspec.yaml` | lists packages and shortcut commands |
| `npm install` | `flutter pub get` | downloads the packages |
| `node_modules/` | `.dart_tool/` | where downloaded packages sit |
| a "module" | a Dart file you `import` | one `.js` file |
| `import { x } from './y.js'` | `import 'y.dart'` | pull in code from another file |
| `export function x` | a public function | make it usable from other files |
| `async` / `await` | identical in Dart | wait for something slow |
| middleware | a wrapper around a request | code that runs before a route handler |
| Express | (no exact match) | the library that turns Node into a web server |

A "route" is one URL the server answers, like `POST /auth/login`. A "handler"
is the function that answers it.

---

## The API, folder by folder

### `api/` root

- **`server.js`**: the starting point. Checks the settings are present,
  connects to the database, starts listening. If something is wrong it stops
  immediately with a clear message, rather than failing confusingly later.
- **`app.js`**: assembles the server: security headers, JSON parsing, then
  attaches every module's routes. Kept separate from `server.js` so tests can
  build the app without actually opening a network port.
- **`package.json`**: the pubspec of the API. Dependencies ship to the
  server; devDependencies are local tools. `scripts` are `npm run <name>`
  shortcuts.
- **`.env`**: your secrets and settings (database password, token secrets).
  Never committed. You made it by copying `.env.example`.
- **`.env.example`**: the blank template of `.env`, safe to commit.
- **`eslint.config.mjs`**: the linter, like `analysis_options.yaml`. It also
  blocks `Math.round` and `parseFloat`, because money is whole paisa and must
  never become a decimal.
- **`.nvmrc`**: records that this project uses Node 24.

### `api/core/`: shared code every feature uses

- **`dates.js`**: the business date. `businessToday()` is today in
  Pakistan, not in UTC, so an entry made just after midnight is not refused as
  dated in the future. Also `monthStart` and `nextMonthStart` for the
  dashboard's month. Decision 057.
- **`config.js`**: reads `.env` once and refuses to start if something
  required is missing. One place that knows every setting.
- **`db.js`**: the database connection pool. Also holds `withTransaction`,
  which runs several database changes as one unit: all succeed or all are
  undone. The posting engine leans on this heavily.
- **`password.js`**: turns a password into a scrambled string, and checks one
  later. Reads which scrambler was used from the stored value itself, so the
  method can change without locking anyone out.
- **`errors.js`**: one shape for every error the API returns:
  `{ error: { code, message, field, details } }`. `code` is stable for the app
  to switch on; `message` is safe to show a person. Also turns the database's
  "duplicate value" error into a clear 409 `ALREADY_EXISTS` instead of a 500,
  for example a cheque number already used on that account.
- **`tokens.js`**: makes and checks the two kinds of login key (see Auth
  below).
- **`auth.js`**: the gatekeepers: "is this request signed in" and "does this
  role have permission". Used by routes that need protecting.
- **`rate-limit.js`**: counts failed logins and blocks after too many, to stop
  password guessing. Counts failures only, so normal use never triggers it.
- **`audit.js`**: writes a record of every change to money, for the ten-year
  audit trail. The record is written in the same unit as the change, so it can
  never describe something that was undone.
- **`sequences.js`**: hands out invoice and journal numbers with no gaps. If
  the work fails, the number is handed back. Auditors ask about gaps first.
- **`idempotency.js`**: stops a double tap or a dropped connection from
  recording the same expense twice.
- **`json.js`**: a small helper for reading and writing the database's JSON
  columns, which behave slightly differently on MariaDB.
- **`sql-split.js`**: splits a migration file into separate statements so they
  can be run one at a time. Needed because a database trigger is full of
  semicolons and a naive split would cut it in half.
- **`money.js`**: integer arithmetic for money: add, subtract, negate, compare,
  format. No float ever touches a money value. Used by the posting engine and
  the reconciliation checks.
- **`validate.js`**: shared validation helpers used across modules, built on
  zod. Validates money objects, dates, pagination parameters.

### `api/modules/`: one folder per feature

Each feature folder holds up to four files, always the same shape:

- **`routes.js`**: the URLs this feature answers, and the validation of what
  comes in. No business logic here.
- **`service.js`**: the actual rules. The thinking part.
- **`repository.js`**: the SQL. The only file that talks to the database for
  this feature.
- **`schema.js`**: the shape of what a request may contain (added where
  needed).

Current modules:

- **`health/`**: one URL, `GET /health`, that says whether the server and
  database are up. No login needed. Used for monitoring.
- **`auth/`**: login, logout, refreshing the session, "who am I", and
  change password. The whole login system, including the forced password
  change on first login.
- **`accounts/`**: list accounts with live balances computed from posted
  journal lines. Petty cash imprest and top-up suggestion. Historical entries
  excluded from balances until history is merged.
- **`transactions/`**: the biggest module. Includes the posting engine that
  builds journal lines from a guided entry. Draft, pending, posted, reversed
  lifecycle. Approve, reject, reverse. Transfers as two linked legs through
  1118 Funds in transit. The opening entry. History merge check and merge.
  Ledger list with search, filter by account, category, status, direction,
  date range. Journal preview (what an entry would post, saved nowhere).
  Receipt upload (multer, 10 MB, images and PDF). Edit history from the
  audit log.
- **`taxes/`**: taxes in force on a date, and the suggestion engine that
  picks which taxes apply for a given direction, currency, account type and
  category, with ATL status resolved by the right party.
- **`vendors/`**: anyone Winibex pays other than employees. NTN, CNIC,
  ATL status with check date. The ATL status drives which tax rate applies.
- **`cheques/`**: the cheque register: issue, present, clear, bounce, cancel.
  Links to the transaction it represents.
- **`reimbursements/`**: when a person paid personally, this pays them back.
  Shows what the company owes each person (computed from posted transactions)
  and clears the payable in one transaction.
- **`attachments/`**: receipt and document uploads on transactions. Stored on
  disk, never in the database. Served through the API with login required,
  never from a static folder.
- **`categories/`**: the category picker, grouped by main head, with control
  accounts excluded.
- **`users/`**: thin list for the people picker (id, name, role). Not a full
  user management module yet.
- **`dashboard/`**: cash held per account, money in and out this month,
  pending count and flag count. The numbers the home screen shows.
- **`flags/`**: the review list of confirmed warnings and raised flags on
  transactions. Lives in `transactions/` in the code: `GET /flags` and
  `POST /flags/:id/resolve` (mark reviewed, owner or admin, with a note).
  `attachments/` resolves an entry's "No receipt" flag when a receipt
  arrives. Decision 056.
- **`history/`**: the merge check (difference per account between historical
  entries and the opening entry) and the merge itself.

This split (routes, service, repository) is worth understanding for an
interview. It means the rules can be tested without a web server, and the SQL
can change without touching the rules.

### `api/migrations/`: how the database is built

Numbered SQL files, run in order. The database remembers which have run.

- **`000_schema_migrations.sql`**: creates the list of which migrations have
  run. The first one.
- **`001_phase0_tables.sql`**: the twelve foundation tables.
- **`002_seed_reference.sql`**: fills in currencies, the chart of accounts,
  categories, settings, sequences. Also seeds 1118 Funds in transit and the
  Transfer in, Transfer out and Opening balance categories. The same for any
  company.
- **`003_bootstrap.sql`**: your specific company: the owner login, the company
  profile, the real accounts. Was a template; you filled it in.
- **`004_phase1_tables.sql`**: Phase 1: thirteen tables (taxes, tax_rules,
  vendors, cheques, transactions, journal_lines, transaction_taxes,
  transaction_charges, entry_flags, attachments, reimbursements,
  reimbursement_items, period_locks) plus four immutability triggers that
  prevent any UPDATE on posted rows' money fields.
- **`005_flag_resolution.sql`**: three columns on `entry_flags` (who resolved
  a flag, when, and why), a CHECK that keeps them consistent, and a clean-up
  of "No receipt" flags the first version raised by mistake. The first
  migration written after the live deploy, so a new file rather than an edit
  of 004. Decisions 052 and 056.

### `api/scripts/`: tools you run by hand

- **`migrate.js`**: applies migrations. `npm run migrate` shows status,
  `npm run migrate:up` applies pending ones.
- **`hash-password.js`**: makes a scrambled password to paste into phpMyAdmin
  when creating a login by hand.
- **`probe-deploy.js`**: throwaway. Proved the server runs your code on
  Hostinger. Should be deleted now that the real server is deployed.
- **`test/`**: the Phase 1 test kit, used by `docs/PHASE1-TEST.md`: dummy
  users and TEST taxes (`phase1-test-seed.sql`), id lookups, tamper tests and
  final checks (`phase1-checks.sql`), every API-only step ready to click in VS
  Code's REST Client (`phase1-api-tests.http`), and the wipe for afterwards
  (`phase1-reset.sql`). Never run the seed on production after the reset.

### `api/tests/`: proof that it all works

Every `.js` file here tests one area. They run against a real database, never a
fake one, because the guarantees being tested live in the database. `npm test`
runs them all. 373 tests after the defect fixes: 370 pass, 3 argon2 tests
skip until that package is installed.

Test files:

- **`database.test.js`**: proves CHECK constraints enforced, strict mode on,
  rollback complete, JSON round trips, BIGINT exact with supportBigNumbers.
- **`auth.test.js`**: login, refresh rotation, family revocation, logout,
  rate limiting, forced password change.
- **`password.test.js`**: bcrypt and argon2id hashing and verification.
- **`schema-001.test.js`**: every Phase 0 table constraint proved by raw SQL.
- **`schema-004.test.js`**: every Phase 1 table and trigger proved by raw SQL,
  including the immutability triggers that refuse UPDATEs on posted rows.
- **`posting.test.js`**: every worked posting example from
  CHART-OF-ACCOUNTS.md as a test asserting exact journal lines. If the chart
  document and the engine disagree, the test fails.
- **`property.test.js`**: 150 random valid operations (entries, transfers,
  reversals, reimbursements). After each, asserts the trial balance is zero
  and every account balance matches its journal lines.
- **`transactions.test.js`**: the full lifecycle: create draft, edit, submit,
  approve, reject, reverse. Blocking validation, warning validation, receipt
  rules, transfers, opening entry, history merge.
- **`approvals.test.js`**: permission checks: staff cannot approve, admin
  approval limits, auto-approve, possible_self_approval marker.
- **`receipts.test.js`**: upload, size limit, file type validation, receipt
  requirement enforcement at posting time.
- **`dashboard.test.js`**: cash balances, in/out totals, pending and flag
  counts match what the individual endpoints report.
- **`idempotency.test.js`**: same key returns same result, different key
  creates a new record.
- **`sequences.test.js`**: concurrent allocation produces no gaps and no
  duplicates.
- **`defect-fixes.test.js`**: one or more tests per defect found while
  writing the Phase 1 test (D1, D2, D5 to D9, D11, D12, D14). If any of them
  comes back, this file fails.

---

## The app, folder by folder

### Flutter vocabulary you asked about

- **l10n**: short for "localisation", the l, ten letters, then n. It means
  "all the words the user sees, kept in one place". The rule in this project:
  no English text is ever typed inside a screen. A screen asks for
  `l10n.actionSignIn` instead of writing `'Sign in'`. One place to change
  wording, nothing missed.
- **the `.arb` file** (`app/lib/l10n/app_en.arb`): that one place. It is just
  a list of labels in JSON: `"actionSignIn": "Sign in"`. The `en` means
  English. Adding Urdu later would be a new file, `app_ur.arb`, not a rewrite.
- **`l10n.yaml`**: a settings file that tells Flutter to turn the `.arb` file
  into real Dart code you can call with autocomplete. It runs on every build.
- **the `generated/` folder**: the Dart code Flutter writes from the `.arb`.
  Never edit it, never commit it. It is rebuilt from the `.arb`.
- **`build_runner`**: a tool that writes code for you. Riverpod uses it to
  turn a short `@riverpod` note into a full provider. You run
  `dart run build_runner build` after adding a provider. The files it writes
  end in `.g.dart` and are never edited by hand.
- **Riverpod**: the state management, like Bloc or Provider. It holds things
  the whole app needs (the logged-in user, the theme choice) and rebuilds the
  screens that use them when they change.
- **go_router**: decides which screen shows for which URL, and redirects to
  login when you are signed out.

### `app/lib/` root

- **`main.dart`**: the very start. Loads saved settings, then launches the app.
- **`app.dart`**: the root widget. Wires in the theme, the words, and the
  router. Shows a loading spinner while it checks whether you are already
  signed in.

### `app/lib/core/`: shared app code

- **`theme/app_theme.dart`**: every colour, size, spacing and font, in one
  file. Graphite and petrol palette, Onest typeface. Nothing anywhere else
  writes a colour. (Your file.)
- **`glossary/glossary.dart`**: the list of accounting terms and which label
  and tooltip each one uses. (Your file.)
- **`widgets/term_tooltip.dart`**: the widget that shows an accounting term
  with its plain-English explanation on hover or long-press.
- **`widgets/money_text.dart`**: displays a money value formatted with the
  currency symbol and correct decimal places. Red for negatives. Never does
  arithmetic, only formatting.
- **`widgets/empty_state.dart`**: the standard "nothing here yet" placeholder
  with an icon, a message and an optional action button.
- **`widgets/error_panel.dart`**: displays API errors with the human-readable
  message and a retry button. Maps error codes to localised strings.
- **`widgets/receipt_field.dart`**: the receipt picker: camera or file, with
  preview thumbnail and remove. Uses file_picker.
- **`api/api_retry.dart`**: wraps API calls with automatic retry on network
  failures and 401 refresh.
- **`settings/preferences.dart`**: access to saved settings on the device.
- **`settings/theme_controller.dart`**: holds the light/dark choice and saves
  it, so it survives a restart.
- **`router/app_router.dart`**: the list of screens and their URLs, plus the
  rule that sends you to login when signed out. Uses path URL strategy (no
  hash), with .htaccess SPA fallback on the server.
- **`api/api_config.dart`**: where the server is. Set at launch, so the same
  app points at localhost in development and the real domain in production.
- **`api/api_exception.dart`**: turns a server error into a Dart type the
  screens can read. Screens check the stable `code`, never the wording.
- **`api/error_message.dart`**: picks the sentence to show when the server
  refuses something: the server's own words for a refusal it explains, the
  app's wording for no answer or a server failure.
- **`api/api_client.dart`**: the thing that actually sends requests. It also
  quietly refreshes your login when the short-lived key expires, so you are
  not kicked out mid-session.
- **`auth/token_store.dart`**: keeps the long-lived login key safely between
  launches. Uses the phone's secure storage on Android; on web the browser
  holds it as a cookie instead.

### `app/lib/features/`: one folder per feature

Each feature splits into three or four, mirroring the API's shape:

- **`data/`**: talks to the API.
- **`domain/`**: the plain Dart objects, like `AuthUser`.
- **`application/`**: the state and logic, the Riverpod controllers.
- **`presentation/`**: the screens.

Current features:

- **`auth/`**: the login screen and everything behind it.
- **`shell/`**: the frame around every screen: the left navigation on desktop,
  the bottom bar on mobile, the theme and sign-out buttons.
- **`dashboard/`**: the home screen: cash held per account, money in and out
  this month, pending entries waiting for approval, flagged entries needing
  review. Real live data, not a placeholder.
- **`accounts/`**: the accounts list with live balances. Tapping an account
  filters the ledger to that account.
- **`transactions/`**: the largest feature folder:
  - The guided entry form: direction, currency, amount, paid by, rate or PKR,
    taxes and charges, category, receipt, then a review screen showing the
    journal preview before submitting
  - The ledger list with search, filters and pagination
  - The journal entry panel that opens on any posted transaction to show its
    debit and credit lines
  - The approval inbox for owner and admin
  - The edit history panel showing what changed on a transaction, from the
    audit log
  - Receipt upload with file_picker (camera or file)
- **`flags/`**: the flags review list: entries with confirmed warnings or
  raised flags. The owner and admins see a Mark reviewed button on each, which
  asks for a short note.
- **`change_password/`**: the change password screen, with the forced-change
  guard that redirects here on first login.

### `app/lib/l10n/`

- **`app_en.arb`**: every word the user sees. (Yours, extended.)
- **`generated/`**: the Dart code built from it. Do not touch.

### `app/test/`

78 Flutter widget tests after the defect fixes. Flutter analyze clean.

- **`foundation_test.dart`**: checks the theme and glossary hold together.
- **`login_test.dart`**: checks the login screen behaves on success, wrong
  password, rate limit and network failure.
- **`entry_form_test.dart`**: every step of the guided entry form, every
  conditional field, the journal preview, the warnings dialog.
- **`accounts_test.dart`**: the accounts list renders balances, tapping
  filters the ledger.
- **`money_text_test.dart`**: money formatting: PKR, USD, negatives, zero,
  large amounts.
- **`entry_screen_test.dart`**: the entry form end to end with a fake
  repository, including a refused save shown on screen, a retry after a
  refused posting that reuses the key, and the form starting again after a
  save.
- **`approvals_screen_test.dart`**: the approval inbox, including a refused
  approval that says why and leaves the card in place.
- **`flags_screen_test.dart`**: the review list, the Mark reviewed button
  for the owner and admins only, a short note sending nothing, a refusal shown.
- **`auth_user_test.dart`**: who may post their own entries: the owner, and
  an admin with auto-approve. Nobody else.

---
