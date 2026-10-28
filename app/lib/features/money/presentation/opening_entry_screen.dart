import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/error_message.dart';
import '../../../core/api/idempotency_key.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_panel.dart';
import '../../../core/widgets/money_text.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../transactions/presentation/widgets/money_field.dart';
import '../application/money_providers.dart';
import '../data/money_repository.dart';
import '../domain/money_moves.dart';
import 'widgets/send_confirming.dart';

/// The real balances on 30 June 2026, posted once as the opening entry.
/// Decision 037. Owner only; once posted it is shown here read only, and a
/// mistake is corrected with a journal entry, never by editing it.
///
/// Each balance is typed as a plain figure, the way a statement shows it. The
/// server decides the debit or credit side from the account, and works out
/// the balancing figure to 3400 itself. Nothing is added up here.
class OpeningEntryScreen extends ConsumerWidget {
  const OpeningEntryScreen({super.key, this.isOwner = false});

  final bool isOwner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final info = ref.watch(openingInfoProvider);

    return switch (info) {
      AsyncData(:final value) => ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            Text(l10n.openingTitle, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.openingSubtitle(value.balancesAt), style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSpacing.xl),
            if (value.entry != null)
              _PostedEntry(entry: value.entry!, date: value.booksLiveFrom)
            else if (!isOwner)
              Text(l10n.openingOwnerOnly, style: Theme.of(context).textTheme.bodyMedium)
            else
              _OpeningForm(info: value),
          ],
        ),
      AsyncError(:final error) => ErrorPanel.from(
          error,
          networkMessage: l10n.errNetwork,
          serverMessage: l10n.errServer,
          retryLabel: l10n.actionRetry,
          onRetry: () => ref.invalidate(openingInfoProvider),
        ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

class _PostedEntry extends StatelessWidget {
  const _PostedEntry({required this.entry, required this.date});

  final OpeningEntryView entry;
  final String date;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.accentSoft,
            borderRadius: BorderRadius.circular(AppRadii.container),
          ),
          child: Text(
            entry.status == 'reversed'
                ? l10n.openingMerged(entry.journalNumber ?? '')
                : l10n.openingPosted(entry.journalNumber ?? '', date),
            style: text.bodyMedium,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        DecoratedBox(
          decoration: BoxDecoration(color: colors.surface, border: Border.all(color: colors.rule)),
          child: Column(
            children: [
              for (final line in entry.lines)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: colors.rule))),
                  child: Row(
                    children: [
                      Expanded(flex: 5, child: Text('${line.code}  ${line.name}', style: text.bodyMedium)),
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: line.debit.isZero ? const SizedBox.shrink() : MoneyText(line.debit),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: line.credit.isZero ? const SizedBox.shrink() : MoneyText(line.credit),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OpeningForm extends ConsumerStatefulWidget {
  const _OpeningForm({required this.info});
  final OpeningInfo info;

  @override
  ConsumerState<_OpeningForm> createState() => _OpeningFormState();
}

class _OpeningFormState extends ConsumerState<_OpeningForm> {
  final _key = newIdempotencyKey();
  final Map<String, Money> _balances = {};
  bool _busy = false;
  Object? _refusal;

  List<(String, Money)> get _filled => [
        for (final account in widget.info.accounts)
          if ((_balances[account.code]?.minorUnits ?? 0) > 0) (account.code, _balances[account.code]!),
      ];

  Future<void> _review() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final names = {for (final account in widget.info.accounts) account.code: account.name};
    final filled = _filled;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.openingReviewTitle),
        content: SizedBox(
          width: AppSizes.dialogWideWidth,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (code, amount) in filled)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      children: [
                        Expanded(child: Text('$code  ${names[code]}')),
                        MoneyText(amount),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
                Text(l10n.openingReviewNote, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.actionCancel)),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.actionPostOpening)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _busy = true;
      _refusal = null;
    });
    try {
      final number = await sendConfirming(
        context,
        (acknowledged) => ref.read(moneyRepositoryProvider).postOpening(
              balances: filled,
              acknowledged: acknowledged,
              key: _key,
            ),
      );
      if (!mounted) return;
      if (number == null) {
        setState(() => _busy = false);
        return;
      }
      refreshAfterMoneyMoved(ref);
      messenger.showSnackBar(SnackBar(content: Text(l10n.openingDone(number))));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _refusal = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = Theme.of(context).textTheme;

    final groups = [
      ('asset', l10n.openingAssets, l10n.openingAssetsHint),
      ('liability', l10n.openingLiabilities, l10n.openingLiabilitiesHint),
      ('equity', l10n.openingEquity, l10n.openingEquityHint),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.openingHowTo, style: text.bodyMedium),
        for (final (type, title, hint) in groups) ...[
          const SizedBox(height: AppSpacing.xl),
          Text(title, style: text.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(hint, style: text.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          for (final account in widget.info.accounts.where((a) => a.type == type))
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(child: Text('${account.code}  ${account.name}', style: text.bodyMedium)),
                  const SizedBox(width: AppSpacing.md),
                  SizedBox(
                    width: AppSizes.amountFieldWidth,
                    child: MoneyField(
                      key: ValueKey('opening-${account.code}'),
                      label: l10n.fieldBalance,
                      value: _balances[account.code],
                      currency: 'PKR',
                      onChanged: (amount) => setState(() => _balances[account.code] = amount),
                    ),
                  ),
                ],
              ),
            ),
        ],
        const SizedBox(height: AppSpacing.xl),
        if (_refusal != null) ...[
          Text(
            errorMessageFor(_refusal!, network: l10n.errNetwork, server: l10n.errServer),
            style: text.bodyMedium?.copyWith(color: colors.negative),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: _filled.isEmpty || _busy ? null : _review,
            child: Text(l10n.actionReviewOpening),
          ),
        ),
      ],
    );
  }
}
