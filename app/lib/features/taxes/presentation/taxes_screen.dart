import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/error_message.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/date_field.dart';
import '../../../core/widgets/error_panel.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../transactions/application/categories_providers.dart';
import '../application/taxes_admin_providers.dart';
import '../data/taxes_admin_repository.dart';
import '../domain/tax_admin.dart';

/// Taxes, their rates over time, and when the entry form suggests each one.
/// The owner's, under Settings. Decisions 067 and 069.
///
/// Each tax is described in a plain sentence first: who pays it, how much,
/// and whether we can claim it back. A rate is never edited. "Change the rate
/// from a date" ends the current one the day before and starts the new one,
/// so every entry keeps the rate that was in force on its date.
class TaxesScreen extends ConsumerStatefulWidget {
  const TaxesScreen({super.key, this.onImportExport});

  /// Opens Import and export. Null hides the button.
  final VoidCallback? onImportExport;

  @override
  ConsumerState<TaxesScreen> createState() => _TaxesScreenState();
}

class _TaxesScreenState extends ConsumerState<TaxesScreen> {
  bool _showOld = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final overview = ref.watch(taxesOverviewProvider);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        Text(l10n.taxesTitle, style: text.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(l10n.taxesIntro, style: text.bodyMedium),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            FilledButton.icon(
              onPressed: overview.value == null
                  ? null
                  : () => _act(
                      context,
                      ref,
                      (_) => showDialog<bool>(
                        context: context,
                        builder: (_) => AddTaxDialog(overview: overview.value!),
                      ),
                    ),
              icon: const Icon(Icons.add),
              label: Text(l10n.actionAddTax),
            ),
            if (widget.onImportExport != null)
              TextButton.icon(
                onPressed: widget.onImportExport,
                icon: const Icon(Icons.import_export),
                label: Text(l10n.actionImportOrExport),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        const _HowTaxesWork(),
        const SizedBox(height: AppSpacing.sm),
        Material(
          type: MaterialType.transparency,
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _showOld,
            onChanged: (value) => setState(() => _showOld = value),
            title: Text(l10n.taxesShowOld, style: text.bodyMedium),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        switch (overview) {
          AsyncData(:final value) => () {
            final shown = value.taxes.where((tax) => _showOld || tax.isCurrent).toList();
            if (shown.isEmpty) return Text(l10n.taxesEmpty, style: text.bodyMedium);
            return Column(
              children: [
                for (final tax in shown)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: _TaxCard(tax: tax),
                  ),
              ],
            );
          }(),
          AsyncError(:final error) => ErrorPanel.from(
            error,
            networkMessage: l10n.errNetwork,
            serverMessage: l10n.errServer,
            retryLabel: l10n.actionRetry,
            onRetry: () => ref.invalidate(taxesOverviewProvider),
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ],
    );
  }
}

class _HowTaxesWork extends StatelessWidget {
  const _HowTaxesWork();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    Widget line(IconData icon, String value) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppSizes.iconSmall, color: colors.accent),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(value, style: text.bodySmall)),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: colors.infoSoft, borderRadius: BorderRadius.circular(AppRadii.container)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.taxHowTitle, style: text.titleSmall),
          line(Icons.verified_user_outlined, l10n.taxHowFiler),
          line(Icons.event_outlined, l10n.taxHowRates),
          line(Icons.auto_awesome_outlined, l10n.taxHowRules),
          line(Icons.lock_clock_outlined, l10n.taxHowEntries),
        ],
      ),
    );
  }
}

/// Opens a dialog that saves through [TaxAdminActions] itself and returns
/// true when it did, then says so.
Future<void> _act(BuildContext context, WidgetRef ref, Future<bool?> Function(BuildContext) open) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final done = await open(context);
  if (done == true) messenger.showSnackBar(SnackBar(content: Text(l10n.taxSaved)));
}

String kindLabel(AppLocalizations l10n, String kind) => switch (kind) {
  'withholding' => l10n.taxKindWithholding,
  'final' => l10n.taxKindFinal,
  'advance' => l10n.taxKindAdvance,
  'sales_tax' => l10n.taxKindSalesTax,
  'fed' => l10n.taxKindFed,
  _ => l10n.taxKindOther,
};

String authorityLabel(AppLocalizations l10n, String authority) => switch (authority) {
  'fbr' => l10n.taxAuthorityFbr,
  'pra' => l10n.taxAuthorityPra,
  'srb' => l10n.taxAuthoritySrb,
  'ict' => l10n.taxAuthorityIct,
  'bank' => l10n.taxAuthorityBank,
  _ => l10n.taxAuthorityOther,
};

String _accountTypeLabel(AppLocalizations l10n, String type) => switch (type) {
  'bank' => l10n.accountTypeBank,
  'cash' => l10n.accountTypeCash,
  'petty_cash' => l10n.accountTypePettyCash,
  'cheque' => l10n.accountTypeCheque,
  _ => l10n.accountTypePassThrough,
};

String ruleDescription(AppLocalizations l10n, TaxRuleView rule) => [
  rule.direction == 'in' ? l10n.ruleMoneyIn : l10n.ruleMoneyOut,
  switch (rule.currencyIsForeign) {
    true => l10n.ruleForeignOnly,
    false => l10n.ruleRupeesOnly,
    null => l10n.ruleAnyCurrency,
  },
  rule.accountType == null ? l10n.ruleAnyAccount : _accountTypeLabel(l10n, rule.accountType!),
  rule.categoryName ?? l10n.ruleAnyCategory,
].join('  ·  ');

/// What the tax does, in one or two plain sentences: who pays it, how much,
/// and whether we can claim it back.
String taxSentence(AppLocalizations l10n, TaxView tax) {
  String amount(String rate) =>
      tax.computation == 'percent' ? l10n.taxPercent(plainRate(rate)) : l10n.taxFixed(plainRate(rate));
  final rate = amount(tax.rateAtl);
  final nonFiler = amount(tax.rateNonAtl);
  final authority = authorityLabel(l10n, tax.authority);
  final keptBack = tax.statusBasis == 'counterparty';

  final first = switch ((keptBack, tax.appliesTo)) {
    (true, 'purchases') => l10n.taxSayKeepBack(rate, nonFiler, authority),
    (true, 'sales') => l10n.taxSayCollect(rate, nonFiler, authority),
    (true, _) => l10n.taxSayHeldBoth(rate, nonFiler, authority),
    (false, 'sales') => l10n.taxSayTakenIn(rate, nonFiler),
    (false, 'purchases') => l10n.taxSayTakenOut(rate, nonFiler),
    (false, _) => l10n.taxSayTakenBoth(rate, nonFiler),
  };
  final second = keptBack
      ? l10n.taxSayNotOurCost
      : tax.isAdjustable
      ? l10n.taxSayClaimable
      : l10n.taxSayFinalCost;
  return '$first $second';
}

class _TaxCard extends ConsumerWidget {
  const _TaxCard({required this.tax});
  final TaxView tax;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = Theme.of(context).textTheme;

    final (chipBackground, chipText, chipLabel) = switch (tax.standing) {
      'in_force' => (colors.accentSoft, colors.accent, l10n.taxInForce),
      'not_yet' => (colors.pendingSoft, colors.pending, l10n.taxStarts(tax.effectiveFrom)),
      'ended' => (colors.reversedSoft, colors.reversed, l10n.taxEnded(tax.effectiveTo ?? '')),
      _ => (colors.reversedSoft, colors.reversed, l10n.vendorSwitchedOff),
    };

    final rates = tax.computation == 'percent'
        ? l10n.taxRates(plainRate(tax.rateAtl), plainRate(tax.rateNonAtl))
        : l10n.taxRatesFixed(plainRate(tax.rateAtl), plainRate(tax.rateNonAtl));

    final activeRules = tax.rules.where((rule) => rule.isActive).toList();

    Widget fact(String label, String value) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: AppSizes.factLabelWidth,
            child: Text(label, style: text.labelMedium?.copyWith(color: colors.textMuted)),
          ),
          Expanded(child: Text(value, style: text.bodyMedium)),
        ],
      ),
    );

    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.rule),
        borderRadius: BorderRadius.circular(AppRadii.container),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: AppSpacing.sm,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(tax.name, style: text.titleMedium),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                            decoration: BoxDecoration(
                              color: colors.surfaceSunken,
                              borderRadius: BorderRadius.circular(AppRadii.control),
                            ),
                            child: Text(tax.shortCode, style: text.labelMedium),
                          ),
                        ],
                      ),
                      if (tax.lawReference != null)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xxs),
                          child: Text(tax.lawReference!, style: text.bodySmall?.copyWith(color: colors.textMuted)),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(color: chipBackground, borderRadius: BorderRadius.circular(AppRadii.pill)),
                  child: Text(chipLabel, style: text.labelSmall?.copyWith(color: chipText)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.surfaceSunken,
                borderRadius: BorderRadius.circular(AppRadii.control),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline, size: AppSizes.iconMedium, color: colors.accent),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(taxSentence(l10n, tax), style: text.bodyMedium)),
                ],
              ),
            ),
            fact(l10n.taxFactRate, rates),
            fact(
              l10n.taxFactKind,
              '${kindLabel(l10n, tax.kind)}, ${l10n.taxPaidTo(authorityLabel(l10n, tax.authority))}',
            ),
            fact(l10n.taxFactRecorded, '${tax.ledgerCode} ${tax.ledgerName}'),
            fact(
              l10n.taxFactDates,
              tax.effectiveTo == null
                  ? l10n.taxPeriodOpen(tax.effectiveFrom)
                  : l10n.taxPeriod(tax.effectiveFrom, tax.effectiveTo!),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Text(l10n.taxRulesTitle, style: text.titleSmall),
                const SizedBox(width: AppSpacing.xs),
                Tooltip(
                  message: l10n.taxRulesExplain,
                  child: Icon(Icons.info_outline, size: AppSizes.iconSmall, color: colors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            if (activeRules.isEmpty) Text(l10n.taxNoRules, style: text.bodySmall?.copyWith(color: colors.pending)),
            for (final rule in tax.rules)
              Row(
                children: [
                  Icon(
                    rule.isActive ? Icons.check_circle_outline : Icons.remove_circle_outline,
                    size: AppSizes.iconSmall,
                    color: rule.isActive ? colors.accent : colors.textMuted,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      ruleDescription(l10n, rule),
                      style: text.bodySmall?.copyWith(
                        decoration: rule.isActive ? null : TextDecoration.lineThrough,
                        color: rule.isActive ? null : colors.textMuted,
                      ),
                    ),
                  ),
                  if (tax.isCurrent)
                    TextButton(
                      onPressed: () => _setRule(context, ref, rule),
                      child: Text(rule.isActive ? l10n.actionSwitchOff : l10n.actionSwitchOn),
                    ),
                ],
              ),
            if (tax.isCurrent) ...[
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _act(
                      context,
                      ref,
                      (context) => showDialog<bool>(
                        context: context,
                        builder: (_) => NewRateDialog(tax: tax),
                      ),
                    ),
                    icon: const Icon(Icons.trending_up, size: AppSizes.iconSmall),
                    label: Text(l10n.actionNewRate),
                  ),
                  TextButton(
                    onPressed: () => _act(
                      context,
                      ref,
                      (context) => showDialog<bool>(
                        context: context,
                        builder: (_) => AddRuleDialog(tax: tax),
                      ),
                    ),
                    child: Text(l10n.actionAddRule),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: colors.negative),
                    onPressed: () => _act(
                      context,
                      ref,
                      (context) => showDialog<bool>(
                        context: context,
                        builder: (_) => EndTaxDialog(tax: tax),
                      ),
                    ),
                    child: Text(l10n.actionEndTax),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _setRule(BuildContext context, WidgetRef ref, TaxRuleView rule) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final refusal = await ref
        .read(taxAdminActionsProvider.notifier)
        .run((repository) => repository.setRule(rule.id, isActive: !rule.isActive));
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          refusal == null ? l10n.taxSaved : errorMessageFor(refusal, network: l10n.errNetwork, server: l10n.errServer),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dialogs. Each saves through TaxAdminActions and closes with true when it
// worked; a refusal is shown inside it, in the server's words.
// ---------------------------------------------------------------------------

final _rateFormat = FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'));
final _rateShape = RegExp(r'^\d+(\.\d{1,4})?$');

String? _dayBefore(String date) {
  final parsed = DateTime.tryParse(date);
  if (parsed == null) return null;
  return DateField.format(parsed.subtract(const Duration(days: 1)));
}

mixin _Saving<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  bool busy = false;
  Object? refusal;

  Future<void> save(Future<void> Function(TaxesAdminRepository repository) call) async {
    setState(() {
      busy = true;
      refusal = null;
    });
    final navigator = Navigator.of(context);
    final result = await ref.read(taxAdminActionsProvider.notifier).run((repository) => call(repository));
    if (!mounted) return;
    if (result == null) {
      navigator.pop(true);
      return;
    }
    setState(() {
      busy = false;
      refusal = result;
    });
  }

  Widget refusalText(BuildContext context) {
    if (refusal == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Text(
        errorMessageFor(refusal!, network: l10n.errNetwork, server: l10n.errServer),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.negative),
      ),
    );
  }
}

class NewRateDialog extends ConsumerStatefulWidget {
  const NewRateDialog({super.key, required this.tax});
  final TaxView tax;

  @override
  ConsumerState<NewRateDialog> createState() => _NewRateDialogState();
}

class _NewRateDialogState extends ConsumerState<NewRateDialog> with _Saving {
  final _formKey = GlobalKey<FormState>();
  late final _atl = TextEditingController(text: plainRate(widget.tax.rateAtl));
  late final _nonAtl = TextEditingController(text: plainRate(widget.tax.rateNonAtl));
  String _from = DateField.today();

  @override
  void dispose() {
    _atl.dispose();
    _nonAtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final ends = _dayBefore(_from);

    return AlertDialog(
      title: Text(l10n.newRateTitle(widget.tax.shortCode)),
      content: SizedBox(
        width: AppSizes.dialogWidth,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.newRateHint, style: text.bodySmall),
              const SizedBox(height: AppSpacing.lg),
              DateField(
                value: _from,
                onChanged: (value) => setState(() => _from = value),
                label: l10n.fieldNewRateFrom,
                hint: l10n.hintDateFormat,
                pickTooltip: l10n.actionPickDate,
              ),
              if (ends != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(l10n.newRateOldEnds(widget.tax.shortCode, ends), style: text.bodySmall),
              ],
              const SizedBox(height: AppSpacing.md),
              _RateFields(atl: _atl, nonAtl: _nonAtl),
              refusalText(context),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: busy ? null : () => Navigator.of(context).pop(), child: Text(l10n.actionCancel)),
        FilledButton(
          onPressed: busy
              ? null
              : () {
                  if (!_formKey.currentState!.validate()) return;
                  save(
                    (repository) => repository.newRate(
                      widget.tax.id,
                      from: _from,
                      rateAtl: _atl.text.trim(),
                      rateNonAtl: _nonAtl.text.trim(),
                    ),
                  );
                },
          child: Text(l10n.actionSaveNewRate),
        ),
      ],
    );
  }
}

class _RateFields extends StatelessWidget {
  const _RateFields({required this.atl, required this.nonAtl});
  final TextEditingController atl;
  final TextEditingController nonAtl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String? check(String? value) => value != null && _rateShape.hasMatch(value.trim()) ? null : l10n.errRateShape;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: atl,
            inputFormatters: [_rateFormat],
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: l10n.fieldRateFiler, suffixText: '%'),
            validator: check,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: TextFormField(
            controller: nonAtl,
            inputFormatters: [_rateFormat],
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: l10n.fieldRateNonFiler, suffixText: '%'),
            validator: check,
          ),
        ),
      ],
    );
  }
}

class EndTaxDialog extends ConsumerStatefulWidget {
  const EndTaxDialog({super.key, required this.tax});
  final TaxView tax;

  @override
  ConsumerState<EndTaxDialog> createState() => _EndTaxDialogState();
}

class _EndTaxDialogState extends ConsumerState<EndTaxDialog> with _Saving {
  String _lastDay = DateField.today();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.endTaxTitle(widget.tax.shortCode)),
      content: SizedBox(
        width: AppSizes.dialogWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.endTaxHint, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSpacing.lg),
            DateField(
              value: _lastDay,
              onChanged: (value) => _lastDay = value,
              label: l10n.fieldLastDay,
              hint: l10n.hintDateFormat,
              pickTooltip: l10n.actionPickDate,
            ),
            refusalText(context),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: busy ? null : () => Navigator.of(context).pop(), child: Text(l10n.actionCancel)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: context.colors.negative),
          onPressed: busy ? null : () => save((repository) => repository.end(widget.tax.id, lastDay: _lastDay)),
          child: Text(l10n.actionEndTax),
        ),
      ],
    );
  }
}

class AddRuleDialog extends ConsumerStatefulWidget {
  const AddRuleDialog({super.key, required this.tax});
  final TaxView tax;

  @override
  ConsumerState<AddRuleDialog> createState() => _AddRuleDialogState();
}

class _AddRuleDialogState extends ConsumerState<AddRuleDialog> with _Saving {
  late String _direction = widget.tax.directions.first;
  String _currency = 'any';
  String _account = 'any';
  int? _category;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final groups = ref.watch(categoryGroupsProvider(direction: _direction)).value ?? const [];
    final categories = [for (final group in groups) ...group.categories]
      ..sort((a, b) => a.ledgerCode.compareTo(b.ledgerCode));

    return AlertDialog(
      title: Text(l10n.addRuleTitle(widget.tax.shortCode)),
      content: SizedBox(
        width: AppSizes.dialogWideWidth,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.addRuleHint, style: text.bodySmall),
              if (widget.tax.directions.length > 1) ...[
                const SizedBox(height: AppSpacing.lg),
                SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: 'out', label: Text(l10n.ruleMoneyOut)),
                    ButtonSegment(value: 'in', label: Text(l10n.ruleMoneyIn)),
                  ],
                  selected: {_direction},
                  onSelectionChanged: (value) => setState(() {
                    _direction = value.first;
                    _category = null;
                  }),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Text(l10n.fieldRuleCurrency, style: text.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              SegmentedButton<String>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: 'any', label: Text(l10n.ruleAnyCurrency)),
                  ButtonSegment(value: 'foreign', label: Text(l10n.ruleForeignOnly)),
                  ButtonSegment(value: 'pkr', label: Text(l10n.ruleRupeesOnly)),
                ],
                selected: {_currency},
                onSelectionChanged: (value) => setState(() => _currency = value.first),
              ),
              const SizedBox(height: AppSpacing.lg),
              DropdownMenu<String>(
                initialSelection: _account,
                expandedInsets: EdgeInsets.zero,
                label: Text(l10n.fieldRuleAccount),
                dropdownMenuEntries: [
                  DropdownMenuEntry(value: 'any', label: l10n.ruleAnyAccount),
                  for (final type in ['bank', 'cash', 'petty_cash', 'cheque', 'pass_through'])
                    DropdownMenuEntry(value: type, label: _accountTypeLabel(l10n, type)),
                ],
                onSelected: (value) => setState(() => _account = value ?? 'any'),
              ),
              const SizedBox(height: AppSpacing.lg),
              DropdownMenu<int>(
                key: ValueKey('rule-category-$_direction'),
                initialSelection: _category ?? -1,
                expandedInsets: EdgeInsets.zero,
                menuHeight: AppSizes.menuMaxHeight,
                enableFilter: true,
                requestFocusOnTap: true,
                label: Text(l10n.fieldRuleCategory),
                dropdownMenuEntries: [
                  DropdownMenuEntry(value: -1, label: l10n.ruleAnyCategory),
                  for (final category in categories)
                    DropdownMenuEntry(value: category.id, label: '${category.ledgerCode}  ${category.name}'),
                ],
                onSelected: (value) => setState(() => _category = value == null || value == -1 ? null : value),
              ),
              refusalText(context),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: busy ? null : () => Navigator.of(context).pop(), child: Text(l10n.actionCancel)),
        FilledButton(
          onPressed: busy
              ? null
              : () => save(
                  (repository) => repository.addRule(widget.tax.id, {
                    'direction': _direction,
                    'currencyIsForeign': switch (_currency) {
                      'foreign' => true,
                      'pkr' => false,
                      _ => null,
                    },
                    'accountType': _account == 'any' ? null : _account,
                    'categoryId': _category,
                  }),
                ),
          child: Text(l10n.actionAddRule),
        ),
      ],
    );
  }
}

class AddTaxDialog extends ConsumerStatefulWidget {
  const AddTaxDialog({super.key, required this.overview});
  final TaxesOverview overview;

  @override
  ConsumerState<AddTaxDialog> createState() => _AddTaxDialogState();
}

class _AddTaxDialogState extends ConsumerState<AddTaxDialog> with _Saving {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _code = TextEditingController();
  final _law = TextEditingController();
  final _atl = TextEditingController();
  final _nonAtl = TextEditingController();
  final _section = TextEditingController();
  final _notes = TextEditingController();
  String _authority = 'fbr';
  String _kind = 'withholding';
  String _appliesTo = 'purchases';
  String _basis = 'counterparty';
  String? _ledgerCode;
  bool _adjustable = false;
  bool _tried = false;
  String _from = DateField.today();

  @override
  void dispose() {
    for (final controller in [_name, _code, _law, _atl, _nonAtl, _section, _notes]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
    setState(() => _tried = true);
    if (!_formKey.currentState!.validate() || _ledgerCode == null) return;
    String? filled(TextEditingController controller) => controller.text.trim().isEmpty ? null : controller.text.trim();
    save(
      (repository) => repository.create({
        'name': _name.text.trim(),
        'shortCode': _code.text.trim(),
        'authority': _authority,
        if (filled(_law) != null) 'lawReference': filled(_law),
        'kind': _kind,
        'appliesTo': _appliesTo,
        'computation': 'percent',
        'rateAtl': _atl.text.trim(),
        'rateNonAtl': _nonAtl.text.trim(),
        'statusBasis': _basis,
        if (filled(_section) != null) 'returnSection': filled(_section),
        'isAdjustable': _adjustable,
        'ledgerCode': _ledgerCode,
        'effectiveFrom': _from,
        if (filled(_notes) != null) 'notes': filled(_notes),
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    String? required(String? value) => value == null || value.trim().isEmpty ? l10n.errRequired : null;

    return AlertDialog(
      title: Text(l10n.addTaxTitleFull),
      content: SizedBox(
        width: AppSizes.dialogWideWidth,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.addTaxHint, style: text.bodySmall),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _name,
                  decoration: InputDecoration(labelText: l10n.fieldTaxName),
                  validator: required,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _code,
                        decoration: InputDecoration(labelText: l10n.fieldTaxCode, helperText: l10n.hintTaxCode),
                        validator: required,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextFormField(
                        controller: _law,
                        decoration: InputDecoration(
                          labelText: l10n.fieldLawReference,
                          helperText: l10n.hintLawReference,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: DropdownMenu<String>(
                        initialSelection: _kind,
                        expandedInsets: EdgeInsets.zero,
                        label: Text(l10n.fieldTaxKind),
                        dropdownMenuEntries: [
                          for (final kind in ['withholding', 'final', 'advance', 'sales_tax', 'fed', 'other'])
                            DropdownMenuEntry(value: kind, label: kindLabel(l10n, kind)),
                        ],
                        onSelected: (value) => setState(() => _kind = value ?? _kind),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: DropdownMenu<String>(
                        initialSelection: _authority,
                        expandedInsets: EdgeInsets.zero,
                        label: Text(l10n.fieldTaxAuthority),
                        dropdownMenuEntries: const [
                          DropdownMenuEntry(value: 'fbr', label: 'FBR'),
                          DropdownMenuEntry(value: 'pra', label: 'PRA'),
                          DropdownMenuEntry(value: 'srb', label: 'SRB'),
                          DropdownMenuEntry(value: 'ict', label: 'ICT'),
                          DropdownMenuEntry(value: 'bank', label: 'Bank'),
                          DropdownMenuEntry(value: 'other', label: 'Other'),
                        ],
                        onSelected: (value) => setState(() => _authority = value ?? _authority),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(l10n.fieldTaxAppliesTo, style: text.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: 'purchases', label: Text(l10n.ruleMoneyOut)),
                    ButtonSegment(value: 'sales', label: Text(l10n.ruleMoneyIn)),
                    ButtonSegment(value: 'both', label: Text(l10n.taxBoth)),
                  ],
                  selected: {_appliesTo},
                  onSelectionChanged: (value) => setState(() => _appliesTo = value.first),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(l10n.fieldTaxBasis, style: text.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: 'counterparty', label: Text(l10n.taxBasisPayeeShort)),
                    ButtonSegment(value: 'company', label: Text(l10n.taxBasisOursShort)),
                  ],
                  selected: {_basis},
                  onSelectionChanged: (value) => setState(() => _basis = value.first),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(_basis == 'company' ? l10n.taxBasisOurs : l10n.taxBasisPayee, style: text.bodySmall),
                const SizedBox(height: AppSpacing.lg),
                _RateFields(atl: _atl, nonAtl: _nonAtl),
                const SizedBox(height: AppSpacing.md),
                DropdownMenu<String>(
                  key: const ValueKey('tax-ledger'),
                  initialSelection: _ledgerCode,
                  expandedInsets: EdgeInsets.zero,
                  menuHeight: AppSizes.menuMaxHeight,
                  enableFilter: true,
                  requestFocusOnTap: true,
                  label: Text(l10n.fieldTaxLedger),
                  helperText: l10n.hintTaxLedger,
                  dropdownMenuEntries: [
                    for (final ledger in widget.overview.ledgers)
                      DropdownMenuEntry(value: ledger.code, label: '${ledger.code}  ${ledger.name}'),
                  ],
                  onSelected: (value) => setState(() => _ledgerCode = value),
                ),
                const SizedBox(height: AppSpacing.md),
                DateField(
                  value: _from,
                  onChanged: (value) => _from = value,
                  label: l10n.fieldTaxFrom,
                  hint: l10n.hintDateFormat,
                  pickTooltip: l10n.actionPickDate,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _section,
                  decoration: InputDecoration(labelText: l10n.fieldReturnSection, helperText: l10n.hintReturnSection),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _adjustable,
                  onChanged: (value) => setState(() => _adjustable = value),
                  title: Text(l10n.fieldAdjustable),
                  subtitle: Text(l10n.hintAdjustable),
                ),
                TextFormField(
                  controller: _notes,
                  maxLines: 2,
                  decoration: InputDecoration(labelText: l10n.fieldNotesOptional),
                ),
                if (_tried && _ledgerCode == null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Text(l10n.hintTaxLedgerNeeded, style: text.bodySmall?.copyWith(color: colors.pending)),
                  ),
                refusalText(context),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: busy ? null : () => Navigator.of(context).pop(), child: Text(l10n.actionCancel)),
        FilledButton(onPressed: busy ? null : _submit, child: Text(l10n.actionAddTax)),
      ],
    );
  }
}
