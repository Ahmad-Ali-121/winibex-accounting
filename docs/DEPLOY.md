# Deploy

Hostinger Business plan. Node.js web app for the API, managed MySQL, static
hosting for the Flutter web build.

Status: Plan. Fill in exact values as each step is done.

## Layout

| Piece | Where | Example |
| --- | --- | --- |
| API | Hostinger Node.js app, deployed from GitHub | `api.<domain>` |
| Web app | Static files from `flutter build web --wasm` | `books.<domain>` |
| Database | Hostinger managed MySQL | |
| Receipts and PDFs | Server disk, outside the web root | |
| Android | APK distributed internally, Play Store later if wanted | |

## Known Hostinger constraints

- npm install runs automatically on deploy. You cannot run npm commands over
  SSH on the Business plan. Anything needing a build step must work through
  the deploy pipeline
- Environment variables need an app restart to take effect
- No migration CLI. Migrations are numbered SQL files applied in order through
  phpMyAdmin, and each one records itself in a `schema_migrations` table
- No headless Chrome. PDFs use a pure-Node PDF library

## First deploy

- Step 0.1 includes a throwaway deploy to prove the `argon2` native module
  builds on Hostinger. If it fails, switch to `bcryptjs` before login is built
- The owner's first password hash is generated locally and pasted into the
  seed SQL in phpMyAdmin. `must_change_password` forces a new password on
  first login

## Environment variables

| Name | Purpose |
| --- | --- |
| `NODE_ENV` | production |
| `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD` | |
| `JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET` | long random strings |
| `CORS_ORIGINS` | the web app domain only |
| `UPLOAD_DIR` | absolute path outside the web root |
| `CRON_SECRET` | protects the cron endpoint |
| `TZ` | UTC |

Never committed. `.env.example` lists the names with no values.

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
