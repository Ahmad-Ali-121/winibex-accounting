// The accounts screen, in both themes, through every state it can be in.
//
// The repository is replaced rather than the provider overridden one by one,
// so the real provider, the real parsing and the real widgets all run. The
// only thing that does not happen is the network call.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winibex_accounting/core/api/api_exception.dart';
import 'package:winibex_accounting/core/money/money.dart';
import 'package:winibex_accounting/core/theme/app_theme.dart';
import 'package:winibex_accounting/features/accounts/data/accounts_repository.dart';
import 'package:winibex_accounting/features/accounts/domain/account.dart';
import 'package:winibex_accounting/features/accounts/presentation/accounts_screen.dart';
import 'package:winibex_accounting/l10n/generated/app_localizations.dart';


class _FakeAccountsRepository extends AccountsRepository {
  _FakeAccountsRepository({this.summary, this.failure}) : super(dio: Dio());

  final AccountsSummary? summary;
  final Object? failure;

  @override
  Future<AccountsSummary> list({bool includeInactive = false}) async {
    if (failure != null) throw failure!;
    return summary!;
  }
}

Account _account({
  int id = 1,
  String name = 'Winibex bank',
  AccountType type = AccountType.bank,
  String code = '1113',
  int balance = 50000000,
  bool isActive = true,
}) {
  return Account(
    id: id,
    name: name,
    type: type,
    isActive: isActive,
    ledger: LedgerAccount(id: id, code: code, name: 'Bank'),
    balance: Money.pkr(balance),
  );
}

AccountsSummary _summary({
  List<Account>? accounts,
  int total = 50000000,
  bool historyMerged = false,
}) {
  return AccountsSummary(
    accounts: accounts ?? [_account()],
    total: Money.pkr(total),
    historyMerged: historyMerged,
  );
}

Future<void> _pump(
  WidgetTester tester, {
  AccountsSummary? summary,
  Object? failure,
  Brightness brightness = Brightness.light,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        accountsRepositoryProvider.overrideWithValue(
          _FakeAccountsRepository(summary: summary, failure: failure),
        ),
      ],
      child: MaterialApp(
        theme: brightness == Brightness.light ? AppTheme.light : AppTheme.dark,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: AccountsScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('balances and the total are shown as the server sent them', (tester) async {
    await _pump(
      tester,
      summary: _summary(
        accounts: [
          _account(name: 'Winibex bank', balance: 50000000),
          _account(id: 2, name: 'Office cash', type: AccountType.cash, code: '1111', balance: 600000),
        ],
        total: 50600000,
      ),
    );

    expect(find.text('Winibex bank'), findsOneWidget);
    expect(find.text('Office cash'), findsOneWidget);
    expect(find.text('500,000.00'), findsOneWidget);
    expect(find.text('6,000.00'), findsOneWidget);

    // The total carries its currency, and is the server's figure rather than
    // anything added up here.
    expect(find.text('PKR 506,000.00'), findsOneWidget);
  });

  testWidgets('a negative balance keeps its sign', (tester) async {
    await _pump(
      tester,
      summary: _summary(accounts: [_account(balance: -2500000)], total: -2500000),
    );

    expect(find.text('-25,000.00'), findsOneWidget);
  });

  testWidgets('the ledger code is shown beside the account', (tester) async {
    await _pump(tester, summary: _summary());

    // The accountant reads 1113; the company reads "Winibex bank". Both are
    // on the row.
    expect(find.textContaining('1113'), findsOneWidget);
  });

  testWidgets('a notice appears while history is unmerged, and goes when it is not', (tester) async {
    await _pump(tester, summary: _summary(historyMerged: false));
    expect(find.textContaining('1 July 2026'), findsOneWidget);

    await _pump(tester, summary: _summary(historyMerged: true));
    expect(find.textContaining('1 July 2026'), findsNothing);
  });

  testWidgets('a closed account is marked rather than hidden silently', (tester) async {
    await _pump(
      tester,
      summary: _summary(accounts: [_account(name: 'Old account', isActive: false)]),
    );

    expect(find.text('Old account'), findsOneWidget);
    expect(find.text('Closed'), findsOneWidget);
  });

  testWidgets('no accounts shows an empty state, not an empty table', (tester) async {
    await _pump(tester, summary: _summary(accounts: [], total: 0));

    expect(find.text('No accounts yet'), findsOneWidget);
  });

  testWidgets('a network failure says the connection failed, not that we broke', (tester) async {
    await _pump(
      tester,
      failure: const ApiException(code: 'NETWORK', message: 'Could not reach the server.'),
    );

    expect(find.textContaining('Could not reach the server'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets("a server error shows the server's own wording", (tester) async {
    await _pump(
      tester,
      failure: const ApiException(
        code: 'FORBIDDEN',
        message: 'Only the owner or an admin can see this.',
        status: 403,
      ),
    );

    expect(find.text('Only the owner or an admin can see this.'), findsOneWidget);
  });

  testWidgets('it renders in the dark theme too', (tester) async {
    await _pump(tester, summary: _summary(), brightness: Brightness.dark);

    expect(find.text('Winibex bank'), findsOneWidget);
    expect(find.text('500,000.00'), findsOneWidget);
  });
}
