import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/money_text.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../accounts/application/accounts_providers.dart';
import '../../application/money_providers.dart';
import '../move_money_dialog.dart';
import '../pay_back_dialog.dart';

/// What the owner and admins can do from the Accounts screen: move money,
/// pay someone back, and the two things that ask for it. Petty cash below its
/// float, and people the company owes. Decision 065.
///
/// Every figure is the server's. A suggested top-up is the server's
/// suggestedTopUp, never worked out here.
class MoneyActionsPanel extends ConsumerWidget {
  const MoneyActionsPanel({super.key, this.onOpeningBalances});

  /// Shown to the owner only.
  final VoidCallback? onOpeningBalances;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            FilledButton.icon(
              onPressed: () => showMoveMoney(context),
              icon: const Icon(Icons.swap_horiz),
              label: Text(l10n.actionMoveMoney),
            ),
            OutlinedButton.icon(
              onPressed: () => showPayBack(context),
              icon: const Icon(Icons.undo),
              label: Text(l10n.actionPaySomeoneBack),
            ),
            if (onOpeningBalances != null)
              TextButton.icon(
                onPressed: onOpeningBalances,
                icon: const Icon(Icons.flag_outlined),
                label: Text(l10n.actionOpeningBalances),
              ),
          ],
        ),
        const _PettyCashHint(),
        const _PeopleOwed(),
      ],
    );
  }
}

class _PettyCashHint extends ConsumerWidget {
  const _PettyCashHint();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final status = ref.watch(pettyCashProvider).value;
    if (status == null || status.imprest == null) return const SizedBox.shrink();

    final low = status.accounts.where((item) => item.belowFloat).toList();
    if (low.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        for (final item in low)
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.lg),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.pendingSoft,
              borderRadius: BorderRadius.circular(AppRadii.container),
            ),
            child: Row(
              children: [
                Icon(Icons.savings_outlined, color: colors.pending),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppSpacing.xs,
                    children: [
                      Text(l10n.pettyLowLead(item.account.name), style: text.bodyMedium),
                      MoneyText(item.account.balance, withCurrency: true),
                      Text(l10n.pettyLowFloat, style: text.bodyMedium),
                      MoneyText(status.imprest!, withCurrency: true),
                      Text(l10n.pettyLowSuggest, style: text.bodyMedium),
                      MoneyText(item.suggestedTopUp, withCurrency: true, weight: FontWeight.w600),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                FilledButton.tonal(
                  onPressed: () => showMoveMoney(
                    context,
                    toAccountId: item.account.id,
                    amount: item.suggestedTopUp,
                  ),
                  child: Text(l10n.actionTopUp),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PeopleOwed extends ConsumerWidget {
  const _PeopleOwed();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final people = ref.watch(peopleOwedProvider).value;
    if (people == null) return const SizedBox.shrink();
    final owed = people.where((person) => person.owed.minorUnits > 0).toList();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.owedTitle, style: text.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.owedHint, style: text.bodySmall),
          const SizedBox(height: AppSpacing.md),
          if (owed.isEmpty)
            Text(l10n.owedNobody, style: text.bodySmall)
          else
            DecoratedBox(
              decoration: BoxDecoration(color: colors.surface, border: Border.all(color: colors.rule)),
              child: Column(
                children: [
                  for (final person in owed)
                    Container(
                      height: AppSizes.rowComfortable,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: colors.rule))),
                      child: Row(
                        children: [
                          Expanded(child: Text(person.name, style: text.bodyMedium)),
                          MoneyText(person.owed),
                          const SizedBox(width: AppSpacing.lg),
                          TextButton(
                            onPressed: () => showPayBack(context, personUserId: person.userId),
                            child: Text(l10n.actionPayBack),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
