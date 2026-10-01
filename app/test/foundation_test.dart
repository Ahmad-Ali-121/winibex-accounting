import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:winibex_accounting/core/glossary/glossary.dart';
import 'package:winibex_accounting/core/theme/app_theme.dart';
import 'package:winibex_accounting/core/widgets/term_tooltip.dart';
import 'package:winibex_accounting/l10n/generated/app_localizations.dart';

Widget wrap(Widget child, {ThemeMode mode = ThemeMode.light}) {
  return MaterialApp(
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: mode,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('theme', () {
    test('both themes carry the colour extension, so context.colors never throws', () {
      expect(AppTheme.light.extension<AppColors>(), isNotNull);
      expect(AppTheme.dark.extension<AppColors>(), isNotNull);
    });

    test('light and dark are designed separately rather than inverted', () {
      expect(AppColors.light.background, isNot(AppColors.dark.background));
      expect(AppColors.light.accent, isNot(AppColors.dark.accent));
      expect(AppColors.light.negative, isNot(AppColors.dark.negative));
    });

    test('every semantic colour has a value in both themes', () {
      // Catches a token added to light and forgotten in dark.
      expect(AppColors.light.toString(), isNot(contains('null')));
      expect(AppColors.dark.toString(), isNot(contains('null')));
    });

    testWidgets('the typeface is Onest everywhere', (tester) async {
      await tester.pumpWidget(wrap(const Text('123')));
      final theme = Theme.of(tester.element(find.byType(Text)));
      expect(theme.textTheme.bodyMedium?.fontFamily, 'Onest');
    });

    // Onest's default digits are proportional, so a column of amounts would
    // not line up without this.
    testWidgets('amount styles request tabular figures', (tester) async {
      await tester.pumpWidget(wrap(const SizedBox()));
      final context = tester.element(find.byType(SizedBox));

      expect(AppText.amount(context).fontFeatures, contains(const FontFeature.tabularFigures()));
      expect(AppText.figure(context).fontFeatures, contains(const FontFeature.tabularFigures()));
    });
  });

  group('glossary', () {
    testWidgets('every term has both a label and an explanation', (tester) async {
      await tester.pumpWidget(wrap(const SizedBox()));
      final l10n = AppLocalizations.of(tester.element(find.byType(SizedBox)));

      for (final term in Term.values) {
        expect(term.label(l10n), isNotEmpty, reason: '${term.name} has no label');
        expect(term.tip(l10n), isNotEmpty, reason: '${term.name} has no tooltip');
        expect(
          term.tip(l10n),
          isNot(equals(term.label(l10n))),
          reason: '${term.name} repeats its label instead of explaining it',
        );
      }
    });

    testWidgets('no two terms share an explanation', (tester) async {
      await tester.pumpWidget(wrap(const SizedBox()));
      final l10n = AppLocalizations.of(tester.element(find.byType(SizedBox)));

      final seen = <String, Term>{};
      for (final term in Term.values) {
        final tip = term.tip(l10n);
        expect(
          seen.containsKey(tip),
          isFalse,
          reason: '${term.name} and ${seen[tip]?.name} have the same explanation',
        );
        seen[tip] = term;
      }
    });
  });

  group('TermTooltip', () {
    testWidgets('shows the term label and carries its explanation', (tester) async {
      await tester.pumpWidget(wrap(const TermLabel(term: Term.debit)));
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(tester.element(find.byType(TermLabel)));
      expect(find.text(l10n.termDebit), findsOneWidget);

      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, l10n.termDebitTip);
    });

    testWidgets('the explanation reaches a screen reader too', (tester) async {
      await tester.pumpWidget(wrap(const TermLabel(term: Term.rebillable)));

      final l10n = AppLocalizations.of(tester.element(find.byType(TermLabel)));
      final semantics = tester.widget<Semantics>(
        find.ancestor(of: find.byType(Tooltip), matching: find.byType(Semantics)).first,
      );
      expect(semantics.properties.tooltip, contains(l10n.termRebillableTip));
    });

    testWidgets('the question mark icon appears only when asked for', (tester) async {
      await tester.pumpWidget(wrap(const TermLabel(term: Term.credit)));
      expect(find.byIcon(Icons.help_outline), findsNothing);

      await tester.pumpWidget(wrap(const TermLabel(term: Term.credit, showIcon: true)));
      expect(find.byIcon(Icons.help_outline), findsOneWidget);
    });
  });
}
