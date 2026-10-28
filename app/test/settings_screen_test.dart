// The Settings home. Decision 069: cards that say what each part is for,
// each opening its own page, and the owner only.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:winibex_accounting/core/theme/app_theme.dart';
import 'package:winibex_accounting/features/ledger_codes/application/ledger_codes_providers.dart';
import 'package:winibex_accounting/features/ledger_codes/domain/ledger_code.dart';
import 'package:winibex_accounting/features/people/application/people_providers.dart';
import 'package:winibex_accounting/features/people/domain/team_member.dart';
import 'package:winibex_accounting/features/settings/presentation/settings_screen.dart';
import 'package:winibex_accounting/features/taxes/application/taxes_admin_providers.dart';
import 'package:winibex_accounting/features/taxes/domain/tax_admin.dart';
import 'package:winibex_accounting/l10n/generated/app_localizations.dart';

const _people = [
  TeamMember(id: 1, name: 'Winibex office', email: 'office@test.local', role: 'owner'),
  TeamMember(id: 2, name: 'Maryam', email: 'maryam@test.local', role: 'staff'),
  TeamMember(id: 3, name: 'Former', email: 'former@test.local', role: 'staff', isActive: false),
];

const _codes = [
  LedgerCode(
    id: 1,
    code: '6000',
    name: 'Admin',
    type: 'expense',
    isHeader: true,
    isSystem: false,
    isActive: true,
    onEntryForm: false,
  ),
  LedgerCode(
    id: 2,
    code: '6600',
    name: 'Office',
    type: 'expense',
    isHeader: false,
    isSystem: false,
    isActive: true,
    onEntryForm: true,
  ),
  LedgerCode(
    id: 3,
    code: '6700',
    name: 'Repairs',
    type: 'expense',
    isHeader: false,
    isSystem: false,
    isActive: true,
    onEntryForm: true,
  ),
];

Future<List<SettingsSection?>> _pump(WidgetTester tester, {bool isOwner = true, SettingsSection? section}) async {
  tester.view.physicalSize = const Size(1400, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final opened = <SettingsSection?>[];

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        teamProvider.overrideWith((ref) async => _people),
        ledgerCodesProvider.overrideWith((ref) async => _codes),
        taxesOverviewProvider.overrideWith(
          (ref) async => const TaxesOverview(today: '2026-10-29', taxes: [], ledgers: []),
        ),
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
        home: Scaffold(
          body: section == SettingsSection.importExport || section == null
              ? SettingsScreen(isOwner: isOwner, section: section, onOpen: opened.add)
              : const SizedBox.shrink(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return opened;
}

AppLocalizations _l10n(WidgetTester tester) => AppLocalizations.of(tester.element(find.byType(Scaffold)));

void main() {
  testWidgets('the home says what each part is for, with a live summary', (tester) async {
    await _pump(tester);
    final l10n = _l10n(tester);

    expect(find.text(l10n.settingsPeopleExplain), findsOneWidget);
    expect(find.text(l10n.settingsTaxesExplain), findsOneWidget);
    expect(find.text(l10n.settingsLedgerExplain), findsOneWidget);
    expect(find.text(l10n.settingsImportExplain), findsOneWidget);
    expect(find.text(l10n.settingsPeopleSummary(2)), findsOneWidget, reason: 'switched-off people do not count');
    expect(find.text(l10n.settingsTaxesSummary(0)), findsOneWidget);
    expect(find.text(l10n.settingsLedgerSummary(2, 1)), findsOneWidget);
  });

  testWidgets('each card opens its own page', (tester) async {
    final opened = await _pump(tester);
    await tester.tap(find.byKey(const ValueKey('settings-card-taxes')));
    await tester.tap(find.byKey(const ValueKey('settings-card-ledger')));
    await tester.tap(find.byKey(const ValueKey('settings-card-people')));
    await tester.tap(find.byKey(const ValueKey('settings-card-import')));
    expect(opened, [
      SettingsSection.taxes,
      SettingsSection.ledgerCodes,
      SettingsSection.people,
      SettingsSection.importExport,
    ]);
  });

  testWidgets('a page has a way back to all settings', (tester) async {
    final opened = await _pump(tester, section: SettingsSection.importExport);
    await tester.tap(find.byKey(const ValueKey('settings-back')));
    expect(opened, [null]);
  });

  testWidgets('anyone but the owner sees one line saying so', (tester) async {
    await _pump(tester, isOwner: false);
    expect(find.text(_l10n(tester).settingsOwnerOnly), findsOneWidget);
    expect(find.byKey(const ValueKey('settings-card-people')), findsNothing);
  });
}
