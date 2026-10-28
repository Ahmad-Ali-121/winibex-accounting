// Batch C: moving money, paying people back, reversing, opening balances.
// Decision 065. The repositories are fakes; the real providers, dialogs and
// request bodies run.

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
import 'package:winibex_accounting/features/money/data/money_repository.dart';
import 'package:winibex_accounting/features/money/domain/money_moves.dart';
import 'package:winibex_accounting/features/money/presentation/opening_entry_screen.dart';
import 'package:winibex_accounting/features/transactions/data/transactions_repository.dart';
import 'package:winibex_accounting/features/transactions/domain/journal_preview.dart';
import 'package:winibex_accounting/features/transactions/domain/ledger.dart';
import 'package:winibex_accounting/features/transactions/presentation/widgets/journal_panel.dart';
import 'package:winibex_accounting/l10n/generated/app_localizations.dart';

Account _account(int id, String name, AccountType type, int balance) => Account(
      id: id,
      name: name,
      type: type,
      isActive: true,
      ledger: LedgerAccount(id: id, code: '111$id', name: name),
      balance: Money.pkr(balance),
    );

class _FakeAccounts extends AccountsRepository {
  _FakeAccounts({this.pettyLow = false}) : super(dio: Dio());
  final bool pettyLow;

  static final bank = _account(3, 'Winibex bank', AccountType.bank, 50000000);
  static final petty = _account(2, 'Petty cash', AccountType.pettyCash, 500000);

  @override
  Future<AccountsSummary> list({bool includeInactive = false}) async =>
      AccountsSummary(accounts: [bank, petty], total: const Money.pkr(50500000), historyMerged: false);

  @override
  Future<PettyCashStatus> pettyCash() async => PettyCashStatus(
        imprest: const Money.pkr(2000000),
        accounts: [
          PettyCashAccount(
            account: petty,
            belowFloat: pettyLow,
            suggestedTopUp: Money.pkr(pettyLow ? 1500000 : 0),
          ),
        ],
      );
}

class _FakeMoney extends MoneyRepository {
  _FakeMoney({this.warnFirst = false, this.opening}) : super(dio: Dio());

  bool warnFirst;
  OpeningInfo? opening;

  final List<Map<String, Object?>> transfers = [];
  final List<Map<String, Object?>> paybacks = [];
  final List<(int, String)> reversals = [];
  List<(String, Money)>? openingPosted;

  @override
  Future<List<String>> transfer({
    required String date,
    required int fromAccountId,
    required int toAccountId,
    required Money amount,
    Money? fee,
    String? description,
    List<String> acknowledged = const [],
    required String key,
  }) async {
    transfers.add({
      'from': fromAccountId,
      'to': toAccountId,
      'amount': amount.minorUnits,
      'fee': fee?.minorUnits,
      'acknowledged': acknowledged,
      'key': key,
    });
    if (warnFirst) {
      warnFirst = false;
      throw const ApiException(
        code: 'VALIDATION_WARNINGS',
        message: 'Check these.',
        status: 409,
        details: {
          'warnings': [
            {'code': 'BANK_BELOW_ZERO', 'message': 'Winibex bank would go below zero.'},
          ],
        },
      );
    }
    return ['JV-12', 'JV-13'];
  }

  @override
  Future<String> reverse({required int transactionId, required String reason, required String key}) async {
    reversals.add((transactionId, reason));
    return 'JV-20';
  }

  @override
  Future<List<PersonOwed>> peopleOwed() async =>
      const [PersonOwed(userId: 7, name: 'Fazal', owed: Money.pkr(595300))];

  @override
  Future<List<OwedCost>> owedCosts(int userId) async => const [
        OwedCost(
          transactionId: 31,
          journalNumber: 'JV-9',
          date: '2026-10-20',
          description: 'Claude subscription on Fazal card',
          remaining: Money.pkr(595300),
        ),
      ];

  @override
  Future<(String, Money)> payBack({
    required int personUserId,
    required int accountId,
    required String date,
    required List<(int, Money)> items,
    List<String> acknowledged = const [],
    required String key,
  }) async {
    paybacks.add({
      'person': personUserId,
      'account': accountId,
      'items': [for (final (id, amount) in items) (id, amount.minorUnits)],
    });
    return ('JV-14', Money.zero);
  }

  @override
  Future<OpeningInfo> openingInfo() async => opening!;

  @override
  Future<String> postOpening({
    required List<(String, Money)> balances,
    List<String> acknowledged = const [],
    required String key,
  }) async {
    openingPosted = balances;
    return 'JV-1';
  }
}

class _FakeTransactions extends TransactionsRepository {
  _FakeTransactions() : super(dio: Dio());

  @override
  Future<List<JournalLine>> journal(int id) async => const [
        JournalLine(coaId: 1, code: '6600', name: 'Office supplies', debit: Money.pkr(150000), credit: Money.pkr(0)),
        JournalLine(coaId: 2, code: '1113', name: 'Bank', debit: Money.pkr(0), credit: Money.pkr(150000)),
      ];
}

Future<void> _pump(WidgetTester tester, Widget home, {_FakeMoney? money, _FakeAccounts? accounts}) async {
  tester.view.physicalSize = const Size(1400, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        accountsRepositoryProvider.overrideWithValue(accounts ?? _FakeAccounts()),
        moneyRepositoryProvider.overrideWithValue(money ?? _FakeMoney()),
        transactionsRepositoryProvider.overrideWithValue(_FakeTransactions()),
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

Future<void> _pick(WidgetTester tester, String key, String label) async {
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Finder _moneyBox(String label) => find.widgetWithText(TextFormField, label);

void main() {
  // --- the accounts screen ---------------------------------------------------

  testWidgets('staff see the accounts, with no money actions', (tester) async {
    await _pump(tester, const AccountsScreen());
    expect(find.text(_l10n(tester).actionMoveMoney), findsNothing);
    expect(find.text(_l10n(tester).owedTitle), findsNothing);
  });

  testWidgets('the owner and admins see move money, pay back, and who is owed', (tester) async {
    await _pump(tester, const AccountsScreen(canMoveMoney: true));
    final l10n = _l10n(tester);

    expect(find.text(l10n.actionMoveMoney), findsOneWidget);
    expect(find.text(l10n.actionPaySomeoneBack), findsOneWidget);
    expect(find.text(l10n.actionOpeningBalances), findsNothing, reason: 'the owner only');
    expect(find.text(l10n.owedTitle), findsOneWidget);
    expect(find.text('Fazal'), findsOneWidget);
  });

  testWidgets('petty cash below its float offers a top-up of the server figure', (tester) async {
    final money = _FakeMoney();
    await _pump(tester, const AccountsScreen(canMoveMoney: true), money: money, accounts: _FakeAccounts(pettyLow: true));
    final l10n = _l10n(tester);

    expect(find.text(l10n.actionTopUp), findsOneWidget);
    await tester.tap(find.text(l10n.actionTopUp));
    await tester.pumpAndSettle();

    expect(find.text(l10n.moveMoneyTitle), findsOneWidget);
    await _pick(tester, 'move-from', 'Winibex bank');
    await tester.tap(find.widgetWithText(FilledButton, l10n.actionMoveMoney).last);
    await tester.pumpAndSettle();

    expect(money.transfers.single['to'], 2, reason: 'to petty cash');
    expect(money.transfers.single['amount'], 1500000, reason: 'the suggested top-up, as the server gave it');
  });

  // --- moving money ---------------------------------------------------------------

  testWidgets('moving money sends both accounts, the amount and the fee', (tester) async {
    final money = _FakeMoney();
    await _pump(tester, const AccountsScreen(canMoveMoney: true), money: money);
    final l10n = _l10n(tester);

    await tester.tap(find.text(l10n.actionMoveMoney));
    await tester.pumpAndSettle();
    await _pick(tester, 'move-from', 'Winibex bank');
    await _pick(tester, 'move-to', 'Petty cash');
    await tester.enterText(_moneyBox(l10n.fieldAmount), '20000');
    await tester.enterText(_moneyBox(l10n.fieldTransferFee), '50');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, l10n.actionMoveMoney).last);
    await tester.pumpAndSettle();

    final sent = money.transfers.single;
    expect(sent['from'], 3);
    expect(sent['to'], 2);
    expect(sent['amount'], 2000000);
    expect(sent['fee'], 5000);
    expect(find.text(l10n.moveMoneyDone('JV-12, JV-13')), findsOneWidget);
  });

  testWidgets('the same account on both sides cannot be sent', (tester) async {
    await _pump(tester, const AccountsScreen(canMoveMoney: true));
    final l10n = _l10n(tester);

    await tester.tap(find.text(l10n.actionMoveMoney));
    await tester.pumpAndSettle();
    await _pick(tester, 'move-from', 'Winibex bank');
    await _pick(tester, 'move-to', 'Winibex bank');
    await tester.enterText(_moneyBox(l10n.fieldAmount), '100');
    await tester.pumpAndSettle();

    expect(find.text(l10n.moveMoneySameAccount), findsOneWidget);
    final button = tester.widget<FilledButton>(find.widgetWithText(FilledButton, l10n.actionMoveMoney).last);
    expect(button.onPressed, isNull);
  });

  testWidgets('a warning is shown, and going ahead sends it again under the same key', (tester) async {
    final money = _FakeMoney(warnFirst: true);
    await _pump(tester, const AccountsScreen(canMoveMoney: true), money: money);
    final l10n = _l10n(tester);

    await tester.tap(find.text(l10n.actionMoveMoney));
    await tester.pumpAndSettle();
    await _pick(tester, 'move-from', 'Winibex bank');
    await _pick(tester, 'move-to', 'Petty cash');
    await tester.enterText(_moneyBox(l10n.fieldAmount), '20000');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, l10n.actionMoveMoney).last);
    await tester.pumpAndSettle();

    expect(find.textContaining('below zero'), findsOneWidget);
    await tester.tap(find.text('Save anyway'));
    await tester.pumpAndSettle();

    expect(money.transfers.length, 2);
    expect(money.transfers[1]['acknowledged'], ['BANK_BELOW_ZERO']);
    expect(money.transfers[1]['key'], money.transfers[0]['key'], reason: 'a retry, not a second transfer');
  });

  // --- paying back ----------------------------------------------------------------

  testWidgets('paying back sends the ticked cost in full, from the chosen account', (tester) async {
    final money = _FakeMoney();
    await _pump(tester, const AccountsScreen(canMoveMoney: true), money: money);
    final l10n = _l10n(tester);

    await tester.tap(find.widgetWithText(TextButton, l10n.actionPayBack));
    await tester.pumpAndSettle();

    expect(find.text('Claude subscription on Fazal card'), findsOneWidget);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await _pick(tester, 'pay-from', 'Winibex bank');
    await tester.tap(find.widgetWithText(FilledButton, l10n.actionPayBack));
    await tester.pumpAndSettle();

    final sent = money.paybacks.single;
    expect(sent['person'], 7);
    expect(sent['account'], 3);
    expect(sent['items'], [(31, 595300)]);
  });

  // --- reversing ------------------------------------------------------------------

  TransactionSummary entry({String status = 'posted', String type = 'normal', bool isReversal = false}) =>
      TransactionSummary(
        id: 55,
        date: '2026-10-20',
        direction: 'out',
        amount: const Money.pkr(150000),
        description: 'Printer paper',
        status: status,
        entryType: type,
        flagCount: 0,
        isReversed: status == 'reversed',
        isReversal: isReversal,
        journalNumber: 'JV-19',
      );

  Future<void> openPanel(WidgetTester tester) async {
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Widget opener(TransactionSummary summary, {bool canReverse = true}) => Builder(
        builder: (context) => TextButton(
          onPressed: () => showJournalPanel(context, summary, canReverse: canReverse),
          child: const Text('open'),
        ),
      );

  testWidgets('a posted entry can be reversed, with a reason', (tester) async {
    final money = _FakeMoney();
    await _pump(tester, opener(entry()), money: money);
    await openPanel(tester);
    final l10n = _l10n(tester);

    await tester.tap(find.text(l10n.actionReverse));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Entered twice');
    await tester.tap(find.widgetWithText(FilledButton, l10n.actionReverse));
    await tester.pumpAndSettle();

    expect(money.reversals, [(55, 'Entered twice')]);
    expect(find.text(l10n.reverseDone('JV-20')), findsOneWidget);
  });

  testWidgets('no reverse button for staff, a reversal, or the opening entry', (tester) async {
    await _pump(tester, opener(entry(), canReverse: false));
    await openPanel(tester);
    expect(find.text(_l10n(tester).actionReverse), findsNothing, reason: 'staff');
  });

  testWidgets('the opening entry is not offered for reversal', (tester) async {
    await _pump(tester, opener(entry(type: 'opening')));
    await openPanel(tester);
    expect(find.text(_l10n(tester).actionReverse), findsNothing);
  });

  testWidgets('a reversal is not offered for reversal', (tester) async {
    await _pump(tester, opener(entry(isReversal: true)));
    await openPanel(tester);
    expect(find.text(_l10n(tester).actionReverse), findsNothing);
  });

  // --- opening balances -------------------------------------------------------------

  const accountsToOpen = [
    OpeningAccount(code: '1111', name: 'Cash in hand, office', type: 'asset'),
    OpeningAccount(code: '1113', name: 'Bank', type: 'asset'),
    OpeningAccount(code: '2210', name: 'Loan from director', type: 'liability'),
    OpeningAccount(code: '3100', name: 'Share capital', type: 'equity'),
  ];

  testWidgets('the owner types the balances, reviews them, and only filled ones are sent', (tester) async {
    final money = _FakeMoney(
      opening: const OpeningInfo(booksLiveFrom: '2026-07-01', balancesAt: '2026-06-30', accounts: accountsToOpen),
    );
    await _pump(tester, const OpeningEntryScreen(isOwner: true), money: money);
    final l10n = _l10n(tester);

    expect(find.text(l10n.openingAssets), findsOneWidget);
    expect(find.text(l10n.openingLiabilities), findsOneWidget);

    Finder box(String code) =>
        find.descendant(of: find.byKey(ValueKey('opening-$code')), matching: find.byType(EditableText));
    await tester.enterText(box('1113'), '500000');
    await tester.enterText(box('2210'), '300000');
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.actionReviewOpening));
    await tester.pumpAndSettle();
    expect(find.text(l10n.openingReviewTitle), findsOneWidget);
    await tester.tap(find.text(l10n.actionPostOpening));
    await tester.pumpAndSettle();

    expect(money.openingPosted!.map((line) => (line.$1, line.$2.minorUnits)).toList(), [
      ('1113', 50000000),
      ('2210', 30000000),
    ]);
  });

  testWidgets('once posted, the opening entry is shown read only', (tester) async {
    final money = _FakeMoney(
      opening: const OpeningInfo(
        booksLiveFrom: '2026-07-01',
        balancesAt: '2026-06-30',
        accounts: accountsToOpen,
        entry: OpeningEntryView(
          transactionId: 1,
          journalNumber: 'JV-1',
          status: 'posted',
          lines: [
            OpeningLine(code: '1113', name: 'Bank', debit: Money.pkr(50000000), credit: Money.pkr(0)),
            OpeningLine(code: '3400', name: 'Opening balance equity', debit: Money.pkr(0), credit: Money.pkr(50000000)),
          ],
        ),
      ),
    );
    await _pump(tester, const OpeningEntryScreen(isOwner: true), money: money);
    final l10n = _l10n(tester);

    expect(find.text(l10n.openingPosted('JV-1', '2026-07-01')), findsOneWidget);
    expect(find.text('3400  Opening balance equity'), findsOneWidget);
    expect(find.text(l10n.actionReviewOpening), findsNothing);
  });

  testWidgets('an admin sees the opening balances screen but cannot post', (tester) async {
    await _pump(
      tester,
      const OpeningEntryScreen(),
      money: _FakeMoney(
        opening: const OpeningInfo(booksLiveFrom: '2026-07-01', balancesAt: '2026-06-30', accounts: accountsToOpen),
      ),
    );
    expect(find.text(_l10n(tester).openingOwnerOnly), findsOneWidget);
  });
}
