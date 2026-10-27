// The guided entry form.
//
// The repositories are replaced, so the real providers, the real draft, the
// real request body and the real widgets all run. Only the network does not.
//
// The two that matter most are at the bottom: the warnings dialog, and what is
// actually sent when the person confirms.

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
import 'package:winibex_accounting/features/transactions/domain/person.dart';
import 'package:winibex_accounting/features/transactions/presentation/entry_screen.dart';
import 'package:winibex_accounting/l10n/generated/app_localizations.dart';

class _FakeAccountsRepository extends AccountsRepository {
  _FakeAccountsRepository() : super(dio: Dio());

  @override
  Future<AccountsSummary> list({bool includeInactive = false}) async {
    return const AccountsSummary(
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
}

class _FakeTransactionsRepository extends TransactionsRepository {
  _FakeTransactionsRepository({this.createFails, this.approveFails}) : super(dio: Dio());

  /// Thrown on the first create only, so the second call can succeed and the
  /// test can check what the retry actually sent.
  ApiException? createFails;

  /// Thrown on the first approve only: the entry was created, then refused at
  /// posting, as a large payment with no receipt is.
  ApiException? approveFails;

  EntryDraft? lastCreated;
  int createCalls = 0;
  int approveCalls = 0;

  /// Every draft edit, in order, with the id it was sent to.
  final List<(int, EntryDraft)> updates = [];

  /// The id of every approve, in order.
  final List<int> approvedIds = [];

  /// The idempotency key of every create, in order.
  final List<String> createdKeys = [];

  @override
  Future<List<CategoryGroup>> categories({String? direction}) async {
    return [
      const CategoryGroup(
        mainHead: 'admin',
        categories: [
          Category(
            id: 7,
            name: 'Software subscriptions',
            mainHead: 'admin',
            direction: 'out',
            ledgerCode: '6400',
            ledgerName: 'Software subscriptions',
          ),
        ],
      ),
    ];
  }

  @override
  Future<List<Person>> people() async =>
      const [Person(id: 3, name: 'Ahmad', role: 'staff')];

  @override
  Future<JournalPreview> preview(EntryDraft draft) async {
    return const JournalPreview(
      lines: [
        JournalLine(
          coaId: 20,
          code: '6400',
          name: 'Software subscriptions',
          debit: Money.pkr(560000),
          credit: Money.pkr(0),
        ),
        JournalLine(
          coaId: 10,
          code: '1113',
          name: 'Bank',
          debit: Money.pkr(0),
          credit: Money.pkr(560000),
        ),
      ],
      totals: PreviewTotals(
        gross: Money.pkr(560000),
        taxTotal: Money.pkr(0),
        chargesTotal: Money.pkr(0),
        withheldTotal: Money.pkr(0),
        amount: Money.pkr(560000),
      ),
    );
  }

  @override
  Future<int> create(EntryDraft draft) async {
    createCalls += 1;
    lastCreated = draft;
    createdKeys.add(draft.idempotencyKey);

    final failure = createFails;
    if (failure != null) {
      createFails = null;
      throw failure;
    }
    return 42;
  }

  @override
  Future<void> update(int id, EntryDraft draft) async {
    updates.add((id, draft));
  }

  @override
  Future<void> approve(int id, String idempotencyKey) async {
    approveCalls += 1;
    approvedIds.add(id);
    final failure = approveFails;
    if (failure != null) {
      approveFails = null;
      throw failure;
    }
  }

  @override
  Future<void> submit(int id) async {}
}

Future<void> _pump(
  WidgetTester tester, {
  required _FakeTransactionsRepository transactions,
  bool canPost = true,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        accountsRepositoryProvider.overrideWithValue(_FakeAccountsRepository()),
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
        home: Scaffold(body: EntryScreen(canPost: canPost)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Walks the form to the review step with a 5,600 subscription.
Future<void> _fillIn(WidgetTester tester) async {
  // Step 1: direction and date. Money out is the default.
  await tester.tap(find.text('Next'));
  await tester.pumpAndSettle();

  // Step 2: amount.
  await tester.enterText(find.byType(TextFormField).first, '5600');
  await tester.pumpAndSettle();
  await tester.tap(find.text('Next'));
  await tester.pumpAndSettle();

  // Step 3: which account.
  await tester.tap(find.text('Winibex bank'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Next'));
  await tester.pumpAndSettle();

  // Step 4: category and description.
  await tester.tap(find.byType(DropdownButtonFormField<int>));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Software subscriptions  6400').last);
  await tester.pumpAndSettle();

  await tester.enterText(find.byType(TextFormField).last, 'Claude subscription');
  await tester.pumpAndSettle();
  await tester.tap(find.text('Next'));
  await tester.pumpAndSettle();

  // Step 5: the receipt. Walked past without attaching one, which the step
  // allows on purpose: the photo is often taken later, and the server refuses
  // the posting if the payment is above the threshold without it.
  await tester.tap(find.text('Next'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('rupees typed by a person become paisa, with no double in between', (tester) async {
    expect(parseMinorUnits('5600'), 560000);
    expect(parseMinorUnits('5,953.50'), 595350);
    expect(parseMinorUnits('0.05'), 5);
    expect(parseMinorUnits('5953.5'), 595350);
    expect(parseMinorUnits(''), 0);
  });

  testWidgets('the form asks one thing at a time', (tester) async {
    await _pump(tester, transactions: _FakeTransactionsRepository());

    expect(find.text('Did money come in, or go out?'), findsOneWidget);
    expect(find.text('How much?'), findsNothing);
    expect(find.text('Step 1 of 6'), findsOneWidget);
  });

  testWidgets('an exchange rate box only appears for a foreign entry', (tester) async {
    await _pump(tester, transactions: _FakeTransactionsRepository());

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Exchange rate'), findsNothing);

    await tester.tap(find.text('Foreign currency'));
    await tester.pumpAndSettle();

    expect(find.text('Exchange rate'), findsOneWidget);
    expect(find.text('Rupees actually received'), findsOneWidget);
  });

  testWidgets('the next step is refused until the step is answered', (tester) async {
    await _pump(tester, transactions: _FakeTransactionsRepository());

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // No amount yet.
    final next = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Next'));
    expect(next.onPressed, isNull);
  });

  testWidgets('the account picker shows what each account holds', (tester) async {
    await _pump(tester, transactions: _FakeTransactionsRepository());

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '5600');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Winibex bank'), findsOneWidget);
    expect(find.text('500,000.00'), findsOneWidget);
    expect(find.text('Or someone paid it personally'), findsOneWidget);
    expect(find.text('Ahmad'), findsOneWidget);
  });

  testWidgets('the review step shows the journal the server would post', (tester) async {
    await _pump(tester, transactions: _FakeTransactionsRepository());
    await _fillIn(tester);

    expect(find.text('Check this before saving'), findsOneWidget);
    expect(find.textContaining('6400'), findsWidgets);
    expect(find.textContaining('1113'), findsWidgets);
    expect(find.text('Balanced'), findsOneWidget);
    expect(find.text('5,600.00'), findsWidgets);
  });

  testWidgets('the button says post or submit depending on who is entering', (tester) async {
    await _pump(tester, transactions: _FakeTransactionsRepository(), canPost: false);
    await _fillIn(tester);

    expect(find.text('Submit for approval'), findsOneWidget);
    expect(find.text('Save and post'), findsNothing);
  });

  testWidgets('warnings are shown with what they matched, not just a code', (tester) async {
    final repository = _FakeTransactionsRepository(
      createFails: const ApiException(
        code: 'VALIDATION_WARNINGS',
        message: 'Check these before saving.',
        status: 409,
        details: {
          'warnings': [
            {
              'code': 'POSSIBLE_DUPLICATE',
              'message': 'Same amount on the same account as JV-0042, 2026-07-03, Office rent.',
              'transactionId': 42,
            },
          ],
        },
      ),
    );

    await _pump(tester, transactions: repository);
    await _fillIn(tester);

    await tester.tap(find.text('Save and post'));
    await tester.pumpAndSettle();

    expect(find.text('Check these first'), findsOneWidget);
    expect(find.textContaining('JV-0042'), findsOneWidget);
    expect(find.text('Save anyway'), findsOneWidget);
    expect(find.text('Go back and check'), findsOneWidget);
  });

  testWidgets('confirming sends the same entry back with the warning acknowledged', (tester) async {
    final repository = _FakeTransactionsRepository(
      createFails: const ApiException(
        code: 'VALIDATION_WARNINGS',
        message: 'Check these before saving.',
        status: 409,
        details: {
          'warnings': [
            {'code': 'POSSIBLE_DUPLICATE', 'message': 'Same amount as JV-0042.'},
          ],
        },
      ),
    );

    await _pump(tester, transactions: repository);
    await _fillIn(tester);

    await tester.tap(find.text('Save and post'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save anyway'));
    await tester.pumpAndSettle();

    expect(repository.createCalls, 2, reason: 'the entry was sent again rather than retyped');

    final sent = repository.lastCreated!;
    expect(sent.acknowledgedWarnings, contains('POSSIBLE_DUPLICATE'));

    final body = sent.toRequest();
    expect(body['acknowledged_warnings'], contains('POSSIBLE_DUPLICATE'));
    expect(body['gross'], {'minor': 560000, 'currency': 'PKR'});
    expect(body['direction'], 'out');
  });

  testWidgets('the idempotency key does not change between the two attempts', (tester) async {
    final repository = _FakeTransactionsRepository(
      createFails: const ApiException(
        code: 'VALIDATION_WARNINGS',
        message: 'Check these.',
        status: 409,
        details: {
          'warnings': [
            {'code': 'BACKDATED', 'message': 'That is 120 days ago.'},
          ],
        },
      ),
    );

    await _pump(tester, transactions: repository);
    await _fillIn(tester);

    await tester.tap(find.text('Save and post'));
    await tester.pumpAndSettle();
    final firstKey = repository.lastCreated!.idempotencyKey;

    await tester.tap(find.text('Save anyway'));
    await tester.pumpAndSettle();

    expect(
      repository.lastCreated!.idempotencyKey,
      firstKey,
      reason: 'a new key on the retry would let the same expense post twice',
    );
  });

  testWidgets('going back from the warnings dialog saves nothing', (tester) async {
    final repository = _FakeTransactionsRepository(
      createFails: const ApiException(
        code: 'VALIDATION_WARNINGS',
        message: 'Check these.',
        status: 409,
        details: {
          'warnings': [
            {'code': 'UNUSUAL_AMOUNT', 'message': 'More than three times the usual.'},
          ],
        },
      ),
    );

    await _pump(tester, transactions: repository);
    await _fillIn(tester);

    await tester.tap(find.text('Save and post'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Go back and check'));
    await tester.pumpAndSettle();

    expect(repository.createCalls, 1, reason: 'it was sent once and refused, and not sent again');
  });

  // -------------------------------------------------------------------------
  // Defect D3: a refusal is shown, not swallowed
  // -------------------------------------------------------------------------

  testWidgets('a refused save shows the server reason above the button', (tester) async {
    const reason = 'That leaves petty cash below zero. It holds PKR 9,700 today.';
    final repository = _FakeTransactionsRepository(
      createFails: const ApiException(code: 'CASH_BELOW_ZERO', message: reason, status: 400),
    );

    await _pump(tester, transactions: repository);
    await _fillIn(tester);

    await tester.tap(find.text('Save and post'));
    await tester.pumpAndSettle();

    expect(find.text(reason), findsOneWidget);
    expect(find.text('Check this before saving'), findsOneWidget, reason: 'still on the review step');
    expect(repository.createCalls, 1);
  });

  testWidgets('a posting refused after creation says why, and the retry posts the same draft', (tester) async {
    const reason = 'A payment of this size needs a receipt attached before it can be posted.';
    final repository = _FakeTransactionsRepository(
      approveFails: const ApiException(code: 'RECEIPT_REQUIRED', message: reason, status: 400),
    );

    await _pump(tester, transactions: repository);
    await _fillIn(tester);

    await tester.tap(find.text('Save and post'));
    await tester.pumpAndSettle();
    expect(find.text(reason), findsOneWidget);

    await tester.tap(find.text('Save and post'));
    await tester.pumpAndSettle();

    expect(repository.createCalls, 1, reason: 'the draft exists, so it is not created again');
    expect(repository.updates, isEmpty, reason: 'nothing changed, so nothing is edited');
    expect(repository.approvedIds, [42, 42], reason: 'the same draft is posted, not a second one');
    expect(find.text('Saved and posted.'), findsOneWidget);
  });

  // -------------------------------------------------------------------------
  // Defect F7: a changed entry after a refusal posts what the screen shows
  // -------------------------------------------------------------------------

  testWidgets('a refused posting, then a changed amount, posts the changed amount on the same draft', (tester) async {
    const reason = 'A payment of this size needs a receipt attached before it can be posted.';
    final repository = _FakeTransactionsRepository(
      approveFails: const ApiException(code: 'RECEIPT_REQUIRED', message: reason, status: 400),
    );

    await _pump(tester, transactions: repository);
    await _fillIn(tester);

    await tester.tap(find.text('Save and post'));
    await tester.pumpAndSettle();
    expect(find.text(reason), findsOneWidget);

    // Back from the review step to the amount, the way a person would.
    for (var step = 0; step < 4; step += 1) {
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Step 2 of 6'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, '6500');
    await tester.pumpAndSettle();
    for (var step = 0; step < 4; step += 1) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.text('Save and post'));
    await tester.pumpAndSettle();

    expect(repository.createCalls, 1, reason: 'no second draft');
    expect(repository.updates.length, 1, reason: 'the existing draft was edited');
    final (editedId, edited) = repository.updates.single;
    expect(editedId, 42);
    expect(edited.toRequest()['gross'], {'minor': 650000, 'currency': 'PKR'});
    expect(repository.approvedIds, [42, 42], reason: 'the edited draft is the one posted');
    expect(find.text('Saved and posted.'), findsOneWidget);
  });

  testWidgets('no connection says the entry is kept, in the app own words', (tester) async {
    final repository = _FakeTransactionsRepository(
      createFails: const ApiException(code: 'NETWORK', message: 'Could not reach the server.'),
    );

    await _pump(tester, transactions: repository);
    await _fillIn(tester);

    await tester.tap(find.text('Save and post'));
    await tester.pumpAndSettle();

    expect(
      find.text('Could not reach the server. Your entry is kept. Try again when connected.'),
      findsOneWidget,
    );
  });

  // -------------------------------------------------------------------------
  // Defect D10: after a save the form starts again
  // -------------------------------------------------------------------------

  testWidgets('after a save the form starts again, empty, with a new key', (tester) async {
    final repository = _FakeTransactionsRepository();

    await _pump(tester, transactions: repository);
    await _fillIn(tester);
    await tester.tap(find.text('Save and post'));
    await tester.pumpAndSettle();

    expect(find.text('Step 1 of 6'), findsOneWidget);
    expect(find.text('Did money come in, or go out?'), findsOneWidget);

    await _fillIn(tester);
    await tester.tap(find.text('Save and post'));
    await tester.pumpAndSettle();

    expect(repository.createdKeys.length, 2);
    expect(
      repository.createdKeys[1],
      isNot(repository.createdKeys[0]),
      reason: 'a new entry needs a new key, or the server refuses it as a reused one',
    );
  });
}
