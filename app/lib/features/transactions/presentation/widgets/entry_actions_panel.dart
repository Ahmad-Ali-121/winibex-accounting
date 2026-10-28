import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/error_message.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/money_text.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/ledger_providers.dart';
import '../../data/transactions_repository.dart';
import '../../domain/ledger.dart';

/// What can be done with an entry that is not in the books yet. Decision 067.
///
///   draft     Edit
///   pending   Take back to fix, by the person who sent it
///   rejected  Fix and send again
///
/// Taking back and fixing first turn the entry into a draft on the server,
/// then [onEdit] opens it in the entry form. The server says no in words when
/// this person may not, and that is shown here.
Future<void> showEntryActions(BuildContext context, TransactionSummary entry, ValueChanged<int> onEdit) {
  return showDialog<void>(context: context, builder: (_) => _EntryActions(entry: entry, onEdit: onEdit));
}

class _EntryActions extends ConsumerStatefulWidget {
  const _EntryActions({required this.entry, required this.onEdit});

  final TransactionSummary entry;
  final ValueChanged<int> onEdit;

  @override
  ConsumerState<_EntryActions> createState() => _EntryActionsState();
}

class _EntryActionsState extends ConsumerState<_EntryActions> {
  bool _busy = false;
  Object? _refusal;

  Future<void> _go() async {
    final navigator = Navigator.of(context);
    final entry = widget.entry;
    if (entry.status != 'draft') {
      setState(() {
        _busy = true;
        _refusal = null;
      });
      try {
        await ref.read(transactionsRepositoryProvider).reopen(entry.id);
      } catch (error) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _refusal = error;
        });
        return;
      }
      ref.invalidate(ledgerPageProvider);
      ref.invalidate(approvalsProvider);
    }
    navigator.pop();
    widget.onEdit(entry.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final entry = widget.entry;

    final (explain, action) = switch (entry.status) {
      'pending' => (l10n.entryPendingExplain, l10n.actionTakeBack),
      'rejected' => (l10n.entryRejectedExplain, l10n.actionFixAndResend),
      _ => (l10n.entryDraftExplain, l10n.actionEdit),
    };

    return AlertDialog(
      title: Text(entry.description),
      content: SizedBox(
        width: AppSizes.dialogWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text('${entry.date}  ·  ${entry.accountName ?? ''}', style: text.bodySmall)),
                MoneyText(entry.signedAmount, size: 15, weight: FontWeight.w600),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(explain, style: text.bodyMedium),
            if (_refusal != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                errorMessageFor(_refusal!, network: l10n.errNetwork, server: l10n.errServer),
                style: text.bodyMedium?.copyWith(color: colors.negative),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.of(context).pop(), child: Text(l10n.actionClose)),
        FilledButton(onPressed: _busy ? null : _go, child: Text(action)),
      ],
    );
  }
}
