# Frontend

The Flutter app. Rewritten 2026-10-03 to match the code as built. Where this
document and the code ever disagree, the code wins and this file is wrong.

## Stack

- Flutter, Material 3, single `MaterialApp` with light and dark themes
- Riverpod 3 with code generation (`@riverpod`, `@Riverpod(keepAlive: true)`)
- go_router, one router built as a keep-alive provider
- dio for HTTP, one configured instance behind `dioProvider`
- `flutter_localizations` and gen-l10n for all user-facing text

`riverpod_lint` is not installed. It pins an older analyzer than
`riverpod_generator` needs, which blocks resolution. Decision 049.

## Where things live

```
lib/
  main.dart                     app entry, URL strategy, runApp
  app.dart                      the MaterialApp, themes, router wiring
  core/
    api/
      api_client.dart           dioProvider, the access-token holder, refresh
      api_config.dart           base URL, from --dart-define at build
      api_exception.dart        the server error shape as one Dart type
      api_retry.dart            noRetry, used by every read provider
      idempotency_key.dart      a v4 key per money-creating request
    auth/
      token_store.dart          the refresh token, in secure storage
    money/
      money.dart                integer minor units, formatting, no doubles
    router/
      app_router.dart           routes, the redirect guard, the shell wiring
    settings/                   theme controller, preferences
    theme/
      app_theme.dart            the one source of colour, type, spacing
    widgets/
      money_text.dart           every amount on screen goes through this
      empty_state.dart, error_panel.dart
  features/
    <name>/
      data/                     the repository: dio calls, JSON to models
      domain/                   the models, plain classes with fromJson
      application/              the providers and controllers
      presentation/             screens, and widgets/ for pieces of them
  l10n/
    app_en.arb                  every string
    generated/                  AppLocalizations, built by gen-l10n
```

A feature is a folder under `features/` with those four subfolders. Each
feature's providers live in its own `application/`, not in a shared place.
The same four file roles repeat in every feature, so `service`-style logic for
transactions is `features/transactions/application/`, and its dio calls are
`features/transactions/data/transactions_repository.dart`.

Features built in Phase 1: `auth`, `accounts`, `transactions` (the posting
form, the ledger, approvals, the journal and history panels), `dashboard`,
`flags`, `shell` (the navigation frame).

## Rules that do not bend

- **No raw colours, sizes, or text styles in feature code.** Everything comes
  from `app_theme.dart` via `context.colors`, `AppSpacing`, `AppRadii`,
  `AppText`, or `Theme.of(context)`. A literal `Color(...)` or `fontSize:` in a
  feature file fails review.
- **No money as a double, ever.** `Money` holds integer minor units and formats
  by building the string from the integer. `Money.fromJson` throws on a decimal
  rather than rounding. Every amount on screen is a `MoneyText`.
- **The app never calculates anything financial.** Balances, journal lines, tax
  and totals all come from the server. After a write, a screen invalidates and
  refetches rather than adjusting a number locally. AGENTS.md.
- **Read providers do not retry.** `@Riverpod(retry: noRetry)`. A failed read
  shows an error panel with a Try again button; the person decides. A silent
  retry leaves the screen on a spinner saying nothing.
- **Writes carry an idempotency key**, generated when the form opens, so a
  double tap or a dropped reply cannot post the same thing twice.
- **The API base URL is a build-time define.** The source defaults to
  localhost; production is passed with
  `--dart-define=API_BASE_URL=https://api-accounting.winibex.com/api/v1`.
  Nothing in the repository names the production host.

## Routing and the session

`app_router.dart` builds a `GoRouter` as a keep-alive provider and listens to
the auth controller, so signing in or out moves the user without a manual
navigation call. The redirect enforces three things in order:

1. A dropped session (a failed refresh) forces the login screen.
2. Not signed in anywhere but login → login. Signed in and sitting on login →
   dashboard.
3. Signed in with `mustChangePassword` true → the change-password screen, and
   nothing else is reachable until it is done. Once false, nobody sits on that
   screen.

The signed-in screens live inside a `ShellRoute` that draws the navigation
frame once and swaps the child.

## Web specifics

- Path URL strategy (`usePathUrlStrategy()` in `main()`), so addresses read
  `/accounts`, not `/#/accounts`.
- The deployed `.htaccess` forces HTTPS and falls any unknown path back to
  `index.html`, so a refresh on a deep link works and a plain-http visit
  redirects rather than breaking CORS.
- Fonts (Onest) are bundled as assets, not fetched, so the app works under the
  COEP header and loads with no network round trip. Numbers use tabular figures
  so columns align.

## Testing

Widget tests replace the repository with a fake and let the real providers,
widgets and models run, so parsing and rendering are exercised; only the
network is stubbed. Both themes are covered. 62 tests at the end of Phase 1.
