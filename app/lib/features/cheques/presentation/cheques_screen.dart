import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/error_message.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/date_field.dart';
import '../../../core/widgets/error_panel.dart';
import '../../../core/widgets/money_text.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../accounts/application/accounts_providers.dart';
import '../../accounts/domain/account.dart';
import '../../transactions/presentation/widgets/money_field.dart';
import '../application/cheques_providers.dart';
import '../domain/cheque.dart';

/// The cheque register: every cheque written, and where each one stands.
/// Decision 066. The money itself is an ordinary entry, linked to the cheque,
/// so the register never becomes a second set of books.
class ChequesScreen extends ConsumerStatefulWidget {
  const ChequesScreen({super.key, this.canManage = false});

  /// The owner and admins write to the register. The server checks again.
  final bool canManage;

  @override
  ConsumerState<ChequesScreen> createState() => _ChequesScreenState();
}

class _ChequesScreenState extends ConsumerState<ChequesScreen> {
  String? _status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final register = ref.watch(chequeRegisterProvider(status: _status));

    final filters = <(String?, String)>[
      (null, l10n.chequeFilterAll),
      ('issued', l10n.chequeIssued),
      ('presented', l10n.chequePresented),
      ('cleared', l10n.chequeCleared),
      ('bounced', l10n.chequeBounced),
      ('cancelled', l10n.chequeCancelled),
    ];

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.chequesTitle, style: text.headlineMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(l10n.chequesIntro, style: text.bodySmall),
                ],
              ),
            ),
            if (widget.canManage)
              FilledButton.icon(
                onPressed: () => showDialog<void>(context: context, builder: (_) => const IssueChequeDialog()),
                icon: const Icon(Icons.add),
                label: Text(l10n.actionIssueCheque),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        const _StatusesExplained(),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final (value, label) in filters)
              ChoiceChip(
                label: Text(label),
                selected: _status == value,
                onSelected: (_) => setState(() => _status = value),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        switch (register) {
          AsyncData(:final value) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_status == null) _Outstanding(amount: value.outstanding),
                const SizedBox(height: AppSpacing.md),
                if (value.cheques.isEmpty)
                  Text(l10n.chequesEmpty, style: text.bodyMedium)
                else
                  for (final cheque in value.cheques)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _ChequeCard(cheque: cheque, canManage: widget.canManage),
                    ),
              ],
            ),
          AsyncError(:final error) => ErrorPanel.from(
              error,
              networkMessage: l10n.errNetwork,
              serverMessage: l10n.errServer,
              retryLabel: l10n.actionRetry,
              onRetry: () => ref.invalidate(chequeRegisterProvider),
            ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ],
    );
  }
}

class _StatusesExplained extends StatelessWidget {
  const _StatusesExplained();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: colors.surfaceSunken, borderRadius: BorderRadius.circular(AppRadii.container)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: AppSizes.iconMedium, color: colors.textMuted),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(l10n.chequeStatusesHelp, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}

class _Outstanding extends StatelessWidget {
  const _Outstanding({required this.amount});
  final Money amount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: colors.rule),
        borderRadius: BorderRadius.circular(AppRadii.container),
      ),
      child: Row(
        children: [
          Expanded(child: Text(l10n.chequesOutstanding, style: Theme.of(context).textTheme.labelLarge)),
          MoneyText(amount, size: 15, weight: FontWeight.w600, withCurrency: true),
        ],
      ),
    );
  }
}

String chequeStatusLabel(AppLocalizations l10n, String status) => switch (status) {
      'presented' => l10n.chequePresented,
      'cleared' => l10n.chequeCleared,
      'bounced' => l10n.chequeBounced,
      'cancelled' => l10n.chequeCancelled,
      _ => l10n.chequeIssued,
    };

class _ChequeCard extends ConsumerWidget {
  const _ChequeCard({required this.cheque, required this.canManage});

  final Cheque cheque;
  final bool canManage;

  Future<void> _say(ScaffoldMessengerState messenger, AppLocalizations l10n, Object? refusal, String done) async {
    messenger.showSnackBar(SnackBar(
      content: Text(refusal == null ? done : errorMessageFor(refusal, network: l10n.errNetwork, server: l10n.errServer)),
    ),);
  }

  Future<void> _move(BuildContext context, WidgetRef ref, String status) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    String? clearedOn;

    if (status == 'cleared') {
      clearedOn = await showDialog<String>(context: context, builder: (_) => const _ClearedOnDialog());
      if (clearedOn == null) return;
    } else if (status == 'bounced' || status == 'cancelled') {
      final sure = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(status == 'bounced' ? l10n.chequeBounceTitle : l10n.chequeCancelTitle),
          content: SizedBox(
            width: AppSizes.dialogWidth,
            child: Text(status == 'bounced' ? l10n.chequeBounceBody : l10n.chequeCancelBody),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.actionBack)),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(status == 'bounced' ? l10n.actionMarkBounced : l10n.actionCancelCheque),
            ),
          ],
        ),
      );
      if (sure != true) return;
    }

    final refusal = await ref
        .read(chequeActionsProvider.notifier)
        .run((repository) => repository.setStatus(cheque.id, status, clearedOn: clearedOn));
    await _say(messenger, l10n, refusal, l10n.chequeNowStatus(cheque.chequeNumber, chequeStatusLabel(l10n, status)));
  }

  Future<void> _link(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final picked = await showDialog<PaymentOption>(
      context: context,
      builder: (_) => _LinkDialog(accountId: cheque.accountId),
    );
    if (picked == null) return;
    final refusal = await ref.read(chequeActionsProvider.notifier).run((repository) => repository.link(cheque.id, picked.id));
    await _say(messenger, l10n, refusal, l10n.chequeLinked(picked.journalNumber ?? ''));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = Theme.of(context).textTheme;

    final (pillBackground, pillText) = switch (cheque.status) {
      'cleared' => (colors.accentSoft, colors.accent),
      'bounced' => (colors.negativeSoft, colors.negative),
      'cancelled' => (colors.reversedSoft, colors.reversed),
      _ => (colors.pendingSoft, colors.pending),
    };

    final actions = <(String, String)>[
      for (final step in cheque.nextSteps)
        (
          step,
          switch (step) {
            'presented' => l10n.actionMarkPresented,
            'cleared' => l10n.actionMarkCleared,
            'bounced' => l10n.actionMarkBounced,
            _ => l10n.actionCancelCheque,
          },
        ),
    ];

    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.rule),
        borderRadius: BorderRadius.circular(AppRadii.container),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(cheque.payee, style: text.titleSmall)),
                MoneyText(cheque.amount, size: 15, weight: FontWeight.w600),
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              '${l10n.chequeNumberShort(cheque.chequeNumber)}  ·  ${cheque.accountName}  ·  ${cheque.issueDate}',
              style: text.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(color: pillBackground, borderRadius: BorderRadius.circular(AppRadii.pill)),
                  child: Text(
                    cheque.status == 'cleared' && cheque.clearedOn != null
                        ? l10n.chequeClearedOn(cheque.clearedOn!)
                        : chequeStatusLabel(l10n, cheque.status),
                    style: text.labelSmall?.copyWith(color: pillText),
                  ),
                ),
                Text(
                  cheque.transactionId == null
                      ? l10n.chequeNotLinked
                      : l10n.chequeLinkedTo(cheque.journalNumber ?? ''),
                  style: text.bodySmall?.copyWith(color: cheque.transactionId == null ? colors.pending : null),
                ),
              ],
            ),
            if (canManage && (actions.isNotEmpty || cheque.transactionId == null)) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final (status, label) in actions)
                    TextButton(
                      style: status == 'bounced' || status == 'cancelled'
                          ? TextButton.styleFrom(foregroundColor: colors.negative)
                          : null,
                      onPressed: () => _move(context, ref, status),
                      child: Text(label),
                    ),
                  if (cheque.transactionId == null)
                    TextButton(onPressed: () => _link(context, ref), child: Text(l10n.actionLinkPayment)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ClearedOnDialog extends StatefulWidget {
  const _ClearedOnDialog();

  @override
  State<_ClearedOnDialog> createState() => _ClearedOnDialogState();
}

class _ClearedOnDialogState extends State<_ClearedOnDialog> {
  String _date = DateField.today();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.chequeClearedTitle),
      content: SizedBox(
        width: AppSizes.dialogWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.chequeClearedBody, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.lg),
            DateField(
              value: _date,
              onChanged: (value) => _date = value,
              label: l10n.fieldClearedOn,
              hint: l10n.hintDateFormat,
              pickTooltip: l10n.actionPickDate,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.actionCancel)),
        FilledButton(onPressed: () => Navigator.of(context).pop(_date), child: Text(l10n.actionMarkCleared)),
      ],
    );
  }
}

class _LinkDialog extends ConsumerStatefulWidget {
  const _LinkDialog({required this.accountId});
  final int accountId;

  @override
  ConsumerState<_LinkDialog> createState() => _LinkDialogState();
}

class _LinkDialogState extends ConsumerState<_LinkDialog> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final payments = ref.watch(chequePaymentsProvider(accountId: widget.accountId, search: _search));

    return AlertDialog(
      title: Text(l10n.linkPaymentTitle),
      content: SizedBox(
        width: AppSizes.dialogWideWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.linkPaymentHint, style: text.bodySmall),
            const SizedBox(height: AppSpacing.md),
            TextField(
              decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: l10n.hintPaymentSearch),
              onSubmitted: (value) => setState(() => _search = value),
            ),
            const SizedBox(height: AppSpacing.md),
            Flexible(
              child: switch (payments) {
                AsyncData(:final value) when value.isEmpty => Text(l10n.linkPaymentNone, style: text.bodyMedium),
                AsyncData(:final value) => ListView(
                    shrinkWrap: true,
                    children: [
                      for (final payment in value)
                        ListTile(
                          title: Text(payment.description),
                          subtitle: Text([payment.date, if (payment.journalNumber != null) payment.journalNumber!].join('  ·  ')),
                          trailing: MoneyText(payment.amount),
                          onTap: () => Navigator.of(context).pop(payment),
                        ),
                    ],
                  ),
                AsyncError(:final error) => Text(errorMessageFor(error, network: l10n.errNetwork, server: l10n.errServer)),
                _ => const LinearProgressIndicator(),
              },
            ),
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.actionCancel))],
    );
  }
}

/// Recording a cheque that was written.
class IssueChequeDialog extends ConsumerStatefulWidget {
  const IssueChequeDialog({super.key});

  @override
  ConsumerState<IssueChequeDialog> createState() => _IssueChequeDialogState();
}

class _IssueChequeDialogState extends ConsumerState<IssueChequeDialog> {
  int? _account;
  String _number = '';
  String _payee = '';
  Money? _amount;
  String _date = DateField.today();
  String _note = '';
  bool _busy = false;
  Object? _refusal;

  bool get _ready =>
      _account != null && _number.trim().isNotEmpty && _payee.trim().isNotEmpty && (_amount?.minorUnits ?? 0) > 0;

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() {
      _busy = true;
      _refusal = null;
    });
    final refusal = await ref.read(chequeActionsProvider.notifier).run(
          (repository) => repository.issue(
            accountId: _account!,
            chequeNumber: _number,
            payee: _payee,
            amount: _amount!,
            issueDate: _date,
            note: _note,
          ),
        );
    if (!mounted) return;
    if (refusal != null) {
      setState(() {
        _busy = false;
        _refusal = refusal;
      });
      return;
    }
    navigator.pop();
    messenger.showSnackBar(SnackBar(content: Text(l10n.chequeIssuedDone(_number.trim()))));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final accounts = ref
            .watch(accountsProvider())
            .value
            ?.accounts
            .where((a) => a.isActive && (a.type == AccountType.bank || a.type == AccountType.cheque))
            .toList() ??
        const <Account>[];

    return AlertDialog(
      title: Text(l10n.issueChequeTitle),
      content: SizedBox(
        width: AppSizes.dialogWideWidth,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.issueChequeHint, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: AppSpacing.lg),
              DropdownMenu<int>(
                key: const ValueKey('cheque-account'),
                initialSelection: _account,
                expandedInsets: EdgeInsets.zero,
                label: Text(l10n.fieldChequeAccount),
                dropdownMenuEntries: [
                  for (final account in accounts) DropdownMenuEntry(value: account.id, label: account.name),
                ],
                onSelected: (id) => setState(() => _account = id),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                decoration: InputDecoration(labelText: l10n.fieldChequeNumber),
                onChanged: (value) => setState(() => _number = value),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                decoration: InputDecoration(labelText: l10n.fieldPayableTo),
                onChanged: (value) => setState(() => _payee = value),
              ),
              const SizedBox(height: AppSpacing.md),
              MoneyField(
                label: l10n.fieldAmount,
                value: _amount,
                currency: 'PKR',
                onChanged: (value) => setState(() => _amount = value),
              ),
              const SizedBox(height: AppSpacing.md),
              DateField(
                value: _date,
                onChanged: (value) => _date = value,
                label: l10n.fieldChequeDate,
                hint: l10n.hintDateFormat,
                pickTooltip: l10n.actionPickDate,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                decoration: InputDecoration(labelText: l10n.fieldNotesOptional),
                onChanged: (value) => _note = value,
              ),
              if (_refusal != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  errorMessageFor(_refusal!, network: l10n.errNetwork, server: l10n.errServer),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.negative),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.of(context).pop(), child: Text(l10n.actionCancel)),
        FilledButton(onPressed: _ready && !_busy ? _save : null, child: Text(l10n.actionIssueCheque)),
      ],
    );
  }
}
