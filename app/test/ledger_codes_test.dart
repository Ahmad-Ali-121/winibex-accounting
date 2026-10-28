// The ledger codes screen. Decisions 068 and 069: the owner adds codes and
// headings, changes them or switches them off; built-in codes are left alone.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:winibex_accounting/core/api/api_exception.dart';
import 'package:winibex_accounting/core/theme/app_theme.dart';
import 'package:winibex_accounting/features/ledger_codes/data/ledger_codes_repository.dart';
import 'package:winibex_accounting/features/ledger_codes/domain/ledger_code.dart';
import 'package:winibex_accounting/features/ledger_codes/presentation/ledger_codes_screen.dart';
import 'package:winibex_accounting/l10n/generated/app_localizations.dart';

const _codes = [
  LedgerCode(
    id: 1,
    code: '1000',
    name: 'Assets',
    type: 'asset',
    isHeader: true,
    isSystem: true,
    isActive: true,
    onEntryForm: false,
  ),
  LedgerCode(
    id: 13,
    code: '1113',
    name: 'Bank, Winibex current account',
    type: 'asset',
    isHeader: false,
    isSystem: true,
    isActive: true,
    onEntryForm: false,
    parentId: 1,
    parentCode: '1000',
  ),
  LedgerCode(
    id: 60,
    code: '6000',
    name: 'Administrative expenses',
    type: 'expense',
    isHeader: true,
    isSystem: false,
    isActive: true,
    onEntryForm: false,
  ),
  LedgerCode(
    id: 66,
    code: '6600',
    name: 'Office supplies, printing and stationery',
    type: 'expense',
    isHeader: false,
    isSystem: false,
    isActive: true,
    onEntryForm: true,
    parentId: 60,
    parentCode: '6000',
  ),
  LedgerCode(
    id: 69,
    code: '6960',
    name: 'Courier charges',
    type: 'expense',
    isHeader: false,
    isSystem: false,
    isActive: false,
    onEntryForm: false,
    parentId: 60,
    parentCode: '6000',
  ),
];

class _FakeLedgerCodes extends LedgerCodesRepository {
  _FakeLedgerCodes() : super(dio: Dio());

  final List<String> calls = [];
  ApiException? refuseCreate;

  @override
  Future<List<LedgerCode>> list() async => _codes;

  @override
  Future<void> create({
    required String code,
    required String name,
    required bool isHeading,
    required bool addToEntryForm,
    String? parentCode,
  }) async {
    if (refuseCreate != null) throw refuseCreate!;
    calls.add('create $code $name heading:$isHeading form:$addToEntryForm under:$parentCode');
  }

  @override
  Future<void> update(int id, {String? name, String? parentCode}) async => calls.add('update $id $name $parentCode');

  @override
  Future<void> setActive(int id, {required bool isActive}) async => calls.add('active $id $isActive');
}

Future<_FakeLedgerCodes> _pump(WidgetTester tester, {VoidCallback? onImportExport}) async {
  tester.view.physicalSize = const Size(1400, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repository = _FakeLedgerCodes();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [ledgerCodesRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: LedgerCodesScreen(onImportExport: onImportExport)),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

AppLocalizations _l10n(WidgetTester tester) => AppLocalizations.of(tester.element(find.byType(LedgerCodesScreen)));

Finder _inDialog(String label) => find.descendant(of: find.byType(AlertDialog), matching: find.text(label));

void main() {
  testWidgets('codes are grouped by class and heading, and built-in ones have no menu', (tester) async {
    await _pump(tester);
    final l10n = _l10n(tester);

    expect(find.text('1000  ${l10n.ledgerClass1}'), findsOneWidget);
    expect(find.text('6000  ${l10n.ledgerClass6}'), findsOneWidget);
    expect(find.text(l10n.ledgerHowTitle), findsOneWidget);
    expect(find.text(l10n.ledgerBuiltIn), findsNWidgets(2));
    expect(find.byKey(const ValueKey('ledger-menu-1113')), findsNothing);
    expect(find.byKey(const ValueKey('ledger-menu-1000')), findsNothing, reason: 'a built-in heading');
    expect(find.byKey(const ValueKey('ledger-menu-6000')), findsOneWidget, reason: 'a heading the owner added');
    expect(find.byKey(const ValueKey('ledger-menu-6600')), findsOneWidget);
  });

  testWidgets('switched-off codes show only when asked, and search narrows the list', (tester) async {
    await _pump(tester);
    final l10n = _l10n(tester);

    expect(find.text('Courier charges'), findsNothing);
    await tester.tap(find.text(l10n.ledgerShowOff));
    await tester.pumpAndSettle();
    expect(find.text('Courier charges'), findsOneWidget);
    expect(find.text(l10n.ledgerSwitchedOff), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('ledger-search')), '66');
    await tester.pumpAndSettle();
    expect(find.text('Office supplies, printing and stationery'), findsOneWidget);
    expect(find.text('Bank, Winibex current account'), findsNothing);
  });

  testWidgets('adding a code says where it goes, offers its headings, and joins the entry form', (tester) async {
    final repository = await _pump(tester);
    final l10n = _l10n(tester);

    await tester.tap(find.byKey(const ValueKey('ledger-add-code')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('ledger-code-field')), '6970');
    await tester.pumpAndSettle();
    expect(find.text(l10n.ledgerGoesUnder(l10n.ledgerClass6)), findsOneWidget);
    expect(find.byKey(const ValueKey('ledger-entry-form-switch')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('ledger-parent-6970')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('6000  Administrative expenses').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('ledger-name-field')), 'Courier and postage');
    await tester.tap(find.byKey(const ValueKey('ledger-add-save')));
    await tester.pumpAndSettle();

    expect(repository.calls, ['create 6970 Courier and postage heading:false form:true under:6000']);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text(l10n.ledgerSaved), findsOneWidget);
  });

  testWidgets('a heading never joins the entry form, and the nearest heading is the default', (tester) async {
    final repository = await _pump(tester);
    final l10n = _l10n(tester);

    await tester.tap(find.byKey(const ValueKey('ledger-add-heading')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.ledgerAddHeadingTitle), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('ledger-code-field')), '6900');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('ledger-entry-form-switch')), findsNothing);

    await tester.enterText(find.byKey(const ValueKey('ledger-name-field')), 'Other office costs');
    await tester.tap(find.byKey(const ValueKey('ledger-add-save')));
    await tester.pumpAndSettle();
    expect(repository.calls, ['create 6900 Other office costs heading:true form:false under:null']);
  });

  testWidgets('a code that is not four digits is stopped before anything is sent', (tester) async {
    final repository = await _pump(tester);
    final l10n = _l10n(tester);

    await tester.tap(find.byKey(const ValueKey('ledger-add-code')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('ledger-code-field')), '0123');
    await tester.enterText(find.byKey(const ValueKey('ledger-name-field')), 'Something');
    await tester.tap(find.byKey(const ValueKey('ledger-add-save')));
    await tester.pumpAndSettle();

    expect(find.text(l10n.errLedgerCodeShape), findsOneWidget);
    expect(repository.calls, isEmpty);
  });

  testWidgets('a refusal stays in the dialog, in the server words', (tester) async {
    final repository = await _pump(tester);
    repository.refuseCreate = const ApiException(
      code: 'VALIDATION_FAILED',
      message: '6600 is already called Office supplies, printing and stationery. Use that one, or pick another name.',
      status: 400,
    );

    await tester.tap(find.byKey(const ValueKey('ledger-add-code')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('ledger-code-field')), '6980');
    await tester.enterText(find.byKey(const ValueKey('ledger-name-field')), 'Office supplies, printing and stationery');
    await tester.tap(find.byKey(const ValueKey('ledger-add-save')));
    await tester.pumpAndSettle();

    expect(find.textContaining('6600 is already called'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('edit sends only what changed, and switching off asks first', (tester) async {
    final repository = await _pump(tester);
    final l10n = _l10n(tester);

    await tester.tap(find.byKey(const ValueKey('ledger-menu-6600')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.actionEdit));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('ledger-rename-field')), 'Office stationery');
    await tester.tap(_inDialog(l10n.actionSave));
    await tester.pumpAndSettle();
    expect(repository.calls, ['update 66 Office stationery null']);

    await tester.tap(find.byKey(const ValueKey('ledger-menu-6600')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.actionSwitchOff));
    await tester.pumpAndSettle();
    expect(find.text(l10n.ledgerSwitchOffHint), findsOneWidget);
    await tester.tap(_inDialog(l10n.actionSwitchOff));
    await tester.pumpAndSettle();
    expect(repository.calls.last, 'active 66 false');
  });

  testWidgets('import or export opens from here', (tester) async {
    var opened = false;
    await _pump(tester, onImportExport: () => opened = true);
    await tester.tap(find.text(_l10n(tester).actionImportOrExport));
    expect(opened, isTrue);
  });
}
