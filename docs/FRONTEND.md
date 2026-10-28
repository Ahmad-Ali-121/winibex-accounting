# Frontend

The Flutter app. Rewritten 2026-10-03 to match the code as built, updated
2026-10-26 for the defect fixes. Where this
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
      error_message.dart        errorMessageFor: the sentence to show for a refusal
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
`flags`, `people` (adding people and what they may do), `shell` (the
navigation frame).

## People

`/settings` shows `PeopleScreen` to the owner and one line to anyone else.
`PeopleActions` is keep-alive like the other action providers and returns
`ApiException?`. A person is `TeamMember`, not `Person`, which is the thin
picker entry. The approval limit is typed in whole rupees and sent as
`Money.pkr(rupees * 100)`; empty sends null, no limit. Decision 063.

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
- **A refusal is shown, never swallowed.** A 4xx from the server is shown in
  the server's own words through `errorMessageFor`, because they carry the
  figure that explains it ("It holds PKR 9,700 today."). No answer gets
  `errNetwork`, a 5xx gets the generic server text, both from `app_en.arb`. The
  server keeps its messages free of SQL, paths and stack traces. Defect D3.
- **Action providers that write are `keepAlive`.** `ApprovalActions` and
  `FlagActions` are `@Riverpod(keepAlive: true, retry: noRetry)`. An
  auto-disposed action provider can be dropped mid-request, and the list
  refresh after it would never run. They return `ApiException?`: null when it
  worked, the refusal otherwise, so the screen decides how to show it.

## The entry form's save

`EntrySave` in `entry_draft_controller.dart` holds what happened to the last
press of the button: `SaveIdle`, `SaveInProgress`, `SaveNeedsConfirmation`
with the warnings, `SaveSucceeded`, or `SaveFailed` with the refusal.

- A press while `SaveInProgress` does nothing, and the button is disabled, so
  a double click sends one request
- The save is create, then upload the receipt if there is one, then approve
  or submit. The receipt goes before posting because a payment at or above
  the threshold is refused without it
- `SaveFailed` shows a red box on the review step with the reason. Going back
  a step clears it. If the draft was already created, pressing the button
  again finishes that same draft: it is edited first with
  `PATCH /transactions/:id` when anything changed, its receipt is sent only
  if it has not been sent already, then it is posted. The form never resends
  its key with different content. Defect F7, decision 059
- `SaveSucceeded` shows the confirmation, then throws the draft away and
  returns to step 1, so the next entry gets empty fields and a new key.
  Defect D10
- `EntrySave` remembers the draft it created (`_SentDraft`: id, the body last
  sent, the receipt already attached), tied to the form's idempotency key, so
  a new form never finishes an old draft. A receipt removed after it was sent
  stays attached on the server; there is no way yet to remove one

Whether the button reads "Save and post" or "Submit for approval" comes from
`AuthUser.canPostOwnEntries`: the owner, or an admin with `autoApproveOwn`.
Every other admin, and all staff, submit. It used to be "owner or admin",
which offered posting to admins the server refuses. Defect D4.

## The root widget and the splash

`app.dart` builds one `MaterialApp.router` from the first frame. While the
session is being restored on launch, the router's builder draws a splash in
place of the page, and the redirect holds position, so a refreshed or typed
address survives. The splash is a one-way latch: once the first answer is in,
it never comes back. Signing in does not set the session to loading. Defects
F1 and F4, decision 060.

## Errors on screen

`ApiException.isNetwork` is true only for code `NETWORK`, no answer at all. An
answer the app could not read becomes code `UNREADABLE`, printed with
`debugPrint`, and shown as `errUnreadable`. `ErrorPanel` and `errorMessageFor`
tell the three apart. Defect F6b.

## Dialogs that ask for a reason

`core/widgets/reason_dialog.dart`, `askForReason(...)`, used for rejecting an
entry and marking a flag reviewed. `AppSizes.dialogWidth` wide, hint on up to
three lines, and under three characters it stays open with
`errNoteTooShort`. O4 and O5.

## The review list

`FlagsScreen(canReview:)` shows a Mark reviewed button on each flag when
`canReview` is true, which the router sets from `AuthUser.canApprove`. The
dialog asks why it needs nothing more; under 3 characters nothing is sent.
After it works, the list is fetched again rather than edited in place.
Decision 056.
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
network is stubbed. Both themes are covered. 62 tests at the end of Phase 1,
78 after the defect fixes: refused saves and approvals, the key reused on a
retry, the form resetting, the review list, and who may post. 79 with F7: a
changed entry after a refusal edits and posts the same draft. 86 with the app
fixes: the sign-in error inside the real app, the date picker, the three kinds
of error, and the reason dialog. 95 with the People screen.
