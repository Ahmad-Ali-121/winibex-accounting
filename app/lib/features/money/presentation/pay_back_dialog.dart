import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/error_message.dart';
import '../../../core/api/idempotency_key.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/date_field.dart';
import '../../../core/widgets/money_text.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../accounts/application/accounts_providers.dart';
import '../../accounts/domain/account.dart';
import '../../transactions/presentation/widgets/money_field.dart';
import '../application/money_providers.dart';
import '../data/money_repository.dart';
import '../domain/money_moves.dart';
import 'widgets/send_confirming.dart';

/// Paying back someone who paid company costs themselves. They pick the
/// costs being paid back, each in full unless changed, and the server clears
/// what the company owes them. Decision 020.
Future<void> showPayBack(BuildContext context, {int? personUserId}) {
  return showDialog<void>(
    context: context,
    builder: (_) => PayBackDialog(personUserId: personUserId),
  );
}

class PayBackDialog extends ConsumerStatefulWidget {
  const PayBackDialog({super.key, this.personUserId});
  final int? personUserId;

  @override
  ConsumerState<PayBackDialog> createState() => _PayBackDialogState();
}

class _PayBackDialogState extends ConsumerState<PayBackDialog> {
  final _key = newIdempotencyKey();

  late int? _person = widget.personUserId;
  int? _account;
  String _date = DateField.today();

  /// The cost and the amount being paid back on it, for every ticked cost.
  final Map<int, Money> _paying = {};
  bool _busy = false;
  Object? _refusal;

  bool get _ready =>
      _person != null && _account != null && _paying.isNotEmpty && _paying.values.every((m) => m.minorUnits > 0);

  void _choosePerson(int? id) => setState(() {
        _person = id;
        _paying.clear();
      });

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() {
      _busy = true;
      _refusal = null;
    });
    try {
      final result = await sendConfirming(
        context,
        (acknowledged) => ref.read(moneyRepositoryProvider).payBack(
              personUserId: _person!,
              accountId: _account!,
              date: _date,
              items: [for (final entry in _paying.entries) (entry.key, entry.value)],
              acknowledged: acknowledged,
              key: _key,
            ),
      );
      if (!mounted) return;
      if (result == null) {
        setState(() => _busy = false);
        return;
      }
      final (journalNumber, owedAfter) = result;
      refreshAfterMoneyMoved(ref);
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.payBackDone(journalNumber, owedAfter.format()))),
      );
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
    final people = ref.watch(peopleOwedProvider).value?.where((p) => p.owed.minorUnits > 0).toList() ??
        const <PersonOwed>[];
    final accounts = ref.watch(accountsProvider()).value?.accounts.where((a) => a.isActive).toList() ??
        const <Account>[];

    return AlertDialog(
      title: Text(l10n.payBackTitle),
      content: SizedBox(
        width: AppSizes.dialogWideWidth,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.payBackHint, style: text.bodySmall),
              const SizedBox(height: AppSpacing.lg),
              DropdownMenu<int>(
                key: const ValueKey('pay-person'),
                initialSelection: _person,
                expandedInsets: EdgeInsets.zero,
                label: Text(l10n.fieldPayBackPerson),
                dropdownMenuEntries: [
                  for (final person in people) DropdownMenuEntry(value: person.userId, label: person.name),
                ],
                onSelected: _choosePerson,
              ),
              if (_person != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(l10n.payBackCostsTitle, style: text.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                _Costs(
                  userId: _person!,
                  paying: _paying,
                  onTick: (cost, ticked) => setState(() {
                    if (ticked) {
                      _paying[cost.transactionId] = cost.remaining;
                    } else {
                      _paying.remove(cost.transactionId);
                    }
                  }),
                  onAmount: (cost, amount) => setState(() => _paying[cost.transactionId] = amount),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              DropdownMenu<int>(
                key: const ValueKey('pay-from'),
                initialSelection: _account,
                expandedInsets: EdgeInsets.zero,
                label: Text(l10n.fieldPaidFrom),
                dropdownMenuEntries: [
                  for (final account in accounts) DropdownMenuEntry(value: account.id, label: account.name),
                ],
                onSelected: (id) => setState(() => _account = id),
              ),
              const SizedBox(height: AppSpacing.md),
              DateField(
                value: _date,
                onChanged: (value) => setState(() => _date = value),
                label: l10n.fieldDate,
                hint: l10n.hintDateFormat,
                pickTooltip: l10n.actionPickDate,
              ),
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
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.of(context).pop(), child: Text(l10n.actionCancel)),
        FilledButton(onPressed: _ready && !_busy ? _send : null, child: Text(l10n.actionPayBack)),
      ],
    );
  }
}

class _Costs extends ConsumerWidget {
  const _Costs({required this.userId, required this.paying, required this.onTick, required this.onAmount});

  final int userId;
  final Map<int, Money> paying;
  final void Function(OwedCost cost, bool ticked) onTick;
  final void Function(OwedCost cost, Money amount) onAmount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final costs = ref.watch(owedCostsProvider(userId: userId));

    return switch (costs) {
      AsyncData(:final value) when value.isEmpty => Text(l10n.payBackNothingOwed, style: text.bodySmall),
      AsyncData(:final value) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final cost in value)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: paying.containsKey(cost.transactionId),
                      onChanged: (ticked) => onTick(cost, ticked ?? false),
                      title: Text(cost.description, style: text.bodyMedium),
                      subtitle: Text(
                        [cost.date, if (cost.journalNumber != null) cost.journalNumber!].join('  ·  '),
                        style: text.bodySmall,
                      ),
                      secondary: MoneyText(cost.remaining),
                    ),
                    if (paying.containsKey(cost.transactionId))
                      Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.xxl),
                        child: MoneyField(
                          label: l10n.fieldPayingBack,
                          value: paying[cost.transactionId],
                          currency: 'PKR',
                          helper: l10n.hintPayingBack,
                          onChanged: (amount) => onAmount(cost, amount),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      AsyncError(:final error) => Text(errorMessageFor(error, network: l10n.errNetwork, server: l10n.errServer)),
      _ => const LinearProgressIndicator(),
    };
  }
}
