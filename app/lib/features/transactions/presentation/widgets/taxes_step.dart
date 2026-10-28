import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/api/error_message.dart';
import '../../../../core/money/money.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/money_text.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../accounts/application/accounts_providers.dart';
import '../../../accounts/domain/account.dart';
import '../../application/entry_draft_controller.dart';
import '../../application/entry_options_providers.dart';
import '../../domain/entry_draft.dart';
import '../../domain/entry_options.dart';
import 'money_field.dart';

/// Tax and charges, after the category, so the suggestion knows the amount,
/// the account and what the money was for. Decision 064.
///
/// Nothing is worked out here. The server suggests the tax lines, works out
/// any tax added by hand, and picks the usual account for a charge. The person
/// changes a figure to what the bank actually took, removes a line, or adds
/// one. UI-GUIDE, entry form step 6.
class TaxesStep extends ConsumerStatefulWidget {
  const TaxesStep({super.key});

  @override
  ConsumerState<TaxesStep> createState() => _TaxesStepState();
}

class _TaxesStepState extends ConsumerState<TaxesStep> {
  bool _busy = false;
  ApiException? _refusal;

  @override
  void initState() {
    super.initState();
    // Suggested once for the figures on the form. Changing the amount, the
    // account, the category, the date or the direction clears the lines, and
    // coming back here suggests them again.
    if (!ref.read(entryDraftControllerProvider).taxesChecked) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _suggest());
    }
  }

  String? _accountType() {
    final draft = ref.read(entryDraftControllerProvider);
    if (draft.paidPersonally || draft.accountId == null) return null;
    final accounts = ref.read(accountsProvider()).value?.accounts ?? const <Account>[];
    for (final account in accounts) {
      if (account.id != draft.accountId) continue;
      return switch (account.type) {
        AccountType.bank => 'bank',
        AccountType.cash => 'cash',
        AccountType.pettyCash => 'petty_cash',
        AccountType.cheque => 'cheque',
        AccountType.passThrough => 'pass_through',
        _ => null,
      };
    }
    return null;
  }

  Future<void> _run(Future<ApiException?> Function() call) async {
    setState(() {
      _busy = true;
      _refusal = null;
    });
    final refusal = await call();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _refusal = refusal;
    });
  }

  Future<void> _suggest() =>
      _run(() => ref.read(entryDraftControllerProvider.notifier).suggestTaxes(accountType: _accountType()));

  Future<void> _addTax() async {
    final draft = ref.read(entryDraftControllerProvider);
    final picked = await showDialog<int>(
      context: context,
      builder: (_) => _AddTaxDialog(
        date: draft.date,
        direction: draft.direction == EntryDirection.moneyIn ? 'in' : 'out',
        exclude: draft.taxes.map((tax) => tax.taxId).toSet(),
      ),
    );
    if (picked == null || !mounted) return;
    await _run(() => ref.read(entryDraftControllerProvider.notifier).addTax(picked));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final colors = context.colors;
    final draft = ref.watch(entryDraftControllerProvider);
    final controller = ref.read(entryDraftControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.stepTaxesQuestion, style: text.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(l10n.hintTaxesStep, style: text.bodySmall),
        const SizedBox(height: AppSpacing.xl),

        // --- taxes ---------------------------------------------------------
        _SectionTitle(l10n.sectionTaxes),
        if (_busy) const LinearProgressIndicator(),
        if (!_busy && draft.taxes.isEmpty) Text(l10n.taxesNoneSuggested, style: text.bodySmall),
        for (final tax in draft.taxes)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _TaxLineCard(
              key: ValueKey('tax-${tax.taxId}-${tax.rateApplied}-${tax.baseAmount.minorUnits}'),
              tax: tax,
              onAmount: (amount) => controller.setTaxAmount(tax.taxId, amount),
              onRemove: () => controller.removeTax(tax.taxId),
            ),
          ),
        if (_refusal != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            errorMessageFor(_refusal!, network: l10n.errNetwork, server: l10n.errServer),
            style: text.bodySmall?.copyWith(color: colors.negative),
          ),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _busy ? null : _addTax,
            icon: const Icon(Icons.add, size: AppSizes.iconSmall),
            label: Text(l10n.actionAddTaxLine),
          ),
        ),

        // --- payee, only when tax is kept back from them -------------------
        if (draft.withholds) ...[
          const SizedBox(height: AppSpacing.lg),
          _SectionTitle(l10n.sectionPayee),
          _PayeePicker(
            selected: draft.vendorId,
            onSelected: (id) => _run(() => controller.setVendor(id)),
          ),
        ],

        // --- charges -------------------------------------------------------
        const SizedBox(height: AppSpacing.lg),
        _SectionTitle(l10n.sectionCharges),
        for (final charge in draft.charges)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _ChargeLineCard(
              key: ValueKey('charge-${charge.id}'),
              charge: charge,
              onChanged: controller.updateCharge,
              onRemove: () => controller.removeCharge(charge.id),
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: controller.addCharge,
            icon: const Icon(Icons.add, size: AppSizes.iconSmall),
            label: Text(l10n.actionAddCharge),
          ),
        ),

        const SizedBox(height: AppSpacing.lg),
        const _MovesTotal(),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Text(title, style: Theme.of(context).textTheme.titleSmall),
      );
}

/// What actually leaves or reaches the account once the taxes and charges are
/// counted. The server's figure, from the same preview the review step shows.
class _MovesTotal extends ConsumerWidget {
  const _MovesTotal();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final draft = ref.watch(entryDraftControllerProvider);
    final preview = ref.watch(journalPreviewProvider).value;
    if (preview == null) return const SizedBox.shrink();

    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceSunken,
        borderRadius: BorderRadius.circular(AppRadii.container),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              draft.direction == EntryDirection.moneyIn ? l10n.totalArrives : l10n.totalLeaves,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          MoneyText(preview.totals.amount, size: 15, weight: FontWeight.w600, withCurrency: true),
        ],
      ),
    );
  }
}

String _plainRate(String rate) {
  if (!rate.contains('.')) return rate;
  final trimmed = rate.replaceFirst(RegExp(r'0+$'), '');
  return trimmed.endsWith('.') ? trimmed.substring(0, trimmed.length - 1) : trimmed;
}

class _TaxLineCard extends StatelessWidget {
  const _TaxLineCard({super.key, required this.tax, required this.onAmount, required this.onRemove});

  final DraftTax tax;
  final ValueChanged<Money> onAmount;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final status = tax.atlStatusUsed == 'atl' ? l10n.taxStatusFiler : l10n.taxStatusNonFiler;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: colors.rule),
        borderRadius: BorderRadius.circular(AppRadii.container),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tax.shortCode.isEmpty ? tax.name : '${tax.shortCode}  ${tax.name}',
                      style: text.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(tax.isWithheldByUs ? l10n.taxKeptBack : l10n.taxTakenFromUs, style: text.bodySmall),
                    const SizedBox(height: AppSpacing.xxs),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text('${l10n.taxRateLine(_plainRate(tax.rateApplied), status)} ', style: text.bodySmall),
                        MoneyText(tax.baseAmount, size: 12.5, weight: FontWeight.w400, muted: true),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: l10n.actionRemove,
                icon: const Icon(Icons.close, size: AppSizes.iconMedium),
                onPressed: onRemove,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          MoneyField(
            label: l10n.fieldTaxAmount,
            value: tax.amount,
            currency: 'PKR',
            onChanged: onAmount,
            helper: tax.isOverride ? l10n.taxChanged : null,
          ),
          if (tax.warning != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: AppSizes.iconSmall, color: colors.pending),
                const SizedBox(width: AppSpacing.xs),
                Expanded(child: Text(tax.warning!, style: text.bodySmall?.copyWith(color: colors.pending))),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ChargeLineCard extends ConsumerStatefulWidget {
  const _ChargeLineCard({super.key, required this.charge, required this.onChanged, required this.onRemove});

  final DraftCharge charge;
  final ValueChanged<DraftCharge> onChanged;
  final VoidCallback onRemove;

  @override
  ConsumerState<_ChargeLineCard> createState() => _ChargeLineCardState();
}

/// A charge line says where it goes: "Goes to 8200 Forex and card fees". The
/// account picker stays out of the way behind "Use another account", for the
/// rare charge the accountant wants somewhere else. Decision 065.
class _ChargeLineCardState extends ConsumerState<_ChargeLineCard> {
  late bool _picking = widget.charge.coaId != null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final charge = widget.charge;
    final accounts = ref.watch(chargeAccountsProvider).value ?? const <ChargeAccount>[];

    final types = {
      'bank_charge': l10n.chargeTypeBank,
      'forex_fee': l10n.chargeTypeForex,
      'card_fee': l10n.chargeTypeCard,
      'platform_fee': l10n.chargeTypePlatform,
      'other': l10n.chargeTypeOther,
    };

    final usualCode = usualChargeLedger[charge.type] ?? usualChargeLedger['other']!;
    final usualName = accounts.where((account) => account.code == usualCode).firstOrNull?.name;
    final usualLabel = usualName == null ? usualCode : '$usualCode  $usualName';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: colors.rule),
        borderRadius: BorderRadius.circular(AppRadii.container),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownMenu<String>(
                  initialSelection: charge.type,
                  expandedInsets: EdgeInsets.zero,
                  label: Text(l10n.fieldChargeType),
                  dropdownMenuEntries: [
                    for (final entry in types.entries) DropdownMenuEntry(value: entry.key, label: entry.value),
                  ],
                  onSelected: (type) => type == null ? null : widget.onChanged(charge.copyWith(type: type)),
                ),
              ),
              IconButton(
                tooltip: l10n.actionRemove,
                icon: const Icon(Icons.close, size: AppSizes.iconMedium),
                onPressed: widget.onRemove,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          MoneyField(
            label: l10n.fieldChargeAmount,
            value: charge.amount,
            currency: 'PKR',
            onChanged: (amount) => widget.onChanged(charge.copyWith(amount: amount)),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (!_picking)
            Row(
              children: [
                Icon(Icons.subdirectory_arrow_right, size: AppSizes.iconSmall, color: colors.textMuted),
                const SizedBox(width: AppSpacing.xs),
                Expanded(child: Text(l10n.chargeGoesTo(usualLabel), style: text.bodySmall)),
                TextButton(
                  onPressed: () => setState(() => _picking = true),
                  child: Text(l10n.actionUseAnotherAccount),
                ),
              ],
            )
          else ...[
            const SizedBox(height: AppSpacing.xs),
            DropdownMenu<int>(
              initialSelection: charge.coaId,
              expandedInsets: EdgeInsets.zero,
              menuHeight: AppSizes.menuMaxHeight,
              label: Text(l10n.fieldChargeAccount),
              helperText: l10n.hintChargeAccount,
              dropdownMenuEntries: [
                for (final account in accounts)
                  DropdownMenuEntry(value: account.id, label: '${account.code}  ${account.name}'),
              ],
              onSelected: (id) => id == null ? null : widget.onChanged(charge.copyWith(coaId: id)),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {
                  setState(() => _picking = false);
                  widget.onChanged(charge.copyWith(usualAccount: true));
                },
                child: Text(l10n.actionBackToUsualAccount(usualLabel)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Who is being paid, when tax is kept back from them. Their NTN or CNIC is
/// what the quarterly statement reports, and their filer status sets the rate.
class _PayeePicker extends ConsumerWidget {
  const _PayeePicker({required this.selected, required this.onSelected});

  final int? selected;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final vendors = ref.watch(vendorOptionsProvider);

    return switch (vendors) {
      AsyncData(:final value) when value.isEmpty => Text(l10n.payeeNoneYet, style: text.bodySmall),
      AsyncData(:final value) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownMenu<int>(
              initialSelection: selected,
              expandedInsets: EdgeInsets.zero,
              menuHeight: AppSizes.menuMaxHeight,
              enableFilter: true,
              requestFocusOnTap: true,
              label: Text(l10n.fieldPayee),
              helperText: l10n.hintPayee,
              dropdownMenuEntries: [
                for (final vendor in value)
                  DropdownMenuEntry(
                    value: vendor.id,
                    label: vendor.canBeWithheldFrom ? vendor.name : '${vendor.name} (${l10n.payeeNoTaxIdShort})',
                  ),
              ],
              onSelected: onSelected,
            ),
            if (selected != null && value.any((v) => v.id == selected && !v.canBeWithheldFrom)) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.payeeNoTaxId, style: text.bodySmall?.copyWith(color: colors.negative)),
            ],
          ],
        ),
      AsyncError(:final error) => Text(
          errorMessageFor(error, network: l10n.errNetwork, server: l10n.errServer),
          style: text.bodySmall?.copyWith(color: colors.negative),
        ),
      _ => const LinearProgressIndicator(),
    };
  }
}

class _AddTaxDialog extends ConsumerWidget {
  const _AddTaxDialog({required this.date, required this.direction, required this.exclude});

  final String date;
  final String direction;
  final Set<int> exclude;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final options = ref.watch(taxOptionsProvider(date: date, direction: direction));

    return AlertDialog(
      title: Text(l10n.addTaxTitle),
      content: SizedBox(
        width: AppSizes.dialogWidth,
        child: switch (options) {
          AsyncData(:final value) => () {
              final left = value.where((tax) => !exclude.contains(tax.id)).toList();
              if (left.isEmpty) return Text(l10n.addTaxNone, style: text.bodyMedium);
              return ListView(
                shrinkWrap: true,
                children: [
                  for (final tax in left)
                    ListTile(
                      title: Text(tax.shortCode.isEmpty ? tax.name : '${tax.shortCode}  ${tax.name}'),
                      subtitle: tax.lawReference == null ? null : Text(tax.lawReference!),
                      onTap: () => Navigator.of(context).pop(tax.id),
                    ),
                ],
              );
            }(),
          AsyncError(:final error) => Text(errorMessageFor(error, network: l10n.errNetwork, server: l10n.errServer)),
          _ => const LinearProgressIndicator(),
        },
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.actionCancel)),
      ],
    );
  }
}
