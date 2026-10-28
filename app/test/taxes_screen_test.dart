// The taxes screen. Decisions 067 and 069: each tax in plain words, a rate
// never edited, a new rate starting on a date, rules for when it is suggested.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:winibex_accounting/core/theme/app_theme.dart';
import 'package:winibex_accounting/features/taxes/data/taxes_admin_repository.dart';
import 'package:winibex_accounting/features/taxes/domain/tax_admin.dart';
import 'package:winibex_accounting/features/taxes/presentation/taxes_screen.dart';
import 'package:winibex_accounting/features/transactions/data/transactions_repository.dart';
import 'package:winibex_accounting/features/transactions/domain/category.dart';
import 'package:winibex_accounting/l10n/generated/app_localizations.dart';

const _current = TaxView(
  id: 2,
  name: 'Withholding on services',
  shortCode: '153-IT',
  lawReference: 'ITO 2001 s.153',
  kind: 'withholding',
  appliesTo: 'purchases',
  computation: 'percent',
  rateAtl: '4.0000',
  rateNonAtl: '8.0000',
  statusBasis: 'counterparty',
  ledgerCode: '2132',
  ledgerName: 'Withholding payable, s.153',
  effectiveFrom: '2026-07-01',
  standing: 'in_force',
  isCurrent: true,
  rules: [TaxRuleView(id: 7, direction: 'out', isActive: true, currencyIsForeign: false, categoryName: 'Outsourcing')],
);

const _old = TaxView(
  id: 1,
  name: 'Withholding on services',
  shortCode: '153-IT',
  kind: 'withholding',
  appliesTo: 'purchases',
  computation: 'percent',
  rateAtl: '3.0000',
  rateNonAtl: '6.0000',
  statusBasis: 'counterparty',
  ledgerCode: '2132',
  ledgerName: 'Withholding payable, s.153',
  effectiveFrom: '2025-07-01',
  effectiveTo: '2026-06-30',
  standing: 'ended',
  isCurrent: false,
  rules: [],
);

class _FakeTaxes extends TaxesAdminRepository {
  _FakeTaxes() : super(dio: Dio());

  final List<String> calls = [];
  Map<String, dynamic>? created;
  Map<String, dynamic>? rule;

  @override
  Future<TaxesOverview> overview() async => const TaxesOverview(
    today: '2026-10-28',
    taxes: [_current, _old],
    ledgers: [
      TaxLedger(id: 41, code: '1141', name: 'Advance income tax'),
      TaxLedger(id: 32, code: '2132', name: 'Withholding payable'),
    ],
  );

  @override
  Future<void> create(Map<String, dynamic> body) async => created = body;

  @override
  Future<void> newRate(int id, {required String from, required String rateAtl, required String rateNonAtl}) async =>
      calls.add('newRate $id $from $rateAtl $rateNonAtl');

  @override
  Future<void> end(int id, {required String lastDay}) async => calls.add('end $id $lastDay');

  @override
  Future<void> addRule(int taxId, Map<String, dynamic> body) async => rule = body;

  @override
  Future<void> setRule(int ruleId, {required bool isActive}) async => calls.add('rule $ruleId $isActive');
}

class _FakeTransactions extends TransactionsRepository {
  _FakeTransactions() : super(dio: Dio());

  @override
  Future<List<CategoryGroup>> categories({String? direction}) async => const [
    CategoryGroup(
      mainHead: 'cost_of_sales',
      categories: [
        Category(
          id: 51,
          name: 'Outsourcing',
          mainHead: 'cost_of_sales',
          direction: 'out',
          ledgerCode: '5100',
          ledgerName: 'Outsourcing and subcontractors',
        ),
      ],
    ),
  ];
}

Future<_FakeTaxes> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1400, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final taxes = _FakeTaxes();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        taxesAdminRepositoryProvider.overrideWithValue(taxes),
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
        home: const Scaffold(body: TaxesScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return taxes;
}

AppLocalizations _l10n(WidgetTester tester) => AppLocalizations.of(tester.element(find.byType(TaxesScreen)));

void main() {
  testWidgets('a tax says in plain words what it does, its rates, where it is recorded and when it is suggested', (
    tester,
  ) async {
    await _pump(tester);
    final l10n = _l10n(tester);

    expect(find.text('Withholding on services'), findsOneWidget, reason: 'the ended row is hidden');
    expect(find.text('153-IT'), findsOneWidget);
    expect(find.text(taxSentence(l10n, _current)), findsOneWidget);
    expect(find.textContaining('we keep back 4%'), findsOneWidget);
    expect(find.text(l10n.taxRates('4', '8')), findsOneWidget);
    expect(find.text('2132 Withholding payable, s.153'), findsOneWidget);
    expect(find.text(l10n.taxHowTitle), findsOneWidget);
    expect(
      find.text([l10n.ruleMoneyOut, l10n.ruleRupeesOnly, l10n.ruleAnyAccount, 'Outsourcing'].join('  ·  ')),
      findsOneWidget,
    );
  });

  testWidgets('earlier rates show when asked, without buttons', (tester) async {
    await _pump(tester);
    final l10n = _l10n(tester);

    await tester.tap(find.text(l10n.taxesShowOld));
    await tester.pumpAndSettle();

    expect(find.text(l10n.taxEnded('2026-06-30')), findsOneWidget);
    expect(find.text(l10n.taxRates('3', '6')), findsOneWidget);
    expect(find.text(l10n.actionNewRate), findsOneWidget, reason: 'only on the current row');
  });

  testWidgets('a new rate is sent with its start date, and says when the old one ends', (tester) async {
    final taxes = await _pump(tester);
    final l10n = _l10n(tester);

    await tester.tap(find.text(l10n.actionNewRate));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, l10n.fieldNewRateFrom), '2027-07-01');
    await tester.pumpAndSettle();
    expect(find.text(l10n.newRateOldEnds('153-IT', '2027-06-30')), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, l10n.fieldRateFiler), '5');
    await tester.enterText(find.widgetWithText(TextFormField, l10n.fieldRateNonFiler), '10');
    await tester.tap(find.text(l10n.actionSaveNewRate));
    await tester.pumpAndSettle();

    expect(taxes.calls, ['newRate 2 2027-07-01 5 10']);
    expect(find.text(l10n.taxSaved), findsOneWidget);
  });

  testWidgets('a rate that is not a number is refused before anything is sent', (tester) async {
    final taxes = await _pump(tester);
    final l10n = _l10n(tester);

    await tester.tap(find.text(l10n.actionNewRate));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, l10n.fieldRateFiler), '4.12345');
    await tester.tap(find.text(l10n.actionSaveNewRate));
    await tester.pumpAndSettle();

    expect(find.text(l10n.errRateShape), findsOneWidget);
    expect(taxes.calls, isEmpty);
  });

  testWidgets('a rule is switched off, not deleted', (tester) async {
    final taxes = await _pump(tester);
    await tester.tap(find.text(_l10n(tester).actionSwitchOff));
    await tester.pumpAndSettle();
    expect(taxes.calls, ['rule 7 false']);
  });

  testWidgets('a new rule is sent with what it matches', (tester) async {
    final taxes = await _pump(tester);
    final l10n = _l10n(tester);

    await tester.tap(find.text(l10n.actionAddRule));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.ruleForeignOnly).last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, l10n.actionAddRule));
    await tester.pumpAndSettle();

    expect(taxes.rule, {'direction': 'out', 'currencyIsForeign': true, 'accountType': null, 'categoryId': null});
  });

  testWidgets('ending a tax sends its last day', (tester) async {
    final taxes = await _pump(tester);
    final l10n = _l10n(tester);

    await tester.tap(find.text(l10n.actionEndTax));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, l10n.fieldLastDay), '2026-12-31');
    await tester.tap(find.widgetWithText(FilledButton, l10n.actionEndTax));
    await tester.pumpAndSettle();

    expect(taxes.calls, ['end 2 2026-12-31']);
  });

  testWidgets('a new tax needs its ledger account, then sends everything', (tester) async {
    final taxes = await _pump(tester);
    final l10n = _l10n(tester);

    await tester.tap(find.widgetWithText(FilledButton, l10n.actionAddTax));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, l10n.fieldTaxName), 'Card advance tax');
    await tester.enterText(find.widgetWithText(TextFormField, l10n.fieldTaxCode), '236Y');
    await tester.enterText(find.widgetWithText(TextFormField, l10n.fieldRateFiler), '0.5');
    await tester.enterText(find.widgetWithText(TextFormField, l10n.fieldRateNonFiler), '1');
    await tester.tap(find.widgetWithText(FilledButton, l10n.actionAddTax).last);
    await tester.pumpAndSettle();
    expect(taxes.created, isNull, reason: 'no ledger account yet');

    expect(find.text(l10n.hintTaxLedgerNeeded), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('tax-ledger')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1141  Advance income tax').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, l10n.actionAddTax).last);
    await tester.pumpAndSettle();

    expect(taxes.created!['shortCode'], '236Y');
    expect(taxes.created!['rateAtl'], '0.5');
    expect(taxes.created!['ledgerCode'], '1141');
    expect(taxes.created!['computation'], 'percent');
  });
}
