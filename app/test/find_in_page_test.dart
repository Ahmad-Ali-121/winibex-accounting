// Find on this screen, Ctrl+F inside the app. Decision 068.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:winibex_accounting/core/theme/app_theme.dart';
import 'package:winibex_accounting/features/shell/presentation/find_in_page.dart';
import 'package:winibex_accounting/l10n/generated/app_localizations.dart';

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: FindScope(
          location: '/transactions',
          child: Column(
            children: [
              Builder(
                builder: (context) =>
                    TextButton(onPressed: () => FindScope.read(context)?.open(), child: const Text('Open find')),
              ),
              Expanded(
                child: FindTarget(
                  child: ListView(
                    children: const [
                      Text('Printer paper and pens'),
                      Text('Printer ink'),
                      Text('Toner refill'),
                      Offstage(child: Text('Printer hidden from view')),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

AppLocalizations _l10n(WidgetTester tester) => AppLocalizations.of(tester.element(find.byType(FindTarget)));

Future<void> _pressCtrlF(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pumpAndSettle();
}

String _count(WidgetTester tester) => tester.widget<Text>(find.byKey(const ValueKey('find-count'))).data ?? '';

void main() {
  test('matches ignore case and do not overlap', () {
    expect(matchOffsets('Printer paper and printer ink', 'PRINTER'), [0, 18]);
    expect(matchOffsets('aaaa', 'aa'), [0, 2]);
    expect(matchOffsets('Toner', ''), isEmpty);
  });

  testWidgets('Ctrl+F opens the find bar with the box ready to type in', (tester) async {
    await _pump(tester);
    expect(find.byKey(const ValueKey('find-field')), findsNothing);

    await _pressCtrlF(tester);
    expect(find.byKey(const ValueKey('find-field')), findsOneWidget);
    final field = tester.widget<TextField>(find.byKey(const ValueKey('find-field')));
    expect(field.focusNode!.hasFocus, isTrue);
  });

  testWidgets('every match on the screen is counted, and hidden text is not', (tester) async {
    await _pump(tester);
    await _pressCtrlF(tester);

    await tester.enterText(find.byKey(const ValueKey('find-field')), 'printer');
    await tester.pumpAndSettle();
    expect(_count(tester), _l10n(tester).findCount(1, 2));
  });

  testWidgets('Enter steps forward and wraps round; Shift+Enter steps back', (tester) async {
    await _pump(tester);
    await _pressCtrlF(tester);
    final l10n = _l10n(tester);

    await tester.enterText(find.byKey(const ValueKey('find-field')), 'printer');
    await tester.pumpAndSettle();

    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(_count(tester), l10n.findCount(2, 2));

    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(_count(tester), l10n.findCount(1, 2));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();
    expect(_count(tester), l10n.findCount(2, 2));
  });

  testWidgets('no match says so, and the find bar never finds its own words', (tester) async {
    await _pump(tester);
    await _pressCtrlF(tester);
    final l10n = _l10n(tester);

    await tester.enterText(find.byKey(const ValueKey('find-field')), 'zzz');
    await tester.pumpAndSettle();
    expect(_count(tester), l10n.findNoMatches);

    await tester.enterText(find.byKey(const ValueKey('find-field')), 'screen');
    await tester.pumpAndSettle();
    expect(_count(tester), l10n.findNoMatches);
  });

  testWidgets('Escape and the close button both close it', (tester) async {
    await _pump(tester);
    await _pressCtrlF(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('find-field')), findsNothing);

    await tester.tap(find.text('Open find'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('find-field')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('find-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('find-field')), findsNothing);
  });
}
