// Import and export of ledger codes and taxes. Decision 069: nothing is
// saved until the person has seen what the file will change and confirmed.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:winibex_accounting/core/files/csv_files.dart';
import 'package:winibex_accounting/core/theme/app_theme.dart';
import 'package:winibex_accounting/features/import_export/data/bulk_repository.dart';
import 'package:winibex_accounting/features/import_export/domain/import_plan.dart';
import 'package:winibex_accounting/features/import_export/presentation/import_export_screen.dart';
import 'package:winibex_accounting/l10n/generated/app_localizations.dart';

const _plan = ImportPlan(
  applied: false,
  added: 1,
  updated: 1,
  unchanged: 1,
  skipped: 1,
  rows: [
    ImportRow(
      rows: [3],
      code: '6960',
      name: 'Courier charges',
      action: 'add',
      changes: ['New code', 'Under 6000 Administrative expenses'],
    ),
    ImportRow(
      rows: [4],
      code: '6600',
      name: 'Office stationery',
      action: 'update',
      changes: ['Name: Office supplies to Office stationery'],
    ),
    ImportRow(rows: [5], code: '6700', name: 'Repairs and maintenance', action: 'unchanged', changes: []),
    ImportRow(
      rows: [6],
      code: '1113',
      name: 'Renamed bank',
      action: 'skip',
      changes: [],
      reason: '1113 is built in: its name, heading and switch stay as they are.',
    ),
  ],
);

class _FakeBulk extends BulkRepository {
  _FakeBulk({this.plan = _plan}) : super(dio: Dio());

  final ImportPlan plan;
  final List<String> calls = [];

  @override
  Future<BulkFile> template(BulkKind kind) async {
    calls.add('template ${kind.path}');
    return BulkFile(filename: '${kind.path}-template.csv', csv: 'Code,Name\r\n');
  }

  @override
  Future<BulkFile> exportList(BulkKind kind) async {
    calls.add('export ${kind.path}');
    return BulkFile(filename: '${kind.path}-2026-10-29.csv', csv: 'Code,Name\r\n6600,Office\r\n');
  }

  @override
  Future<ImportPlan> importFile(BulkKind kind, String csv, {required bool apply}) async {
    calls.add('import ${kind.path} apply:$apply');
    return apply
        ? ImportPlan(
            applied: true,
            added: plan.added,
            updated: plan.updated,
            unchanged: plan.unchanged,
            skipped: plan.skipped,
            rows: plan.rows,
          )
        : plan;
  }
}

class _FakeFiles extends CsvFiles {
  _FakeFiles();

  final List<String> saved = [];

  @override
  Future<PickedCsv?> pick() async => const PickedCsv(name: 'codes.csv', text: 'Code,Name\r\n6960,Courier\r\n');

  @override
  Future<void> save({required String filename, required String csv}) async => saved.add(filename);
}

Future<(_FakeBulk, _FakeFiles)> _pump(WidgetTester tester, {ImportPlan plan = _plan}) async {
  tester.view.physicalSize = const Size(1400, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final bulk = _FakeBulk(plan: plan);
  final files = _FakeFiles();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [bulkRepositoryProvider.overrideWithValue(bulk), csvFilesProvider.overrideWithValue(files)],
      child: MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: ImportExportScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (bulk, files);
}

AppLocalizations _l10n(WidgetTester tester) => AppLocalizations.of(tester.element(find.byType(ImportExportScreen)));

void main() {
  testWidgets('the page explains the three steps and offers both lists', (tester) async {
    await _pump(tester);
    final l10n = _l10n(tester);
    expect(find.text(l10n.bulkStep1), findsOneWidget);
    expect(find.text(l10n.bulkLedgerExplain), findsOneWidget);
    expect(find.text(l10n.bulkTaxesExplain), findsOneWidget);
  });

  testWidgets('the template and the current list download as files', (tester) async {
    final (bulk, files) = await _pump(tester);

    await tester.tap(find.byKey(const ValueKey('bulk-template-ledger-codes')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('bulk-export-taxes')));
    await tester.pumpAndSettle();

    expect(bulk.calls, ['template ledger-codes', 'export taxes']);
    expect(files.saved, ['ledger-codes-template.csv', 'taxes-2026-10-29.csv']);
  });

  testWidgets('an import shows what each row will do before anything is saved', (tester) async {
    final (bulk, _) = await _pump(tester);
    final l10n = _l10n(tester);

    await tester.tap(find.byKey(const ValueKey('bulk-import-ledger-codes')));
    await tester.pumpAndSettle();

    expect(bulk.calls, ['import ledger-codes apply:false']);
    expect(find.text(l10n.bulkPreviewTitle('codes.csv')), findsOneWidget);
    expect(find.text(l10n.bulkCountAdd(1)), findsOneWidget);
    expect(find.text(l10n.bulkCountSkip(1)), findsOneWidget);
    expect(find.text('6960  Courier charges'), findsOneWidget);
    expect(find.textContaining('1113 is built in'), findsOneWidget);
    expect(find.text('6700  Repairs and maintenance'), findsNothing, reason: 'rows with no change are hidden at first');

    await tester.tap(find.text(l10n.bulkShowUnchanged));
    await tester.pumpAndSettle();
    expect(find.text('6700  Repairs and maintenance'), findsOneWidget);
  });

  testWidgets('confirming saves, then says what was saved', (tester) async {
    final (bulk, _) = await _pump(tester);
    final l10n = _l10n(tester);

    await tester.tap(find.byKey(const ValueKey('bulk-import-ledger-codes')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.bulkSaveChanges(2)), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('bulk-confirm')));
    await tester.pumpAndSettle();

    expect(bulk.calls, ['import ledger-codes apply:false', 'import ledger-codes apply:true']);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text(l10n.bulkSaved(1, 1, 1)), findsOneWidget);
  });

  testWidgets('a file with nothing to change cannot be saved', (tester) async {
    const nothing = ImportPlan(
      applied: false,
      added: 0,
      updated: 0,
      unchanged: 1,
      skipped: 0,
      rows: [
        ImportRow(rows: [3], code: '6700', name: 'Repairs', action: 'unchanged', changes: []),
      ],
    );
    await _pump(tester, plan: nothing);
    final l10n = _l10n(tester);

    await tester.tap(find.byKey(const ValueKey('bulk-import-taxes')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.bulkNothingToSave), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byKey(const ValueKey('bulk-confirm')));
    expect(button.onPressed, isNull);
  });
}
