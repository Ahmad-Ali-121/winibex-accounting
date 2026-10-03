import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/error_panel.dart';
import '../../../../core/widgets/money_text.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/entry_draft_controller.dart';

/// The journal entry this draft would post, before anything is saved.
///
/// UI-GUIDE wants the double entry visible rather than hidden, so the person
/// learns what the books are doing with what they typed. The lines come from
/// the server: the app never works out a debit or a credit. AGENTS.md.
class JournalPreviewPanel extends ConsumerWidget {
  const JournalPreviewPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final preview = ref.watch(journalPreviewProvider);

    return switch (preview) {
      AsyncData(value: null) => Text(
          l10n.previewNotReady,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      AsyncData(:final value) => DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.rule),
          ),
          child: Column(
            children: [
              _Header(),
              for (final line in value!.lines)
                _LineRow(
                  code: line.code,
                  name: line.name,
                  debit: line.isDebit ? line.debit : null,
                  credit: line.isDebit ? null : line.credit,
                ),
              _TotalsRow(debits: value.debits, credits: value.credits),
            ],
          ),
        ),
      AsyncError(:final error) => ErrorPanel.from(
          error,
          networkMessage: l10n.errNetwork,
          serverMessage: l10n.errServer,
          retryLabel: l10n.actionRetry,
          onRetry: () => ref.invalidate(journalPreviewProvider),
        ),
      _ => const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: LinearProgressIndicator(),
        ),
    };
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final style = Theme.of(context).textTheme.labelSmall;

    return Container(
      height: AppSizes.rowCompact,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceSunken,
        border: Border(bottom: BorderSide(color: colors.rule)),
      ),
      child: Row(
        children: [
          Expanded(flex: 5, child: Text(l10n.journalColumnAccount, style: style)),
          Expanded(
            flex: 2,
            child: Align(alignment: Alignment.centerRight, child: Text(l10n.termDebit, style: style)),
          ),
          Expanded(
            flex: 2,
            child: Align(alignment: Alignment.centerRight, child: Text(l10n.termCredit, style: style)),
          ),
        ],
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({required this.code, required this.name, this.debit, this.credit});

  final String code;
  final String name;
  final dynamic debit;
  final dynamic credit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.rule)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              '$code  $name',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: debit == null ? const SizedBox.shrink() : MoneyText(debit),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: credit == null ? const SizedBox.shrink() : MoneyText(credit),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalsRow extends StatelessWidget {
  const _TotalsRow({required this.debits, required this.credits});

  final dynamic debits;
  final dynamic credits;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceSunken,
        border: Border(top: BorderSide(color: colors.ruleStrong)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(l10n.journalBalanced, style: Theme.of(context).textTheme.titleSmall),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: MoneyText(debits, weight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: MoneyText(credits, weight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
