import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/money_text.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/ledger_providers.dart';
import '../../domain/ledger.dart';

/// The double entry behind one posted transaction.
///
/// UI-GUIDE wants this on every posted entry, because the whole point of the
/// system is that the books are visible rather than hidden behind a list of
/// payments.
Future<void> showJournalPanel(BuildContext context, TransactionSummary entry) {
  return showDialog(
    context: context,
    builder: (context) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: _JournalPanel(entry: entry),
      ),
    ),
  );
}

class _JournalPanel extends ConsumerWidget {
  const _JournalPanel({required this.entry});

  final TransactionSummary entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final lines = ref.watch(entryJournalProvider(transactionId: entry.id));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.journalNumber ?? '', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: AppSpacing.xxs),
              Text(entry.description, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '${entry.date}  ·  ${entry.accountName ?? ''}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (entry.isReversed) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(l10n.ledgerReversedNotice,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.reversed),),
              ],
            ],
          ),
        ),
        const Divider(height: 1),
        switch (lines) {
          AsyncData(:final value) => Column(
              children: [
                for (final line in value)
                  Container(
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
                            '${line.code}  ${line.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: line.isDebit ? MoneyText(line.debit) : const SizedBox.shrink(),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: line.isDebit ? const SizedBox.shrink() : MoneyText(line.credit),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          AsyncError() => Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(l10n.errServer, style: Theme.of(context).textTheme.bodySmall),
            ),
          _ => const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: LinearProgressIndicator(),
            ),
        },
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.actionClose),
            ),
          ),
        ),
      ],
    );
  }
}
