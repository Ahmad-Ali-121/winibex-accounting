import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_panel.dart';
import '../../../core/widgets/money_text.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/accounts_providers.dart';
import '../domain/account.dart';

/// What the company holds, account by account.
///
/// Every figure here comes from the server. Nothing is added up on this side,
/// including the total: two places that both know how to total a set of
/// balances will eventually disagree, and only one of them would be right.
class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final summary = ref.watch(accountsProvider());

    return switch (summary) {
      AsyncData(:final value) when value.accounts.isEmpty =>
        EmptyState(title: l10n.emptyAccountsTitle, detail: l10n.emptyAccountsDetail),
      AsyncData(:final value) => _AccountsBody(summary: value),
      AsyncError(:final error) => ErrorPanel.from(
          error,
          networkMessage: l10n.errNetwork,
          serverMessage: l10n.errServer,
          retryLabel: l10n.actionRetry,
          onRetry: () => ref.invalidate(accountsProvider),
        ),
      _ => const _AccountsSkeleton(),
    };
  }
}

class _AccountsBody extends StatelessWidget {
  const _AccountsBody({required this.summary});

  final AccountsSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            Text(l10n.accountsTitle, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.accountsSubtitle, style: Theme.of(context).textTheme.bodySmall),

            // While history is unmerged, these balances deliberately exclude
            // everything before 1 July 2026. Saying so beats someone deciding
            // the numbers look wrong.
            if (!summary.historyMerged) ...[
              const SizedBox(height: AppSpacing.lg),
              _Notice(text: l10n.accountsHistoryNotMerged),
            ],

            const SizedBox(height: AppSpacing.xl),
            _AccountsTable(summary: summary),
          ],
        ),
      ),
    );
  }
}

/// Ruled, like a ledger. No cards, no shadows: rows separated by lines.
class _AccountsTable extends StatelessWidget {
  const _AccountsTable({required this.summary});

  final AccountsSummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.rule),
      ),
      child: Column(
        children: [
          _HeaderRow(),
          for (final account in summary.accounts)
            _AccountRow(account: account, isLast: false),
          _TotalRow(total: summary.total, label: l10n.accountsTotal),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
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
          Expanded(flex: 4, child: Text(l10n.accountsColumnAccount, style: style)),
          Expanded(flex: 2, child: Text(l10n.accountsColumnLedger, style: style)),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(l10n.accountsColumnBalance, style: style),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.account, required this.isLast});

  final Account account;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return Container(
      height: AppSizes.rowComfortable,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: colors.rule)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    account.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                if (!account.isActive) ...[
                  const SizedBox(width: AppSpacing.sm),
                  _Tag(text: l10n.accountsInactive),
                ],
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${account.ledger.code}  ${_typeLabel(l10n, account.type)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: MoneyText(account.balance),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.total, required this.label});

  final Money total;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      height: AppSizes.rowComfortable,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceSunken,
        border: Border(top: BorderSide(color: colors.ruleStrong)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Text(label, style: Theme.of(context).textTheme.titleSmall),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: MoneyText(total, size: 15, weight: FontWeight.w600, withCurrency: true),
            ),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: colors.pendingSoft,
        borderRadius: BorderRadius.circular(AppRadii.container),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.pending),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: colors.reversedSoft,
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.reversed),
      ),
    );
  }
}

/// Rows of the right height and shape, so the table does not jump when the
/// real figures arrive.
class _AccountsSkeleton extends StatelessWidget {
  const _AccountsSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < 5; i++)
                Container(
                  height: AppSizes.rowComfortable,
                  margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: colors.surfaceSunken,
                    borderRadius: BorderRadius.circular(AppRadii.control),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String _typeLabel(AppLocalizations l10n, AccountType type) => switch (type) {
      AccountType.bank => l10n.accountTypeBank,
      AccountType.cash => l10n.accountTypeCash,
      AccountType.pettyCash => l10n.accountTypePettyCash,
      AccountType.cheque => l10n.accountTypeCheque,
      AccountType.passThrough => l10n.accountTypePassThrough,
      AccountType.unknown => '',
    };
