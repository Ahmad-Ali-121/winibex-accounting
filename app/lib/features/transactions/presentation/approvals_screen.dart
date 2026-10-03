import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_panel.dart';
import '../../../core/widgets/money_text.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/ledger_providers.dart';
import '../domain/ledger.dart';

/// What is waiting to be approved, oldest first.
///
/// An entry waiting three days matters more than one submitted this morning,
/// which is why the order is not newest first like the ledger.
class ApprovalsScreen extends ConsumerWidget {
  const ApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final approvals = ref.watch(approvalsProvider);

    return switch (approvals) {
      AsyncData(:final value) when value.isEmpty => EmptyState(
          title: l10n.emptyApprovalsTitle,
          detail: l10n.emptyApprovalsDetail,
        ),
      AsyncData(:final value) => ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: value.length,
          itemBuilder: (context, index) => _ApprovalCard(approval: value[index]),
        ),
      AsyncError(:final error) => ErrorPanel.from(
          error,
          networkMessage: l10n.errNetwork,
          serverMessage: l10n.errServer,
          retryLabel: l10n.actionRetry,
          onRetry: () => ref.invalidate(approvalsProvider),
        ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

class _ApprovalCard extends ConsumerWidget {
  const _ApprovalCard({required this.approval});

  final Approval approval;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final entry = approval.summary;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.rule),
        borderRadius: BorderRadius.circular(AppRadii.container),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(entry.description, style: Theme.of(context).textTheme.titleSmall),
              ),
              MoneyText(entry.signedAmount, size: 15, weight: FontWeight.w600),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            [entry.date, entry.accountName, entry.categoryName, entry.createdByName]
                .where((part) => part != null && part.isNotEmpty)
                .join('  ·  '),
            style: Theme.of(context).textTheme.bodySmall,
          ),

          if (entry.flagCount > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(Icons.flag_outlined, size: 14, color: colors.pending),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  l10n.approvalsHasFlags(entry.flagCount),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.pending),
                ),
              ],
            ),
          ],

          const SizedBox(height: AppSpacing.md),

          // Nobody approves their own entry under the same login. Decision 036.
          // Saying so here beats letting someone press approve and get a 403.
          if (approval.isOwnEntry)
            Text(
              l10n.approvalsYourOwn,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textMuted),
            )
          else
            Row(
              children: [
                FilledButton(
                  onPressed: () => ref.read(approvalActionsProvider.notifier).approve(entry.id),
                  child: Text(l10n.actionApprove),
                ),
                const SizedBox(width: AppSpacing.sm),
                OutlinedButton(
                  onPressed: () => _reject(context, ref, entry.id),
                  child: Text(l10n.actionReject),
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// Rejecting always carries a reason. The person who entered it has to know
  /// what to fix, and the reason stays on the entry.
  Future<void> _reject(BuildContext context, WidgetRef ref, int id) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.rejectTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 255,
          decoration: InputDecoration(
            labelText: l10n.fieldReason,
            helperText: l10n.hintRejectReason,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(l10n.actionReject),
          ),
        ],
      ),
    );

    if (reason == null || reason.isEmpty) return;
    await ref.read(approvalActionsProvider.notifier).reject(id, reason);
  }
}
