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
import 'widgets/send_confirming.dart';

/// Moving money from one company account to another: cash drawn from the
/// bank, petty cash topped up. Two linked entries through 1118, posted
/// together or not at all. A bank fee is recorded as a bank charge.
Future<void> showMoveMoney(BuildContext context, {int? toAccountId, Money? amount}) {
  return showDialog<void>(
    context: context,
    builder: (_) => MoveMoneyDialog(toAccountId: toAccountId, amount: amount),
  );
}

class MoveMoneyDialog extends ConsumerStatefulWidget {
  const MoveMoneyDialog({super.key, this.toAccountId, this.amount});

  final int? toAccountId;
  final Money? amount;

  @override
  ConsumerState<MoveMoneyDialog> createState() => _MoveMoneyDialogState();
}

class _MoveMoneyDialogState extends ConsumerState<MoveMoneyDialog> {
  /// One key for this transfer, kept across a retry, so a lost answer cannot
  /// move the money twice.
  final _key = newIdempotencyKey();

  int? _from;
  late int? _to = widget.toAccountId;
  late Money? _amount = widget.amount;
  Money? _fee;
  String _date = DateField.today();
  String _description = '';
  bool _busy = false;
  Object? _refusal;

  bool get _ready => _from != null && _to != null && _from != _to && (_amount?.minorUnits ?? 0) > 0;

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() {
      _busy = true;
      _refusal = null;
    });
    try {
      final numbers = await sendConfirming(
        context,
        (acknowledged) => ref.read(moneyRepositoryProvider).transfer(
              date: _date,
              fromAccountId: _from!,
              toAccountId: _to!,
              amount: _amount!,
              fee: _fee,
              description: _description,
              acknowledged: acknowledged,
              key: _key,
            ),
      );
      if (!mounted) return;
      if (numbers == null) {
        setState(() => _busy = false);
        return;
      }
      refreshAfterMoneyMoved(ref);
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(l10n.moveMoneyDone(numbers.join(', ')))));
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
    final accounts = ref.watch(accountsProvider()).value?.accounts.where((a) => a.isActive).toList() ??
        const <Account>[];

    Account? find(int? id) => accounts.where((a) => a.id == id).firstOrNull;

    Widget holds(int? id) {
      final account = find(id);
      if (account == null) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs, left: AppSpacing.md),
        child: Row(
          children: [
            Text('${l10n.fieldHoldsNow} ', style: text.bodySmall),
            MoneyText(account.balance, size: 12.5, weight: FontWeight.w400, muted: true),
          ],
        ),
      );
    }

    return AlertDialog(
      title: Text(l10n.moveMoneyTitle),
      content: SizedBox(
        width: AppSizes.dialogWideWidth,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.moveMoneyHint, style: text.bodySmall),
              const SizedBox(height: AppSpacing.lg),
              DropdownMenu<int>(
                key: const ValueKey('move-from'),
                initialSelection: _from,
                expandedInsets: EdgeInsets.zero,
                label: Text(l10n.fieldMoveFrom),
                dropdownMenuEntries: [
                  for (final account in accounts) DropdownMenuEntry(value: account.id, label: account.name),
                ],
                onSelected: (id) => setState(() => _from = id),
              ),
              holds(_from),
              const SizedBox(height: AppSpacing.md),
              DropdownMenu<int>(
                key: const ValueKey('move-to'),
                initialSelection: _to,
                expandedInsets: EdgeInsets.zero,
                label: Text(l10n.fieldMoveTo),
                dropdownMenuEntries: [
                  for (final account in accounts) DropdownMenuEntry(value: account.id, label: account.name),
                ],
                onSelected: (id) => setState(() => _to = id),
              ),
              holds(_to),
              if (_from != null && _from == _to) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(l10n.moveMoneySameAccount, style: text.bodySmall?.copyWith(color: colors.negative)),
              ],
              const SizedBox(height: AppSpacing.md),
              MoneyField(
                label: l10n.fieldAmount,
                value: _amount,
                currency: 'PKR',
                onChanged: (value) => setState(() => _amount = value),
              ),
              const SizedBox(height: AppSpacing.md),
              MoneyField(
                label: l10n.fieldTransferFee,
                value: _fee,
                currency: 'PKR',
                helper: l10n.hintTransferFee,
                onChanged: (value) => setState(() => _fee = value),
              ),
              const SizedBox(height: AppSpacing.md),
              DateField(
                value: _date,
                onChanged: (value) => setState(() => _date = value),
                label: l10n.fieldDate,
                hint: l10n.hintDateFormat,
                pickTooltip: l10n.actionPickDate,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                decoration: InputDecoration(labelText: l10n.fieldDescriptionOptional),
                maxLength: 255,
                onChanged: (value) => _description = value,
              ),
              if (_refusal != null)
                Text(
                  errorMessageFor(_refusal!, network: l10n.errNetwork, server: l10n.errServer),
                  style: text.bodyMedium?.copyWith(color: colors.negative),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.of(context).pop(), child: Text(l10n.actionCancel)),
        FilledButton(onPressed: _ready && !_busy ? _send : null, child: Text(l10n.actionMoveMoney)),
      ],
    );
  }
}
