// The review list, and marking a flag reviewed. Decision 056, defect D2.
//
// The repository is replaced, so the real providers and widgets run and only
// the network does not.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:winibex_accounting/core/api/api_exception.dart';
import 'package:winibex_accounting/core/money/money.dart';
import 'package:winibex_accounting/core/theme/app_theme.dart';
import 'package:winibex_accounting/features/flags/data/flags_repository.dart';
import 'package:winibex_accounting/features/flags/presentation/flags_screen.dart';
import 'package:winibex_accounting/l10n/generated/app_localizations.dart';

const _tea = EntryFlag(
  id: 5,
  transactionId: 12,
  severity: 'flag',
  code: 'THIN_DESCRIPTION',
  detail: 'The description is too short to tell what this was.',
  entryDescription: 'tea',
  entryAmount: Money.pkr(30000),
  journalNumber: 'JV-0013',
);

class _FakeFlagsRepository extends FlagsRepository {
  _FakeFlagsRepository({this.resolveFails}) : super(dio: Dio());

  final ApiException? resolveFails;

  int loads = 0;
  int? resolvedId;
  String? resolvedNote;

  /// Once resolved, the server no longer lists the flag as open.
  @override
  Future<List<EntryFlag>> load() async {
    loads += 1;
    return resolvedId == null ? const [_tea] : const [];
  }

  @override
  Future<void> resolve(int id, String note) async {
    final failure = resolveFails;
    if (failure != null) throw failure;
    resolvedId = id;
    resolvedNote = note;
  }
}

Future<void> _pump(
  WidgetTester tester,
  _FakeFlagsRepository repository, {
  bool canReview = true,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [flagsRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: FlagsScreen(canReview: canReview)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(FlagsScreen)));

Future<void> _markReviewed(WidgetTester tester, String note) async {
  final l10n = _l10n(tester);
  await tester.tap(find.widgetWithText(TextButton, l10n.actionMarkReviewed));
  await tester.pumpAndSettle();

  expect(find.text(l10n.markReviewedTitle), findsOneWidget);
  await tester.enterText(find.byType(TextField), note);
  await tester.tap(find.widgetWithText(FilledButton, l10n.actionMarkReviewed));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a flag names the entry it is about', (tester) async {
    await _pump(tester, _FakeFlagsRepository());

    expect(find.text('tea'), findsOneWidget);
    expect(find.text(_l10n(tester).flagThinDescription), findsOneWidget);
    expect(find.text('JV-0013'), findsOneWidget);
  });

  testWidgets('staff are not offered the button', (tester) async {
    await _pump(tester, _FakeFlagsRepository(), canReview: false);

    expect(find.text(_l10n(tester).actionMarkReviewed), findsNothing);
  });

  testWidgets('marking reviewed sends the reason, and the flag leaves the list', (tester) async {
    final repository = _FakeFlagsRepository();
    await _pump(tester, repository);
    final l10n = _l10n(tester);

    await _markReviewed(tester, 'Office tea for the team, nothing to add');

    expect(repository.resolvedId, 5);
    expect(repository.resolvedNote, 'Office tea for the team, nothing to add');
    expect(repository.loads, 2, reason: 'the list is asked for again, not edited in place');
    expect(find.text('tea'), findsNothing);
    expect(find.text(l10n.emptyFlagsTitle), findsOneWidget);
    expect(find.text(l10n.flagMarkedReviewed), findsOneWidget);
  });

  testWidgets('a reason shorter than three characters sends nothing', (tester) async {
    final repository = _FakeFlagsRepository();
    await _pump(tester, repository);

    await _markReviewed(tester, 'ok');

    expect(repository.resolvedId, isNull);
    expect(find.text('tea'), findsOneWidget);
  });

  testWidgets('a refusal says why', (tester) async {
    const reason = 'Only the owner or an admin can mark a flag reviewed.';
    final repository = _FakeFlagsRepository(
      resolveFails: const ApiException(code: 'FORBIDDEN', message: reason, status: 403),
    );
    await _pump(tester, repository);

    await _markReviewed(tester, 'Looks fine to me');

    expect(find.text(reason), findsOneWidget);
    expect(find.text('tea'), findsOneWidget, reason: 'nothing changed on the server');
  });
}
