# Code map

What every file does, in plain words. Written for someone who knows Flutter
but is new to Node. Read this when you come back to a file and cannot remember
why it exists.

Kept current as the project grows. If a file is not here, it was added after
this was last updated.

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

- **`server.js`** — the starting point. Checks the settings are present,
  connects to the database, starts listening. If something is wrong it stops
  immediately with a clear message, rather than failing confusingly later.
- **`app.js`** — assembles the server: security headers, JSON parsing, then
  attaches every module's routes. Kept separate from `server.js` so tests can
  build the app without actually opening a network port.
- **`package.json`** — the pubspec of the API. Dependencies ship to the
  server; devDependencies are local tools. `scripts` are `npm run <name>`
  shortcuts.
- **`.env`** — your secrets and settings (database password, token secrets).
  Never committed. You made it by copying `.env.example`.
- **`.env.example`** — the blank template of `.env`, safe to commit.
- **`eslint.config.mjs`** — the linter, like `analysis_options.yaml`. It also
  blocks `Math.round` and `parseFloat`, because money is whole paisa and must
  never become a decimal.
- **`.nvmrc`** — records that this project uses Node 24.

### `api/core/` — shared code every feature uses

- **`config.js`** — reads `.env` once and refuses to start if something
  required is missing. One place that knows every setting.
- **`db.js`** — the database connection pool. Also holds `withTransaction`,
  which runs several database changes as one unit: all succeed or all are
  undone. The posting engine will lean on this heavily.
- **`password.js`** — turns a password into a scrambled string, and checks one
  later. Reads which scrambler was used from the stored value itself, so the
  method can change without locking anyone out.
- **`errors.js`** — one shape for every error the API returns:
  `{ error: { code, message, field, details } }`. `code` is stable for the app
  to switch on; `message` is safe to show a person.
- **`tokens.js`** — makes and checks the two kinds of login key (see Auth
  below).
- **`auth.js`** — the gatekeepers: "is this request signed in" and "does this
  role have permission". Used by routes that need protecting.
- **`rate-limit.js`** — counts failed logins and blocks after too many, to stop
  password guessing. Counts failures only, so normal use never triggers it.
- **`audit.js`** — writes a record of every change to money, for the ten-year
  audit trail. The record is written in the same unit as the change, so it can
  never describe something that was undone.
- **`sequences.js`** — hands out invoice and journal numbers with no gaps. If
  the work fails, the number is handed back. Auditors ask about gaps first.
- **`idempotency.js`** — stops a double tap or a dropped connection from
  recording the same expense twice.
- **`json.js`** — a small helper for reading and writing the database's JSON
  columns, which behave slightly differently on MariaDB.
- **`sql-split.js`** — splits a migration file into separate statements so they
  can be run one at a time. Needed because a database trigger is full of
  semicolons and a naive split would cut it in half.

### `api/modules/` — one folder per feature

Each feature folder holds up to four files, always the same shape:

- **`routes.js`** — the URLs this feature answers, and the validation of what
  comes in. No business logic here.
- **`service.js`** — the actual rules. The thinking part.
- **`repository.js`** — the SQL. The only file that talks to the database for
  this feature.
- **`schema.js`** — the shape of what a request may contain (added where
  needed).

Current modules:

- **`health/`** — one URL, `GET /health`, that says whether the server and
  database are up. No login needed. Used for monitoring.
- **`auth/`** — login, logout, refreshing the session, and "who am I". The
  whole login system.

This split (routes, service, repository) is worth understanding for an
interview. It means the rules can be tested without a web server, and the SQL
can change without touching the rules.

### `api/migrations/` — how the database is built

Numbered SQL files, run in order. The database remembers which have run.

- **`000_schema_migrations.sql`** — creates the list of which migrations have
  run. The first one.
- **`001_phase0_tables.sql`** — the twelve foundation tables.
- **`002_seed_reference.sql`** — fills in currencies, the chart of accounts,
  categories, settings, sequences. The same for any company.
- **`003_bootstrap.sql`** — your specific company: the owner login, the company
  profile, the real accounts. Was a template; you filled it in.

### `api/scripts/` — tools you run by hand

- **`migrate.js`** — applies migrations. `npm run migrate` shows status,
  `npm run migrate:up` applies pending ones.
- **`hash-password.js`** — makes a scrambled password to paste into phpMyAdmin
  when creating a login by hand.
- **`probe-deploy.js`** — throwaway. Proves the server runs your code on
  Hostinger. Deleted after the first deploy.

### `api/tests/` — proof that it all works

Every `.js` file here tests one area. They run against a real database, never a
fake one, because the guarantees being tested live in the database. `npm test`
runs them all. 124 tests as of end of Phase 0.

---

## The app, folder by folder

### Flutter vocabulary you asked about

- **l10n** — short for "localisation", the l, ten letters, then n. It means
  "all the words the user sees, kept in one place". The rule in this project:
  no English text is ever typed inside a screen. A screen asks for
  `l10n.actionSignIn` instead of writing `'Sign in'`. One place to change
  wording, nothing missed.
- **the `.arb` file** (`app/lib/l10n/app_en.arb`) — that one place. It is just
  a list of labels in JSON: `"actionSignIn": "Sign in"`. The `en` means
  English. Adding Urdu later would be a new file, `app_ur.arb`, not a rewrite.
- **`l10n.yaml`** — a settings file that tells Flutter to turn the `.arb` file
  into real Dart code you can call with autocomplete. It runs on every build.
- **the `generated/` folder** — the Dart code Flutter writes from the `.arb`.
  Never edit it, never commit it. It is rebuilt from the `.arb`.
- **`build_runner`** — a tool that writes code for you. Riverpod uses it to
  turn a short `@riverpod` note into a full provider. You run
  `dart run build_runner build` after adding a provider. The files it writes
  end in `.g.dart` and are never edited by hand.
- **Riverpod** — the state management, like Bloc or Provider. It holds things
  the whole app needs (the logged-in user, the theme choice) and rebuilds the
  screens that use them when they change.
- **go_router** — decides which screen shows for which URL, and redirects to
  login when you are signed out.

### `app/lib/` root

- **`main.dart`** — the very start. Loads saved settings, then launches the app.
- **`app.dart`** — the root widget. Wires in the theme, the words, and the
  router. Shows a loading spinner while it checks whether you are already
  signed in.

### `app/lib/core/` — shared app code

- **`theme/app_theme.dart`** — every colour, size, spacing and font, in one
  file. Graphite and petrol palette, Onest typeface. Nothing anywhere else
  writes a colour. (Your file.)
- **`glossary/glossary.dart`** — the list of accounting terms and which label
  and tooltip each one uses. (Your file.)
- **`widgets/term_tooltip.dart`** — the widget that shows an accounting term
  with its plain-English explanation on hover or long-press.
- **`settings/preferences.dart`** — access to saved settings on the device.
- **`settings/theme_controller.dart`** — holds the light/dark choice and saves
  it, so it survives a restart.
- **`router/app_router.dart`** — the list of screens and their URLs, plus the
  rule that sends you to login when signed out.
- **`api/api_config.dart`** — where the server is. Set at launch, so the same
  app points at localhost in development and the real domain in production.
- **`api/api_exception.dart`** — turns a server error into a Dart type the
  screens can read. Screens check the stable `code`, never the wording.
- **`api/api_client.dart`** — the thing that actually sends requests. It also
  quietly refreshes your login when the short-lived key expires, so you are
  not kicked out mid-session.
- **`auth/token_store.dart`** — keeps the long-lived login key safely between
  launches. Uses the phone's secure storage on Android; on web the browser
  holds it as a cookie instead.

### `app/lib/features/` — one folder per feature

Each feature splits into three, mirroring the API's shape:

- **`data/`** — talks to the API.
- **`domain/`** — the plain Dart objects, like `AuthUser`.
- **`application/`** — the state and logic, the Riverpod controllers.
- **`presentation/`** — the screens.

Current features:

- **`auth/`** — the login screen and everything behind it.
- **`shell/`** — the frame around every screen: the left navigation on desktop,
  the bottom bar on mobile, the theme and sign-out buttons.
- **`dashboard/`** — a placeholder until Phase 6.

### `app/lib/l10n/`

- **`app_en.arb`** — every word the user sees. (Yours, extended.)
- **`generated/`** — the Dart code built from it. Do not touch.

### `app/test/`

- **`foundation_test.dart`** — checks the theme and glossary hold together.
- **`login_test.dart`** — checks the login screen behaves on success, wrong
  password, rate limit and network failure.

---