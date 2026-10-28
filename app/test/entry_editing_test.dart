// Fixing an entry that is not in the books yet. Decision 067.
//
//   - a draft opened from the server is edited, never created again
//   - one sent back shows why, above the form
//   - from the ledger: Edit a draft, take back a submitted one, fix a
//     rejected one; the server's refusal is shown in its words

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
import 'package:winibex_accounting/features/transactions/data/transactions_repository.dart';
import 'package:winibex_accounting/features/transactions/domain/category.dart';
import 'package:winibex_accounting/features/transactions/domain/entry_draft.dart';
import 'package:winibex_accounting/features/transactions/domain/journal_preview.dart';
import 'package:winibex_accounting/features/transactions/domain/ledger.dart';
import 'package:winibex_accounting/features/transactions/domain/person.dart';
import 'package:winibex_accounting/features/transactions/presentation/entry_screen.dart';
import 'package:winibex_accounting/features/transactions/presentation/ledger_screen.dart';
import 'package:winibex_accounting/l10n/generated/app_localizations.dart';

class _FakeAccounts extends AccountsRepository {
  _FakeAccounts() : super(dio: Dio());

  @override
  Future<AccountsSummary> list({bool includeInactive = false}) async => const AccountsSummary(
        accounts: [
          Account(
            id: 1,
            name: 'Winibex bank',
            type: AccountType.bank,
            isActive: true,
            ledger: LedgerAccount(id: 10, code: '1113', name: 'Bank'),
            balance: Money.pkr(50000000),
          ),
        ],
        total: Money.pkr(50000000),
        historyMerged: false,
      );
}

TransactionSummary _row(int id, String status, String description) => TransactionSummary(
      id: id,
      date: '2026-10-20',
      direction: 'out',
      amount: const Money.pkr(120000),
      description: description,
      status: status,
      entryType: 'normal',
      flagCount: 0,
      isReversed: false,
      isReversal: false,
      accountName: 'Winibex bank',
    );

class _FakeTransactions extends TransactionsRepository {
  _FakeTransactions({this.reopenFails}) : super(dio: Dio());

  final ApiException? reopenFails;
  int creates = 0;
  final List<int> updated = [];
  final List<int> submitted = [];
  final List<int> reopened = [];

  @override
  Future<List<CategoryGroup>> categories({String? direction}) async => const [
        CategoryGroup(mainHead: 'admin', categories: [
          Category(
            id: 7,
            name: 'Travelling and conveyance',
            mainHead: 'admin',
            direction: 'out',
            ledgerCode: '6500',
            ledgerName: 'Travelling and conveyance',
          ),
        ],),
      ];

  @override
  Future<List<Person>> people() async => const [];

  @override
  Future<JournalPreview> preview(EntryDraft draft) async => const JournalPreview(
        lines: [
          JournalLine(coaId: 65, code: '6500', name: 'Travel', debit: Money.pkr(120000), credit: Money.pkr(0)),
          JournalLine(coaId: 10, code: '1113', name: 'Bank', debit: Money.pkr(0), credit: Money.pkr(120000)),
        ],
        totals: PreviewTotals(
          gross: Money.pkr(120000),
          taxTotal: Money.pkr(0),
          chargesTotal: Money.pkr(0),
          withheldTotal: Money.pkr(0),
          amount: Money.pkr(120000),
        ),
      );

  @override
  Future<EntryDraft> openDraft(int id, {required String idempotencyKey}) async => EntryDraft(
        idempotencyKey: idempotencyKey,
        existingId: id,
        sentBackReason: 'Say where the taxi went',
        date: '2026-10-20',
        accountId: 1,
        pkrAmount: const Money.pkr(120000),
        categoryId: 7,
        description: 'Taxi',
        taxesChecked: true,
      );

  @override
  Future<int> create(EntryDraft draft) async {
    creates += 1;
    return 99;
  }

  @override
  Future<void> update(int id, EntryDraft draft) async => updated.add(id);

  @override
  Future<void> submit(int id) async => submitted.add(id);

  @override
  Future<void> reopen(int id) async {
    if (reopenFails != null) throw reopenFails!;
    reopened.add(id);
  }

  @override
  Future<LedgerPage> ledger(LedgerQuery query) async => LedgerPage(
        transactions: [_row(5, 'draft', 'Lunch draft'), _row(6, 'pending', 'Courier'), _row(8, 'rejected', 'Taxi')],
        page: 1,
        pageSize: 50,
        total: 3,
        hasMore: false,
      );
}

Future<void> _pump(WidgetTester tester, Widget home, _FakeTransactions transactions) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        accountsRepositoryProvider.overrideWithValue(_FakeAccounts()),
        transactionsRepositoryProvider.overrideWithValue(transactions),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: home),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

AppLocalizations _l10n(WidgetTester tester) => AppLocalizations.of(tester.element(find.byType(Scaffold).first));

void main() {
  testWidgets('a sent-back entry opens with why, and saving edits it rather than creating another', (tester) async {
    final transactions = _FakeTransactions();
    var done = false;
    await _pump(tester, EntryScreen(editId: 8, onEditDone: () => done = true), transactions);
    final l10n = _l10n(tester);

    expect(find.text(l10n.fixingSentBack), findsOneWidget);
    expect(find.text(l10n.fixingReason('Say where the taxi went')), findsOneWidget);

    // Walk to the review step: every step is already answered.
    for (var step = 0; step < 6; step += 1) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Submit for approval'));
    await tester.pumpAndSettle();

    expect(transactions.creates, 0, reason: 'no second entry');
    expect(transactions.updated, [8], reason: 'the same draft was changed');
    expect(transactions.submitted, [8]);
    expect(done, isTrue, reason: 'the form is left once it is saved');
  });

  testWidgets('a draft in the ledger opens straight in the form', (tester) async {
    final transactions = _FakeTransactions();
    int? opened;
    await _pump(tester, LedgerScreen(onEdit: (id) => opened = id), transactions);
    final l10n = _l10n(tester);

    await tester.tap(find.text('Lunch draft'));
    await tester.pumpAndSettle();
    expect(find.text(l10n.entryDraftExplain), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, l10n.actionEdit));
    await tester.pumpAndSettle();

    expect(transactions.reopened, isEmpty, reason: 'a draft needs no reopening');
    expect(opened, 5);
  });

  testWidgets('a submitted entry is taken back, then opened', (tester) async {
    final transactions = _FakeTransactions();
    int? opened;
    await _pump(tester, LedgerScreen(onEdit: (id) => opened = id), transactions);
    final l10n = _l10n(tester);

    await tester.tap(find.text('Courier'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.actionTakeBack));
    await tester.pumpAndSettle();

    expect(transactions.reopened, [6]);
    expect(opened, 6);
  });

  testWidgets('a rejected entry is fixed and sent again from the ledger', (tester) async {
    final transactions = _FakeTransactions();
    int? opened;
    await _pump(tester, LedgerScreen(onEdit: (id) => opened = id), transactions);
    final l10n = _l10n(tester);

    await tester.tap(find.text('Taxi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.actionFixAndResend));
    await tester.pumpAndSettle();

    expect(transactions.reopened, [8]);
    expect(opened, 8);
  });

  testWidgets('when the server says no, the reason is shown and nothing opens', (tester) async {
    const reason = 'Only the person who sent it can take it back. An approver can reject it instead, with a reason.';
    final transactions = _FakeTransactions(
      reopenFails: const ApiException(code: 'FORBIDDEN', message: reason, status: 403),
    );
    int? opened;
    await _pump(tester, LedgerScreen(onEdit: (id) => opened = id), transactions);

    await tester.tap(find.text('Courier'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_l10n(tester).actionTakeBack));
    await tester.pumpAndSettle();

    expect(find.text(reason), findsOneWidget);
    expect(opened, isNull);
  });
}
