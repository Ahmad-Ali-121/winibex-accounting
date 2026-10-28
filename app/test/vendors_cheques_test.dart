// Batch D: vendors and the cheque register. Decision 066. The repositories
// are fakes; the real providers, screens and request bodies run.

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
import 'package:winibex_accounting/features/cheques/data/cheques_repository.dart';
import 'package:winibex_accounting/features/cheques/domain/cheque.dart';
import 'package:winibex_accounting/features/cheques/presentation/cheques_screen.dart';
import 'package:winibex_accounting/features/vendors/data/vendors_repository.dart';
import 'package:winibex_accounting/features/vendors/domain/vendor.dart';
import 'package:winibex_accounting/features/vendors/presentation/vendors_screen.dart';
import 'package:winibex_accounting/l10n/generated/app_localizations.dart';

class _FakeVendors extends VendorsRepository {
  _FakeVendors({this.refuseAdd}) : super(dio: Dio());

  final ApiException? refuseAdd;
  VendorForm? added;
  (int, Map<String, dynamic>)? changed;

  @override
  Future<List<Vendor>> list({bool includeInactive = true}) async => const [
        Vendor(
          id: 1,
          name: 'Acme Ltd',
          kind: 'company',
          ntn: '1234567-8',
          atlStatus: 'atl',
          atlCheckedOn: '2026-07-01',
          atlCheckIsStale: true,
          canBeWithheldFrom: true,
          isActive: true,
        ),
        Vendor(id: 2, name: 'Bilal Designs', kind: 'individual', atlStatus: 'unknown', isActive: true),
        Vendor(id: 3, name: 'Upwork', kind: 'foreign', atlStatus: 'unknown', isActive: true),
      ];

  @override
  Future<void> add(VendorForm form) async {
    if (refuseAdd != null) throw refuseAdd!;
    added = form;
  }

  @override
  Future<void> change(int id, Map<String, dynamic> changes) async => changed = (id, changes);
}

class _FakeAccounts extends AccountsRepository {
  _FakeAccounts() : super(dio: Dio());

  @override
  Future<AccountsSummary> list({bool includeInactive = false}) async => const AccountsSummary(
        accounts: [
          Account(
            id: 3,
            name: 'Winibex bank',
            type: AccountType.bank,
            isActive: true,
            ledger: LedgerAccount(id: 3, code: '1113', name: 'Bank'),
            balance: Money.pkr(50000000),
          ),
          Account(
            id: 1,
            name: 'Office cash',
            type: AccountType.cash,
            isActive: true,
            ledger: LedgerAccount(id: 1, code: '1111', name: 'Cash'),
            balance: Money.pkr(5000000),
          ),
        ],
        total: Money.pkr(55000000),
        historyMerged: false,
      );
}

class _FakeCheques extends ChequesRepository {
  _FakeCheques() : super(dio: Dio());

  final List<Map<String, Object?>> issued = [];
  final List<(int, String, String?)> statuses = [];
  final List<(int, int)> links = [];

  static const _issued = Cheque(
    id: 10,
    accountId: 3,
    accountName: 'Winibex bank',
    chequeNumber: '004512',
    payee: 'Acme Ltd',
    amount: Money.pkr(9600000),
    issueDate: '2026-10-20',
    status: 'issued',
  );

  static const _cleared = Cheque(
    id: 11,
    accountId: 3,
    accountName: 'Winibex bank',
    chequeNumber: '004511',
    payee: 'Office landlord',
    amount: Money.pkr(9000000),
    issueDate: '2026-10-01',
    status: 'cleared',
    clearedOn: '2026-10-03',
    transactionId: 40,
    journalNumber: 'JV-8',
  );

  @override
  Future<ChequeRegister> list({String? status}) async => ChequeRegister(
        cheques: [_issued, _cleared].where((c) => status == null || c.status == status).toList(),
        outstanding: const Money.pkr(9600000),
      );

  @override
  Future<void> issue({
    required int accountId,
    required String chequeNumber,
    required String payee,
    required Money amount,
    required String issueDate,
    String? note,
  }) async {
    issued.add({'account': accountId, 'number': chequeNumber, 'payee': payee, 'amount': amount.minorUnits});
  }

  @override
  Future<void> setStatus(int id, String status, {String? clearedOn}) async => statuses.add((id, status, clearedOn));

  @override
  Future<void> link(int id, int transactionId) async => links.add((id, transactionId));

  @override
  Future<List<PaymentOption>> payments({required int accountId, String search = ''}) async => const [
        PaymentOption(
          id: 77,
          journalNumber: 'JV-15',
          date: '2026-10-20',
          description: 'Website work by Acme',
          amount: Money.pkr(9600000),
        ),
      ];
}

Future<void> _pump(WidgetTester tester, Widget home, {_FakeVendors? vendors, _FakeCheques? cheques}) async {
  tester.view.physicalSize = const Size(1400, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        vendorsRepositoryProvider.overrideWithValue(vendors ?? _FakeVendors()),
        chequesRepositoryProvider.overrideWithValue(cheques ?? _FakeCheques()),
        accountsRepositoryProvider.overrideWithValue(_FakeAccounts()),
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

Finder _field(String label) => find.widgetWithText(TextFormField, label);

void main() {
  // --- vendors ----------------------------------------------------------------

  testWidgets('each vendor says if they are a filer, when checked, and if they lack an NTN', (tester) async {
    await _pump(tester, const VendorsScreen());
    final l10n = _l10n(tester);

    expect(find.text('Acme Ltd'), findsOneWidget);
    expect(find.text(l10n.filerYes), findsOneWidget);
    expect(find.text(l10n.filerCheckAgain('2026-07-01')), findsOneWidget);

    expect(find.text(l10n.filerUnknown), findsOneWidget, reason: 'Bilal, not checked');
    expect(find.text(l10n.vendorNoTaxId), findsOneWidget, reason: 'Bilal has no NTN or CNIC');
    expect(find.text(l10n.vendorKindForeign), findsOneWidget, reason: 'Upwork, with no filer chip');
  });

  testWidgets('staff can read vendors but not add or change them', (tester) async {
    await _pump(tester, const VendorsScreen());
    final l10n = _l10n(tester);
    expect(find.text(l10n.actionAddVendor), findsNothing);
    expect(find.text(l10n.actionEdit), findsNothing);
  });

  testWidgets('search narrows the list', (tester) async {
    await _pump(tester, const VendorsScreen());
    await tester.enterText(find.byType(TextField).first, 'acme');
    await tester.pumpAndSettle();
    expect(find.text('Acme Ltd'), findsOneWidget);
    expect(find.text('Bilal Designs'), findsNothing);
  });

  testWidgets('adding a filer sends the NTN, the status and the date checked', (tester) async {
    final vendors = _FakeVendors();
    await _pump(tester, const VendorsScreen(canManage: true), vendors: vendors);
    final l10n = _l10n(tester);

    await tester.tap(find.text(l10n.actionAddVendor));
    await tester.pumpAndSettle();
    await tester.enterText(_field(l10n.fieldVendorName), 'Zed Hosting');
    await tester.enterText(_field(l10n.fieldNtn), '7654321-0');
    await tester.tap(find.text(l10n.filerYes).last);
    await tester.pumpAndSettle();
    await tester.enterText(_field(l10n.fieldCheckedOn), '2026-10-28');
    await tester.tap(find.widgetWithText(FilledButton, l10n.actionSave));
    await tester.pumpAndSettle();

    final body = vendors.added!.toRequest();
    expect(body['name'], 'Zed Hosting');
    expect(body['ntn'], '7654321-0');
    expect(body['atlStatus'], 'atl');
    expect(body['atlCheckedOn'], '2026-10-28');
    expect(body.containsKey('cnic'), isFalse, reason: 'empty fields are left out');
  });

  testWidgets('a local vendor with no NTN or CNIC is warned about in the form', (tester) async {
    await _pump(tester, const VendorsScreen(canManage: true));
    final l10n = _l10n(tester);

    await tester.tap(find.text(l10n.actionAddVendor));
    await tester.pumpAndSettle();
    expect(find.text(l10n.hintNoTaxId), findsOneWidget);

    await tester.tap(find.text(l10n.vendorKindForeign).last);
    await tester.pumpAndSettle();
    expect(find.text(l10n.hintNoTaxId), findsNothing, reason: 'no NTN is needed outside Pakistan');
    expect(_field(l10n.fieldCountry), findsOneWidget);
  });

  testWidgets('a vendor can be switched off', (tester) async {
    final vendors = _FakeVendors();
    await _pump(tester, const VendorsScreen(canManage: true), vendors: vendors);

    await tester.tap(find.text(_l10n(tester).actionSwitchOff).first);
    await tester.pumpAndSettle();

    expect(vendors.changed?.$1, 1);
    expect(vendors.changed?.$2, {'isActive': false});
  });

  testWidgets('a refusal from the server is shown in its words', (tester) async {
    final vendors = _FakeVendors(
      refuseAdd: const ApiException(code: 'ALREADY_EXISTS', message: 'That name is already used.', status: 409),
    );
    await _pump(tester, const VendorsScreen(canManage: true), vendors: vendors);
    final l10n = _l10n(tester);

    await tester.tap(find.text(l10n.actionAddVendor));
    await tester.pumpAndSettle();
    await tester.enterText(_field(l10n.fieldVendorName), 'Acme Ltd');
    await tester.tap(find.widgetWithText(FilledButton, l10n.actionSave));
    await tester.pumpAndSettle();

    expect(find.text('That name is already used.'), findsOneWidget);
  });

  // --- cheques ----------------------------------------------------------------

  testWidgets('the register shows what is outstanding and where each cheque stands', (tester) async {
    await _pump(tester, const ChequesScreen());
    final l10n = _l10n(tester);

    expect(find.text(l10n.chequesOutstanding), findsOneWidget);
    expect(find.text('PKR 96,000.00'), findsOneWidget);
    expect(find.text(l10n.chequeClearedOn('2026-10-03')), findsOneWidget);
    expect(find.text(l10n.chequeLinkedTo('JV-8')), findsOneWidget);
    expect(find.text(l10n.chequeNotLinked), findsOneWidget);
    expect(find.text(l10n.actionMarkPresented), findsNothing, reason: 'staff cannot move a cheque');
  });

  testWidgets('an issued cheque offers presented, bounced and cancel; a cleared one nothing', (tester) async {
    await _pump(tester, const ChequesScreen(canManage: true));
    final l10n = _l10n(tester);

    expect(find.text(l10n.actionMarkPresented), findsOneWidget);
    expect(find.text(l10n.actionMarkBounced), findsOneWidget);
    expect(find.text(l10n.actionCancelCheque), findsOneWidget);
    expect(find.text(l10n.actionMarkCleared), findsNothing, reason: 'it has to be presented first');
  });

  testWidgets('marking presented sends it', (tester) async {
    final cheques = _FakeCheques();
    await _pump(tester, const ChequesScreen(canManage: true), cheques: cheques);

    await tester.tap(find.text(_l10n(tester).actionMarkPresented));
    await tester.pumpAndSettle();

    expect(cheques.statuses, [(10, 'presented', null)]);
  });

  testWidgets('cancelling asks first', (tester) async {
    final cheques = _FakeCheques();
    await _pump(tester, const ChequesScreen(canManage: true), cheques: cheques);
    final l10n = _l10n(tester);

    await tester.tap(find.text(l10n.actionCancelCheque));
    await tester.pumpAndSettle();
    expect(find.text(l10n.chequeCancelTitle), findsOneWidget);
    expect(cheques.statuses, isEmpty);

    await tester.tap(find.widgetWithText(FilledButton, l10n.actionCancelCheque));
    await tester.pumpAndSettle();
    expect(cheques.statuses, [(10, 'cancelled', null)]);
  });

  testWidgets('a cheque is linked to the payment picked', (tester) async {
    final cheques = _FakeCheques();
    await _pump(tester, const ChequesScreen(canManage: true), cheques: cheques);
    final l10n = _l10n(tester);

    await tester.tap(find.text(l10n.actionLinkPayment));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Website work by Acme'));
    await tester.pumpAndSettle();

    expect(cheques.links, [(10, 77)]);
  });

  testWidgets('recording a cheque offers only bank accounts and sends what was typed', (tester) async {
    final cheques = _FakeCheques();
    await _pump(tester, const ChequesScreen(canManage: true), cheques: cheques);
    final l10n = _l10n(tester);

    await tester.tap(find.widgetWithText(FilledButton, l10n.actionIssueCheque));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('cheque-account')));
    await tester.pumpAndSettle();
    expect(find.text('Office cash'), findsNothing, reason: 'cash cannot write a cheque');
    await tester.tap(find.text('Winibex bank').last);
    await tester.pumpAndSettle();

    await tester.enterText(_field(l10n.fieldChequeNumber), '004513');
    await tester.enterText(_field(l10n.fieldPayableTo), 'Zed Hosting');
    await tester.enterText(_field(l10n.fieldAmount), '12000');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, l10n.actionIssueCheque).last);
    await tester.pumpAndSettle();

    expect(cheques.issued.single, {'account': 3, 'number': '004513', 'payee': 'Zed Hosting', 'amount': 1200000});
  });
}
