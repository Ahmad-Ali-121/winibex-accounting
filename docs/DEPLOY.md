# Deploy

Hostinger Business plan. Node.js web app for the API, managed MariaDB, static
hosting for the Flutter web build.

Status: Plan. Fill in exact values as each step is done.

## Layout

| Piece | Where | Example |
| --- | --- | --- |
| API | Hostinger Node.js app, deployed from GitHub | `api.<domain>` |
| Web app | Static files from `flutter build web --wasm` | `books.<domain>` |
| Database | Hostinger managed MariaDB 11.8 | |
| Receipts and PDFs | Server disk, outside the web root | |
| Android | APK distributed internally, Play Store later if wanted | |

## Server facts, confirmed 2026-10-01

| | |
| --- | --- |
| Database | `11.8.9-MariaDB-log`, checked with `SELECT VERSION()` in phpMyAdmin |
| Node | 24.x selected in hPanel. 18, 20, 22 and 24 are offered |
| Connections | 75 maximum per database user. The pool limit must stay well under this |

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
| `connectionLimit` | Well under Hostinger's 75 per user |
| Session `sql_mode` | `STRICT_ALL_TABLES` and friends, so nothing is silently truncated |
| Session `time_zone` | `+00:00` |
| Session `transaction_isolation` | `READ-COMMITTED` |

Tables are created `utf8mb4` with `utf8mb4_uca1400_ai_ci`. MySQL's
`utf8mb4_0900_ai_ci` does not exist on MariaDB.

## First deploy

- A throwaway deploy of `api/scripts/probe-deploy.js` confirms the app runs,
  reports the Node version, and proves password hashing works on the real
  server. Deleted once step 0.6 lands the real server
- The owner's first password hash is generated locally with
  `npm run hash:password` and pasted into the seed SQL in phpMyAdmin.
  `must_change_password` forces a new password on first login
- Decide at this point whether to switch from bcryptjs to argon2id. There are
  no real passwords yet, so the cost either way is zero. Open item L in
  `docs/DECISIONS.md`

## Environment variables

| Name | Purpose |
| --- | --- |
| `NODE_ENV` | production |
| `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD` | |
| `PASSWORD_ALGORITHM` | `bcrypt` or `argon2id`. See decision 042 |
| `JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET` | long random strings |
| `CORS_ORIGINS` | the web app domain only |
| `UPLOAD_DIR` | absolute path outside the web root |
| `CRON_SECRET` | protects the cron endpoint |
| `TZ` | UTC |

Never committed. `.env.example` lists the names with local defaults for the
database only, and blanks for everything secret.

## Web app headers

Wasm multithreading needs these on every response for the web app:

```
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: credentialless
```

Set them in `.htaccess` for the static site. Test that the API's CORS headers
still allow the app once COEP is on, since it tightens cross-origin loading.

Also: long cache headers on hashed asset files, no cache on `index.html` and
`flutter_service_worker.js`, so users get updates immediately.

## Cron

One Hostinger cron job, daily, calling the protected endpoint:

```
curl -fsS -X POST -H "X-Cron-Secret: $CRON_SECRET" https://api.<domain>/api/v1/jobs/daily
```

The daily job creates recurring instances, recalculates overdue invoice
status, and raises time-based flags.

## Backups

- Hostinger daily backups, already included
- Plus a nightly SQL dump written to the server and copied off it weekly.
  A backup on the same server as the data is not a backup
- Monthly restore test into a scratch database. An untested backup is a hope

## Release checklist

1. All tests pass, see `docs/TESTING.md`
2. New migrations applied to production in order
3. Env vars changed? Restart the API app
4. Build web with `--wasm --release`, upload, confirm headers
5. Smoke test: log in, view balances, create and post a test entry, reverse it
6. Update `docs/PROGRESS.md`
