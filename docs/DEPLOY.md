# Deploy

Hostinger Business plan. Node.js web app for the API, managed MariaDB, static
hosting for the Flutter web build.

Status: Phase 1 deployed and live. CI/CD in place.

## Layout

| Piece | Where | URL |
| --- | --- | --- |
| API | Hostinger Node.js app, deployed from GitHub via Git integration | api-accounting.winibex.com |
| Web app | Static files from `flutter build web --wasm`, deployed via GitHub Actions + FTP | accounting.winibex.com |
| Database | Hostinger managed MariaDB 11.8 | |
| Receipts and PDFs | Server disk, outside the web root | |
| Android | APK distributed internally, Play Store later if wanted | Phase 7 |

## CI/CD

**API:** Hostinger Git integration. Push to the main branch and Hostinger
pulls and restarts automatically. npm install runs on deploy. No build step
needed for plain Node.

**Web app:** GitHub Actions workflow. On push, it builds
`flutter build web --wasm`, then uploads the `build/web/` output to Hostinger
over FTP. The .htaccess file is committed in the repo and deployed with the
build.

## Server facts, confirmed 2026-10-01

| | |
| --- | --- |
| Database | `11.8.9-MariaDB-log`, checked with `SELECT VERSION()` in phpMyAdmin |
| Node | 24.x selected in hPanel. 18, 20, 22 and 24 are offered |
| Connections | `max_connections` reports 2000. The pool's `connectionLimit` stays well under it regardless: the figure is shared across all databases on the server |

Re-check both after any Hostinger platform change. A major version move on
either is a migration, not a surprise to discover in production.

## Known Hostinger constraints

- npm install runs automatically on deploy. You cannot run npm commands over
  SSH on the Business plan. Anything needing a build step must work through
  the deploy pipeline
- A native module that fails to compile fails the whole deploy, with no way to
  read the build log. This is why the password module avoids one by default,
  see decision 042
- Environment variables need an app restart to take effect
- No migration CLI. Migrations are numbered SQL files applied in order through
  phpMyAdmin, and each one records itself in a `schema_migrations` table
- No headless Chrome. PDFs use a pure-Node PDF library
- Global `sql_mode` and the server time zone cannot be changed. The connection
  pool sets strict mode, UTC and READ-COMMITTED per connection instead

## Database connection settings

Every connection, local and production, sets the same options. They live in
`api/core/db.js` and are asserted by `api/tests/database.test.js`.

| Option | Why |
| --- | --- |
| `supportBigNumbers: true` | Without it the driver rounds a BIGINT past JavaScript's safe integer limit, silently. Money is BIGINT paisa. Decision 044 |
| `timezone: 'Z'` | Timestamps are UTC everywhere |
| `multipleStatements: false` | Removes a whole class of injection |
| `connectionLimit` | Well under Hostinger's 2000 max_connections (shared across the server) |
| Session `sql_mode` | `STRICT_ALL_TABLES` and friends, so nothing is silently truncated |
| Session `time_zone` | `+00:00` |
| Session `transaction_isolation` | `READ-COMMITTED` |

Tables are created `utf8mb4` with `utf8mb4_unicode_ci`. Hostinger's MariaDB
11.8.9 does not have MariaDB's `utf8mb4_uca1400_ai_ci`, although the local
Docker 11.8 does. MySQL's `utf8mb4_0900_ai_ci` does exist on Hostinger.
Decision 054.

## Web app .htaccess

The .htaccess file for the web app handles four things:

1. **Force HTTPS.** Redirects all HTTP requests to HTTPS.
2. **SPA fallback.** All requests that do not match a real file are rewritten
   to `index.html`, so path-based URLs (no hash) work with page refresh and
   direct links.
3. **COOP/COEP headers.** Required for wasm multithreading:
   `Cross-Origin-Opener-Policy: same-origin` and
   `Cross-Origin-Embedder-Policy: credentialless`.
4. **Cache headers.** Long cache on hashed asset files (JS, CSS, wasm), no
   cache on `index.html` and `flutter_service_worker.js` so users get updates
   immediately.

## First deploy

- A throwaway deploy of `api/scripts/probe-deploy.js` confirmed the app runs,
  reported the Node version, and proved password hashing works on the real
  server. **Done 2026-10-03, decision 054.** It also found that the collation
  every migration used does not exist on this server, before a single table was
  created. The file should be deleted
- The owner's first password hash was generated locally with
  `npm run hash:password` and pasted into the seed SQL in phpMyAdmin.
  `must_change_password` forces a new password on first login
- **Settled: bcryptjs stays.** 295 ms to hash and 282 ms to verify on the real
  server, well under the second that makes a login feel broken. argon2id is a
  native module and decision 042 records what a failed compile does to a
  Hostinger deploy. Open item L is closed, decision 054

## Environment variables

| Name | Purpose |
| --- | --- |
| `NODE_ENV` | production |
| `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD` | |
| `PASSWORD_ALGORITHM` | `bcrypt` or `argon2id`. See decision 042 |
| `JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET` | long random strings |
| `CORS_ORIGINS` | the web app domain: `https://accounting.winibex.com` |
| `UPLOAD_DIR` | absolute path outside the web root |
| `CRON_SECRET` | protects the cron endpoint |
| `TZ` | UTC |

Never committed. `.env.example` lists the names with local defaults for the
database only, and blanks for everything secret.

## Cron

One Hostinger cron job, daily, calling the protected endpoint:

```
curl -fsS -X POST -H "X-Cron-Secret: $CRON_SECRET" https://api-accounting.winibex.com/api/v1/jobs/daily
```

The daily job creates recurring instances, recalculates overdue invoice
status, and raises time-based flags.

## Resetting a database (test runs only)

`api/scripts/test/phase1-reset.sql` drops every table. In phpMyAdmin, untick
"Enable foreign key checks" below the SQL box first: that box overrides the
script's own `SET FOREIGN_KEY_CHECKS = 0`, and with it ticked the drops stop
at `transactions`. Tick it again before applying migrations. Never run this on
production once real entries exist.

## Backups

- Hostinger daily backups, already included
- Plus a nightly SQL dump written to the server and copied off it weekly.
  A backup on the same server as the data is not a backup
- Monthly restore test into a scratch database. An untested backup is a hope

## Release checklist

1. All tests pass, see `docs/TESTING.md`
2. New migrations applied to production in order via phpMyAdmin, **before**
   the push. The API deploys itself on push, and new code may read columns
   only the new migration creates
3. Env vars changed? Restart the API app in hPanel
4. Push to main: API auto-deploys via Git integration, web app deploys via
   GitHub Actions + FTP
5. Smoke test: log in, view balances, open each changed screen. **Do not
   post test entries on production**: since 2026-10-27 it holds the real
   books, and a posted entry can only be reversed, never removed
6. Update `docs/PROGRESS.md`
