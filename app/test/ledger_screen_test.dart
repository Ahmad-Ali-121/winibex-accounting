// The ledger.
//
// The repository is replaced so the real providers, widgets and models run.
// The two worth reading are at the bottom: searching asks the server rather
// than filtering what is on screen, and a reversed entry stays in the list.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:winibex_accounting/core/api/api_exception.dart';
import 'package:winibex_accounting/core/money/money.dart';
import 'package:winibex_accounting/core/theme/app_theme.dart';
import 'package:winibex_accounting/features/transactions/data/transactions_repository.dart';
import 'package:winibex_accounting/features/transactions/domain/journal_preview.dart';
import 'package:winibex_accounting/features/transactions/domain/ledger.dart';
import 'package:winibex_accounting/features/transactions/presentation/ledger_screen.dart';
import 'package:winibex_accounting/l10n/generated/app_localizations.dart';

TransactionSummary _entry({
  int id = 1,
  String date = '2026-07-05',
  String direction = 'out',
  int amount = 900000,
  String description = 'Office rent July',
  String status = 'posted',
  String? journalNumber = 'JV-1',
  bool isReversed = false,
  int flagCount = 0,
}) {
  return TransactionSummary(
    id: id,
    date: date,
    direction: direction,
    amount: Money.pkr(amount),
    description: description,
    status: status,
    entryType: 'normal',
    flagCount: flagCount,
    isReversed: isReversed,
    isReversal: false,
    journalNumber: journalNumber,
    accountName: 'Winibex bank',
    categoryName: 'Rent',
    createdByName: 'Maryam',
  );
}

class _FakeRepository extends TransactionsRepository {
  _FakeRepository({List<TransactionSummary>? entries, this.failure})
      : entries = entries ?? [_entry()],
        super(dio: Dio());

  final List<TransactionSummary> entries;
  final Object? failure;

  LedgerQuery? lastQuery;
  int journalCalls = 0;

  @override
  Future<LedgerPage> ledger(LedgerQuery query) async {
    lastQuery = query;
    if (failure != null) throw failure!;

    return LedgerPage(
      transactions: entries,
      page: query.page,
      pageSize: 50,
      total: 120,
      hasMore: query.page * 50 < 120,
    );
  }

  @override
  Future<List<JournalLine>> journal(int id) async {
    journalCalls += 1;
    return const [
      JournalLine(
        coaId: 1,
        code: '6300',
        name: 'Rent',
        debit: Money.pkr(900000),
        credit: Money.pkr(0),
      ),
      JournalLine(
        coaId: 2,
        code: '1113',
        name: 'Bank',
        debit: Money.pkr(0),
        credit: Money.pkr(900000),
      ),
    ];
  }
}

Future<void> _pump(WidgetTester tester, _FakeRepository repository) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [transactionsRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: LedgerScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(LedgerScreen)));

void main() {
  testWidgets('entries are listed with what they were and where they sat', (tester) async {
    await _pump(tester, _FakeRepository());

    expect(find.text('Office rent July'), findsOneWidget);
    expect(find.text('2026-07-05'), findsOneWidget);
    expect(find.textContaining('Winibex bank'), findsOneWidget);
    expect(find.textContaining('JV-1'), findsOneWidget);
  });

  testWidgets('money out reads as negative, money in does not', (tester) async {
    await _pump(
      tester,
      _FakeRepository(entries: [
        _entry(id: 1, direction: 'out', amount: 900000),
        _entry(id: 2, direction: 'in', amount: 5000000, description: 'Client payment'),
      ],),
    );

    expect(find.text('-9,000.00'), findsOneWidget);
    expect(find.text('50,000.00'), findsOneWidget);
  });

  testWidgets('a reversed entry stays in the list, struck through', (tester) async {
    await _pump(
      tester,
      _FakeRepository(entries: [_entry(isReversed: true, status: 'reversed')]),
    );

    final text = tester.widget<Text>(find.text('Office rent July'));
    expect(
      text.style?.decoration,
      TextDecoration.lineThrough,
      reason: 'nothing leaves the book, so a reversal is shown rather than hidden',
    );
  });

  testWidgets('a draft or a waiting entry is tagged', (tester) async {
    await _pump(
      tester,
      _FakeRepository(entries: [
        _entry(id: 1, status: 'pending', journalNumber: null),
        _entry(id: 2, status: 'draft', journalNumber: null, description: 'Not sent yet'),
      ],),
    );

    final l10n = _l10n(tester);
    expect(find.text(l10n.statusPending), findsOneWidget);
    expect(find.text(l10n.statusDraft), findsOneWidget);
  });

  testWidgets('an entry with something to review carries a marker', (tester) async {
    await _pump(tester, _FakeRepository(entries: [_entry(flagCount: 2)]));
    expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
  });

  testWidgets('the count is the server total, not what is on screen', (tester) async {
    await _pump(tester, _FakeRepository());
    expect(find.textContaining('120'), findsOneWidget);
  });

  testWidgets('searching asks the server rather than filtering the page', (tester) async {
    final repository = _FakeRepository();
    await _pump(tester, repository);

    await tester.enterText(find.byType(TextField), 'rent');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(
      repository.lastQuery?.search,
      'rent',
      reason: 'the app holds one page, so searching it would miss everything else',
    );
  });

  testWidgets('paging asks for the next page and resets nothing else', (tester) async {
    final repository = _FakeRepository();
    await _pump(tester, repository);

    await tester.tap(find.text(_l10n(tester).actionNextPage));
    await tester.pumpAndSettle();

    expect(repository.lastQuery?.page, 2);
  });

  testWidgets('opening a posted entry shows its double entry', (tester) async {
    final repository = _FakeRepository();
    await _pump(tester, repository);

    await tester.tap(find.text('Office rent July'));
    await tester.pumpAndSettle();

    expect(repository.journalCalls, 1);
    expect(find.textContaining('6300'), findsOneWidget);
    expect(find.textContaining('1113'), findsOneWidget);
    expect(find.text('9,000.00'), findsNWidgets(2), reason: 'one debit and one credit');
  });

  testWidgets('a draft cannot be opened, because it has no journal yet', (tester) async {
    final repository = _FakeRepository(
      entries: [_entry(status: 'draft', journalNumber: null)],
    );
    await _pump(tester, repository);

    await tester.tap(find.text('Office rent July'));
    await tester.pumpAndSettle();

    expect(repository.journalCalls, 0);
  });

  testWidgets('nothing to show says so', (tester) async {
    await _pump(tester, _FakeRepository(entries: []));
    expect(find.text(_l10n(tester).emptyLedgerTitle), findsOneWidget);
  });

  testWidgets('a failure offers to try again', (tester) async {
    await _pump(
      tester,
      _FakeRepository(failure: const ApiException(code: 'NETWORK', message: 'no')),
    );

    expect(find.text(_l10n(tester).actionRetry), findsOneWidget);
  });
}
