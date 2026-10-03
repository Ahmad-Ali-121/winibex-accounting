import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/money/money.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_panel.dart';
import '../../../core/widgets/money_text.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/dashboard_providers.dart';
import '../data/dashboard_repository.dart';

/// The home screen. A glance at where the money is, and what needs attention.
///
/// Every figure is the server's. Nothing here adds anything up, and after any
/// write the screen asks again rather than adjusting a number locally.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final summary = ref.watch(dashboardSummaryProvider);

    return switch (summary) {
      AsyncData(:final value) => _Body(summary: value),
      AsyncError(:final error) => ErrorPanel.from(
          error,
          networkMessage: l10n.errNetwork,
          serverMessage: l10n.errServer,
          retryLabel: l10n.actionRetry,
          onRetry: () => ref.invalidate(dashboardSummaryProvider),
        ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.summary});
  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            Text(l10n.dashboardTitle, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xl),

            _CashCard(amount: summary.cashHeld, merged: summary.historyMerged),
            const SizedBox(height: AppSpacing.lg),

            Row(
              children: [
                Expanded(child: _MonthCard(label: l10n.dashboardInThisMonth, amount: summary.monthIn, positive: true)),
                const SizedBox(width: AppSpacing.lg),
                Expanded(child: _MonthCard(label: l10n.dashboardOutThisMonth, amount: summary.monthOut, positive: false)),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            if (summary.pendingCount > 0)
              _ActionTile(
                label: l10n.dashboardWaitingApproval(summary.pendingCount),
                onTap: () => context.go(Routes.approvals),
              ),
            if (summary.openFlagCount > 0)
              _ActionTile(
                label: l10n.dashboardOpenFlags(summary.openFlagCount),
                onTap: () => context.go(Routes.flags),
              ),
          ],
        ),
      ),
    );
  }
}

class _CashCard extends StatelessWidget {
  const _CashCard({required this.amount, required this.merged});
  final Money amount;
  final bool merged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.rule),
        borderRadius: BorderRadius.circular(AppRadii.container),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.dashboardCashHeld, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          MoneyText.figure(amount, withCurrency: true),
          if (!merged) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.dashboardBeforeHistory, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

class _MonthCard extends StatelessWidget {
  const _MonthCard({required this.label, required this.amount, required this.positive});
  final String label;
  final Money amount;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.rule),
        borderRadius: BorderRadius.circular(AppRadii.container),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            amount.format(withCurrency: true),
            style: AppText.amount(context, size: 20, weight: FontWeight.w600).copyWith(
              color: positive ? colors.moneyIn : colors.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Material(
        color: colors.pendingSoft,
        borderRadius: BorderRadius.circular(AppRadii.container),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.container),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.pending)),
                ),
                Icon(Icons.arrow_forward, size: 16, color: colors.pending),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
