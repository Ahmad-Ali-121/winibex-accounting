# Winibex Accounting

Internal accounting system for Winibex PVT LTD.

- `api/` the server. Node and Express. All business rules live here
- `app/` the Flutter app, web and Android. Empty until step 0.12
- `mcp/` AI access to the books. Empty until Phase 9
- `docs/` the plan. Read `docs/PROGRESS.md` first

## Setting up, first time only

You need two programs installed.

**1. Node.js 24**

Download from nodejs.org, take the LTS version, install with all defaults.
Check it worked by opening a terminal and running:

```bash
node -v
```

It should print something starting with `v24`.

**2. Docker Desktop**

Download from docker.com, install, then start it. On Windows it may ask to
enable WSL and restart. Let it.

Docker runs the database on your machine without you installing a database.
Check it worked:

```bash
docker --version
```

Leave Docker Desktop running whenever you are working on this project.

## Starting work

Open a terminal in this folder.

```bash
# 1. Make your settings file. Only needed once.
cp api/.env.example api/.env

# 2. Start the database. Takes about 20 seconds the first time.
docker compose up -d

# 3. Install the server's packages. Only needed once, and again
#    whenever package.json changes.
cd api
npm install

# 4. Check everything works
npm run lint
npm test
npm run probe
```

Expected: lint prints nothing, tests pass with a few skipped, and the probe
prints `"ok": true`.

When you finish for the day, `docker compose down` stops the database. Your
data stays.

## The database

Production is Hostinger managed MariaDB 11.8, so the local one is MariaDB 11.8
too. Developing against a different database means finding the differences in
production.

There are two databases in the container. `winibex` is the real one you work
with. `winibex_test` is wiped and rebuilt by the test suite, which is why it is
kept separate.

To look inside with a terminal: `npm run db:shell`.
To wipe it and start clean: `npm run db:reset`.

## Passwords

Passwords are never stored as readable text. They are scrambled first, by
`api/core/password.js`.

Currently set to bcrypt, which always installs anywhere. argon2id is stronger
and can be switched on later by installing the `argon2` package and changing
one line in `api/.env`. Existing passwords keep working either way, because
`verifyPassword` reads which method was used from the stored value itself.

## Commands

Run these from inside `api/`.

| Command | What it does |
| --- | --- |
| `npm run lint` | Checks code style. Prints nothing when clean |
| `npm test` | Runs all tests against the real database |
| `npm run probe` | Checks Node and password hashing work here |
| `npm run hash:password` | Makes a password hash to paste into phpMyAdmin |
| `npm run db:up` | Starts the database |
| `npm run db:down` | Stops the database |
| `npm run db:reset` | Deletes everything and starts the database fresh |
| `npm run db:shell` | Opens a database terminal |

## Rules that do not bend

Full detail in `AGENTS.md`. The short version:

- Every money movement writes balanced debit and credit lines, or nothing saves
- A posted entry is never edited by anyone. Mistakes are fixed by reversing
- Money is whole paisa, stored as integers. Never a decimal
- Tax rates are rows in a table with dates, never numbers written into code
- The Flutter app never calculates a balance. It shows what the server says
