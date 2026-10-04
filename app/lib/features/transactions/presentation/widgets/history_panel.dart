import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/ledger_providers.dart';
import '../../data/transactions_repository.dart';

/// Who changed an entry, when, and what moved.
///
/// Every change is recorded in the audit log as it happens. This reads it back.
/// Nothing here can alter anything: it is a record, shown so the books can be
/// trusted rather than taken on faith.
Future<void> showHistoryPanel(BuildContext context, int transactionId, String title) {
  return showDialog(
    context: context,
    builder: (context) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: _HistoryPanel(transactionId: transactionId, title: title),
      ),
    ),
  );
}

class _HistoryPanel extends ConsumerWidget {
  const _HistoryPanel({required this.transactionId, required this.title});

  final int transactionId;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final history = ref.watch(entryHistoryProvider(transactionId: transactionId));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.historyTitle, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xxs),
              Text(title, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        const Divider(height: 1),
        Flexible(
          child: switch (history) {
            AsyncData(:final value) when value.isEmpty => Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(l10n.historyEmpty, style: Theme.of(context).textTheme.bodySmall),
              ),
            AsyncData(:final value) => ListView.builder(
                shrinkWrap: true,
                itemCount: value.length,
                itemBuilder: (context, index) => _EventRow(event: value[index]),
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
        ),
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

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event});

  final HistoryEvent event;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.rule)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_actionLabel(l10n, event.action), style: Theme.of(context).textTheme.labelMedium),
              const Spacer(),
              if (event.userName != null)
                Text(event.userName!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          if (event.at != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(_formatWhen(event.at!), style: Theme.of(context).textTheme.bodySmall),
          ],
          for (final change in event.changes)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                '${_fieldLabel(change.field)}: ${_value(change.from)} → ${_value(change.to)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textMuted),
              ),
            ),
        ],
      ),
    );
  }

  String _actionLabel(AppLocalizations l10n, String action) => switch (action) {
        'insert' => l10n.historyCreated,
        'update' => l10n.historyUpdated,
        'status_change' => l10n.historyStatusChanged,
        _ => action,
      };

  // A few fields read better with a label; the rest show their raw key, which
  // is still informative for an audit view.
  String _fieldLabel(String field) => switch (field) {
        'status' => 'Status',
        'amount' => 'Amount',
        'description' => 'Description',
        'journalNumber' => 'Journal number',
        'reason' => 'Reason',
        _ => field,
      };

  String _value(dynamic v) {
    if (v == null) return '—';
    if (v is bool) return v ? 'yes' : 'no';
    return v.toString();
  }

  String _formatWhen(String iso) {
    // The server sends UTC. Shown as the date and time to the minute, which is
    // all an audit view needs.
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    final local = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
  }
}
