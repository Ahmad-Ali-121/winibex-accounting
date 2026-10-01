import 'package:flutter/material.dart';

import '../../../core/glossary/glossary.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/term_tooltip.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Placeholder for Phase 6. It exists now so the shell, the theme, the strings
/// and the tooltip are exercised by something real rather than by nothing.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.navDashboard, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.emptyTransactions, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.xl),

          // Hover or long press either of these to see the glossary working.
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.lg,
            children: [
              for (final term in [Term.debit, Term.credit, Term.trialBalance, Term.runway])
                Container(
                  width: 220,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: Border.all(color: colors.rule),
                    borderRadius: BorderRadius.circular(AppRadii.container),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TermLabel(term: term, showIcon: true),
                      const SizedBox(height: AppSpacing.sm),
                      // Tabular figures, so columns of numbers line up. Any
                      // amount must use AppText.amount or the alignment breaks.
                      Text('0.00', style: AppText.figure(context)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
