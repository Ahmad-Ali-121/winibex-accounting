import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/error_message.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_panel.dart';
import '../../../core/widgets/money_text.dart';
import '../../../core/widgets/reason_dialog.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/flags_providers.dart';
import '../data/flags_repository.dart';

/// Things worth a second look.
///
/// A warning someone confirmed on the way past, or a flag the system raised,
/// such as a payment with no receipt. Nothing here is an error: the entries
/// are posted. This is the list an owner skims to keep the books honest.
class FlagsScreen extends ConsumerWidget {
  const FlagsScreen({super.key, this.canReview = false});

  /// The owner or an admin, who may mark a flag reviewed. The server decides
  /// for real; this only decides whether the button is offered.
  final bool canReview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final flags = ref.watch(openFlagsProvider);

    return switch (flags) {
      AsyncData(:final value) when value.isEmpty =>
        EmptyState(title: l10n.emptyFlagsTitle, detail: l10n.emptyFlagsDetail),
      AsyncData(:final value) => ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: value.length,
          itemBuilder: (context, index) => _FlagCard(flag: value[index], canReview: canReview),
        ),
      AsyncError(:final error) => ErrorPanel.from(
          error,
          networkMessage: l10n.errNetwork,
          serverMessage: l10n.errServer,
          retryLabel: l10n.actionRetry,
          onRetry: () => ref.invalidate(openFlagsProvider),
        ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

class _FlagCard extends ConsumerWidget {
  const _FlagCard({required this.flag, required this.canReview});
  final EntryFlag flag;
  final bool canReview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final tone = flag.isWarning ? colors.pending : colors.info;

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
              Icon(
                flag.isWarning ? Icons.error_outline : Icons.flag_outlined,
                size: 16,
                color: tone,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(_label(l10n, flag.code), style: Theme.of(context).textTheme.labelMedium?.copyWith(color: tone)),
              const Spacer(),
              MoneyText(flag.entryAmount, size: 14, weight: FontWeight.w600),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(flag.entryDescription, style: Theme.of(context).textTheme.bodyMedium),
          if (flag.detail.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(flag.detail, style: Theme.of(context).textTheme.bodySmall),
          ],
          Row(
            children: [
              if (flag.journalNumber != null)
                Text(flag.journalNumber!, style: Theme.of(context).textTheme.bodySmall),
              if (flag.acknowledgedByName != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  l10n.flagsConfirmedBy(flag.acknowledgedByName!),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const Spacer(),
              // A flag is cleared on purpose, with a reason that stays with
              // it. One whose cause went away, such as a receipt arriving,
              // clears itself and never reaches this list. Decision 056.
              if (canReview)
                TextButton(
                  onPressed: () => _markReviewed(context, ref),
                  child: Text(l10n.actionMarkReviewed),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _markReviewed(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);

    // "Reviewed" with no reason is a flag dismissed by reflex. The dialog
    // wants three characters at least, as the server does, and says so.
    final note = await askForReason(
      context,
      title: l10n.markReviewedTitle,
      label: l10n.fieldReviewNote,
      hint: l10n.hintReviewNote,
      confirmLabel: l10n.actionMarkReviewed,
    );

    if (note == null || !context.mounted) return;

    // Taken now: once the flag is resolved the list reloads and this card is
    // gone, so its context cannot be used afterwards.
    final messenger = ScaffoldMessenger.of(context);
    final refusal = await ref.read(flagActionsProvider.notifier).resolve(flag.id, note);

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          refusal == null
              ? l10n.flagMarkedReviewed
              : errorMessageFor(refusal, network: l10n.errNetwork, server: l10n.errServer),
        ),
      ),
    );
  }

  String _label(AppLocalizations l10n, String code) => switch (code) {
        'NO_RECEIPT' => l10n.flagNoReceipt,
        'THIN_DESCRIPTION' => l10n.flagThinDescription,
        'POSSIBLE_DUPLICATE' => l10n.flagPossibleDuplicate,
        'UNUSUAL_AMOUNT' => l10n.flagUnusualAmount,
        'BACKDATED' => l10n.flagBackdated,
        'BANK_BELOW_ZERO' => l10n.flagBankBelowZero,
        'LARGE_CASH' => l10n.flagLargeCash,
        'RATE_DEVIATION' => l10n.flagRateDeviation,
        'REPEATED_DESCRIPTION' => l10n.flagRepeatedDescription,
        _ => code,
      };
}
