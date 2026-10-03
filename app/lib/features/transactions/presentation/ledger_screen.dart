import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_panel.dart';
import '../../../core/widgets/money_text.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/ledger_providers.dart';
import '../domain/ledger.dart';
import 'widgets/journal_panel.dart';

/// Every entry, searched on the server.
///
/// Reversed entries stay here, struck through rather than removed, and so do
/// the entries that reversed them. Nothing is ever deleted from the book.
/// Decision 012.
class LedgerScreen extends ConsumerWidget {
  const LedgerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final page = ref.watch(ledgerPageProvider);

    return Column(
      children: [
        const _SearchBar(),
        Expanded(
          child: switch (page) {
            AsyncData(:final value) when value.transactions.isEmpty => EmptyState(
                title: l10n.emptyLedgerTitle,
                detail: l10n.emptyLedgerDetail,
              ),
            AsyncData(:final value) => _LedgerTable(page: value),
            AsyncError(:final error) => ErrorPanel.from(
                error,
                networkMessage: l10n.errNetwork,
                serverMessage: l10n.errServer,
                retryLabel: l10n.actionRetry,
                onRetry: () => ref.invalidate(ledgerPageProvider),
              ),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ),
      ],
    );
  }
}

class _SearchBar extends ConsumerWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.rule)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.hintSearchLedger,
                prefixIcon: const Icon(Icons.search, size: 18),
              ),
              // Searching runs on the server across every row, not across the
              // page in front of you. Decision 022.
              onSubmitted: (value) => ref.read(ledgerFiltersProvider.notifier).setSearch(value),
            ),
          ),
        ],
      ),
    );
  }
}

class _LedgerTable extends ConsumerWidget {
  const _LedgerTable({required this.page});

  final LedgerPage page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: page.transactions.length,
            itemBuilder: (context, index) => _LedgerRow(entry: page.transactions[index]),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: colors.surfaceSunken,
            border: Border(top: BorderSide(color: colors.rule)),
          ),
          child: Row(
            children: [
              Text(
                l10n.ledgerShowing(page.transactions.length, page.total),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              TextButton(
                onPressed: page.page > 1
                    ? () => ref.read(ledgerFiltersProvider.notifier).previousPage()
                    : null,
                child: Text(l10n.actionPrevious),
              ),
              TextButton(
                onPressed: page.hasMore
                    ? () => ref.read(ledgerFiltersProvider.notifier).nextPage()
                    : null,
                child: Text(l10n.actionNextPage),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.entry});

  final TransactionSummary entry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return InkWell(
      onTap: entry.isPosted ? () => showJournalPanel(context, entry) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.rule)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 92,
              child: Text(entry.date, style: Theme.of(context).textTheme.bodySmall),
            ),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          // A reversed entry is struck through, not hidden.
                          decoration: entry.isReversed ? TextDecoration.lineThrough : null,
                          color: entry.isReversed ? colors.reversed : null,
                        ),
                  ),
                  Text(
                    [entry.accountName, entry.categoryName, entry.journalNumber]
                        .where((part) => part != null && part.isNotEmpty)
                        .join('  ·  '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (entry.status != 'posted' && entry.status != 'reversed')
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: _StatusTag(status: entry.status),
              ),
            if (entry.flagCount > 0)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: Tooltip(
                  message: l10n.ledgerFlagged,
                  child: Icon(Icons.flag_outlined, size: 16, color: colors.pending),
                ),
              ),
            SizedBox(
              width: 140,
              child: Align(
                alignment: Alignment.centerRight,
                child: MoneyText(entry.signedAmount),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    final (label, colour) = switch (status) {
      'draft' => (l10n.statusDraft, colors.reversed),
      'pending' => (l10n.statusPending, colors.pending),
      'rejected' => (l10n.statusRejected, colors.negative),
      _ => (status, colors.textMuted),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: colour),
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colour),
      ),
    );
  }
}
