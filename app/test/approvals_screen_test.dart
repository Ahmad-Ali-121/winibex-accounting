// The approval inbox.
//
// The rule it exists to enforce is decision 036: nobody approves their own
// entry under the same login. The inbox says so on the row rather than letting
// someone press approve and collect a 403.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:winibex_accounting/core/money/money.dart';
import 'package:winibex_accounting/core/theme/app_theme.dart';
import 'package:winibex_accounting/features/transactions/data/transactions_repository.dart';
import 'package:winibex_accounting/features/transactions/domain/ledger.dart';
import 'package:winibex_accounting/features/transactions/presentation/approvals_screen.dart';
import 'package:winibex_accounting/l10n/generated/app_localizations.dart';

Approval _approval({
  int id = 1,
  String description = 'Office rent July',
  int amount = 900000,
  bool isOwnEntry = false,
  int flagCount = 0,
}) {
  return Approval(
    summary: TransactionSummary(
      id: id,
      date: '2026-07-05',
      direction: 'out',
      amount: Money.pkr(amount),
      description: description,
      status: 'pending',
      entryType: 'normal',
      flagCount: flagCount,
      isReversed: false,
      isReversal: false,
      accountName: 'Winibex bank',
      categoryName: 'Rent',
      createdByName: 'Maryam',
    ),
    createdBy: 3,
    isOwnEntry: isOwnEntry,
    submittedAt: '2026-07-05T09:00:00Z',
  );
}

class _FakeRepository extends TransactionsRepository {
  _FakeRepository({List<Approval>? waiting})
      : waiting = waiting ?? [_approval()],
        super(dio: Dio());

  final List<Approval> waiting;

  int? approved;
  int? rejected;
  String? rejectReason;

  @override
  Future<List<Approval>> approvals() async => waiting;

  @override
  Future<void> approve(int id, String idempotencyKey) async => approved = id;

  @override
  Future<void> reject(int id, String reason) async {
    rejected = id;
    rejectReason = reason;
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
        home: const Scaffold(body: ApprovalsScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The wording comes from app_en.arb and is Ahmad's to change. Reading it from
/// the tree keeps these tests about what the screen does rather than about the
/// exact words it uses.
AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(ApprovalsScreen)));

void main() {
  testWidgets('what is waiting is listed with who entered it', (tester) async {
    await _pump(tester, _FakeRepository());
    final l10n = _l10n(tester);

    expect(find.text('Office rent July'), findsOneWidget);
    expect(find.textContaining('Maryam'), findsOneWidget);
    expect(find.text('-9,000.00'), findsOneWidget);
    expect(find.text(l10n.actionApprove), findsOneWidget);
  });

  testWidgets('your own entry offers no buttons, and says why', (tester) async {
    await _pump(tester, _FakeRepository(waiting: [_approval(isOwnEntry: true)]));
    final l10n = _l10n(tester);

    expect(find.text(l10n.actionApprove), findsNothing);
    expect(find.text(l10n.actionReject), findsNothing);
    expect(find.text(l10n.approvalsYourOwn), findsOneWidget);
  });

  testWidgets('an entry with flags shows how many', (tester) async {
    await _pump(tester, _FakeRepository(waiting: [_approval(flagCount: 2)]));
    expect(find.text(_l10n(tester).approvalsHasFlags(2)), findsOneWidget);
  });

  testWidgets('approving posts it', (tester) async {
    final repository = _FakeRepository(waiting: [_approval(id: 7)]);
    await _pump(tester, repository);

    await tester.tap(find.text(_l10n(tester).actionApprove));
    await tester.pumpAndSettle();

    expect(repository.approved, 7);
  });

  testWidgets('rejecting asks for a reason and sends it', (tester) async {
    final repository = _FakeRepository(waiting: [_approval(id: 9)]);
    await _pump(tester, repository);
    final l10n = _l10n(tester);

    await tester.tap(find.text(l10n.actionReject));
    await tester.pumpAndSettle();

    expect(find.text(l10n.rejectTitle), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Wrong account, should be petty cash');
    await tester.tap(find.widgetWithText(FilledButton, l10n.actionReject));
    await tester.pumpAndSettle();

    expect(repository.rejected, 9);
    expect(repository.rejectReason, 'Wrong account, should be petty cash');
  });

  testWidgets('rejecting with no reason sends nothing', (tester) async {
    final repository = _FakeRepository(waiting: [_approval(id: 9)]);
    await _pump(tester, repository);
    final l10n = _l10n(tester);

    await tester.tap(find.text(l10n.actionReject));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, l10n.actionReject));
    await tester.pumpAndSettle();

    expect(
      repository.rejected,
      isNull,
      reason: 'a rejection with no reason tells the person nothing to fix',
    );
  });

  testWidgets('an empty inbox says so rather than showing an empty list', (tester) async {
    await _pump(tester, _FakeRepository(waiting: []));
    expect(find.text(_l10n(tester).emptyApprovalsTitle), findsOneWidget);
  });
}
