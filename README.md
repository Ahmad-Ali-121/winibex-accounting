# Winibex Accounting

Internal double-entry accounting system for Winibex PVT LTD. Replaces the
Expense Tracker spreadsheet.

Covers cash and bank accounts, income and expenses, multi-currency with
Pakistani tax handling, clients and projects, Upwork earning accounts with
partner splits, quotations, invoices and receipts, payroll, recurring costs,
and the full set of financial statements.

## Stack

Flutter for web and Android, Node with Express for the API, MySQL. Hosted on
Hostinger.

## Repository

| Folder | Contents |
| --- | --- |
| `app/` | Flutter app |
| `api/` | Express API and posting engine |
| `mcp/` | MCP server for AI tool access, read only |
| `docs/` | Everything below |

## Documentation

| File | Read when |
| --- | --- |
| `docs/OVERVIEW.md` | First. The whole picture in one read |
| `docs/PROGRESS.md` | Starting any session. Where work stopped |
| `docs/SCHEMA.md` | Touching data |
| `docs/CHART-OF-ACCOUNTS.md` | Touching posting or reports |
| `docs/TAXES.md` | Touching tax |
| `docs/API.md` | Adding or calling an endpoint |
| `docs/FRONTEND.md` | Writing Flutter code |
| `app/lib/core/theme/app_theme.dart` | Any colour, font, size or spacing |
| `app/lib/l10n/app_en.arb` | Any text a user sees |
| `docs/UI-GUIDE.md` | Designing any screen |
| `docs/DECISIONS.md` | Wondering why something is the way it is |
| `docs/TESTING.md` | Before merging |
| `docs/DEPLOY.md` | Before releasing |

## Getting started

See `AGENTS.md` for commands.
