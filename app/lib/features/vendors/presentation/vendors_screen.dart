import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/error_message.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/date_field.dart';
import '../../../core/widgets/error_panel.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/vendors_providers.dart';
import '../domain/vendor.dart';

/// Everyone Winibex pays other than staff. Decision 066.
///
/// What matters about a vendor, said plainly on each card: whether they have
/// an NTN or CNIC (tax cannot be kept back without one), whether they are a
/// filer (it halves the rate), and when that was last checked.
class VendorsScreen extends ConsumerStatefulWidget {
  const VendorsScreen({super.key, this.canManage = false});

  /// The owner and admins add and change vendors. The server checks again.
  final bool canManage;

  @override
  ConsumerState<VendorsScreen> createState() => _VendorsScreenState();
}

class _VendorsScreenState extends ConsumerState<VendorsScreen> {
  String _search = '';

  Future<void> _add() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final form = await showDialog<VendorForm>(context: context, builder: (_) => const VendorDialog());
    if (form == null) return;
    final refusal = await ref.read(vendorActionsProvider.notifier).add(form);
    messenger.showSnackBar(SnackBar(
      content: Text(refusal == null
          ? l10n.vendorAdded(form.name)
          : errorMessageFor(refusal, network: l10n.errNetwork, server: l10n.errServer),),
    ),);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final vendors = ref.watch(vendorListProvider);

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
                  Text(l10n.vendorsTitle, style: text.headlineMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(l10n.vendorsIntro, style: text.bodySmall),
                ],
              ),
            ),
            if (widget.canManage)
              FilledButton.icon(
                onPressed: _add,
                icon: const Icon(Icons.add_business_outlined),
                label: Text(l10n.actionAddVendor),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        const _FilerExplained(),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: l10n.hintVendorSearch,
          ),
          onChanged: (value) => setState(() => _search = value.trim().toLowerCase()),
        ),
        const SizedBox(height: AppSpacing.lg),
        switch (vendors) {
          AsyncData(:final value) when value.isEmpty => Text(l10n.vendorsEmpty, style: text.bodyMedium),
          AsyncData(:final value) => Column(
              children: [
                for (final vendor in value.where((v) =>
                    _search.isEmpty ||
                    v.name.toLowerCase().contains(_search) ||
                    (v.ntn ?? '').contains(_search) ||
                    (v.cnic ?? '').contains(_search),))
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _VendorCard(vendor: vendor, canManage: widget.canManage),
                  ),
              ],
            ),
          AsyncError(:final error) => ErrorPanel.from(
              error,
              networkMessage: l10n.errNetwork,
              serverMessage: l10n.errServer,
              retryLabel: l10n.actionRetry,
              onRetry: () => ref.invalidate(vendorListProvider),
            ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ],
    );
  }
}

class _FilerExplained extends StatelessWidget {
  const _FilerExplained();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceSunken,
        borderRadius: BorderRadius.circular(AppRadii.container),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: AppSizes.iconMedium, color: colors.textMuted),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(l10n.vendorsFilerHelp, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}

String kindLabel(AppLocalizations l10n, String kind) => switch (kind) {
      'aop' => l10n.vendorKindAop,
      'individual' => l10n.vendorKindIndividual,
      'foreign' => l10n.vendorKindForeign,
      _ => l10n.vendorKindCompany,
    };

class _VendorCard extends ConsumerWidget {
  const _VendorCard({required this.vendor, required this.canManage});

  final Vendor vendor;
  final bool canManage;

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final form = await showDialog<VendorForm>(context: context, builder: (_) => VendorDialog(existing: vendor));
    if (form == null) return;
    final refusal = await ref.read(vendorActionsProvider.notifier).change(vendor.id, form.toRequest());
    messenger.showSnackBar(SnackBar(
      content: Text(refusal == null
          ? l10n.vendorSaved
          : errorMessageFor(refusal, network: l10n.errNetwork, server: l10n.errServer),),
    ),);
  }

  Future<void> _toggle(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final refusal = await ref.read(vendorActionsProvider.notifier).change(vendor.id, {'isActive': !vendor.isActive});
    messenger.showSnackBar(SnackBar(
      content: Text(refusal == null
          ? l10n.vendorSaved
          : errorMessageFor(refusal, network: l10n.errNetwork, server: l10n.errServer),),
    ),);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = Theme.of(context).textTheme;

    final ids = [
      if (vendor.ntn != null) '${l10n.fieldNtn} ${vendor.ntn}',
      if (vendor.cnic != null) '${l10n.fieldCnic} ${vendor.cnic}',
    ];

    final chips = <Widget>[
      if (!vendor.isForeign)
        switch (vendor.atlStatus) {
          'atl' => _Chip(icon: Icons.verified_outlined, label: l10n.filerYes, tone: _Tone.good),
          'non_atl' => _Chip(icon: Icons.report_outlined, label: l10n.filerNo, tone: _Tone.warn),
          _ => _Chip(icon: Icons.help_outline, label: l10n.filerUnknown, tone: _Tone.plain),
        },
      if (!vendor.isForeign && vendor.atlStatus != 'unknown' && vendor.atlCheckIsStale)
        _Chip(
          icon: Icons.event_repeat,
          label: l10n.filerCheckAgain(vendor.atlCheckedOn ?? ''),
          tone: _Tone.warn,
        ),
      if (!vendor.isForeign && !vendor.canBeWithheldFrom)
        _Chip(icon: Icons.badge_outlined, label: l10n.vendorNoTaxId, tone: _Tone.bad),
      if (!vendor.isActive) _Chip(icon: Icons.block, label: l10n.vendorSwitchedOff, tone: _Tone.bad),
    ];

    return Opacity(
      opacity: vendor.isActive ? 1 : 0.7,
      child: Material(
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
                  Expanded(child: Text(vendor.name, style: text.titleSmall)),
                  Text(kindLabel(l10n, vendor.kind), style: text.labelMedium),
                ],
              ),
              if (ids.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(ids.join('   '), style: text.bodySmall),
              ],
              if (chips.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: chips),
              ],
              if (canManage) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _edit(context, ref),
                      icon: const Icon(Icons.edit_outlined, size: AppSizes.iconSmall),
                      label: Text(l10n.actionEdit),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    TextButton(
                      onPressed: () => _toggle(context, ref),
                      child: Text(vendor.isActive ? l10n.actionSwitchOff : l10n.actionSwitchOn),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum _Tone { good, warn, bad, plain }

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, required this.tone});

  final IconData icon;
  final String label;
  final _Tone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (background, foreground) = switch (tone) {
      _Tone.good => (colors.accentSoft, colors.accent),
      _Tone.warn => (colors.pendingSoft, colors.pending),
      _Tone.bad => (colors.negativeSoft, colors.negative),
      _Tone.plain => (colors.surfaceSunken, colors.textMuted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadii.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSizes.iconSmall, color: foreground),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: foreground)),
        ],
      ),
    );
  }
}

/// Adding a vendor, or changing one. Returns the form, or null if cancelled.
class VendorDialog extends StatefulWidget {
  const VendorDialog({super.key, this.existing});
  final Vendor? existing;

  @override
  State<VendorDialog> createState() => _VendorDialogState();
}

class _VendorDialogState extends State<VendorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _ntn = TextEditingController(text: widget.existing?.ntn ?? '');
  late final _cnic = TextEditingController(text: widget.existing?.cnic ?? '');
  late final _country = TextEditingController(text: widget.existing?.country ?? '');
  late final _email = TextEditingController(text: widget.existing?.email ?? '');
  late final _phone = TextEditingController(text: widget.existing?.phone ?? '');
  late final _notes = TextEditingController(text: widget.existing?.notes ?? '');
  late String _kind = widget.existing?.kind ?? 'company';
  late String _atl = widget.existing?.atlStatus ?? 'unknown';
  late String _checkedOn = widget.existing?.atlCheckedOn ?? DateField.today();

  @override
  void dispose() {
    for (final controller in [_name, _ntn, _cnic, _country, _email, _phone, _notes]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final foreign = _kind == 'foreign';
    Navigator.of(context).pop(VendorForm(
      name: _name.text,
      kind: _kind,
      ntn: foreign ? '' : _ntn.text,
      cnic: foreign ? '' : _cnic.text,
      atlStatus: foreign ? 'unknown' : _atl,
      atlCheckedOn: foreign || _atl == 'unknown' ? null : _checkedOn,
      country: foreign ? _country.text : '',
      email: _email.text,
      phone: _phone.text,
      notes: _notes.text,
    ),);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final foreign = _kind == 'foreign';
    final noTaxId = !foreign && _ntn.text.trim().isEmpty && _cnic.text.trim().isEmpty;

    return AlertDialog(
      title: Text(widget.existing == null ? l10n.addVendorTitle : l10n.editVendorTitle),
      content: SizedBox(
        width: AppSizes.dialogWideWidth,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: InputDecoration(labelText: l10n.fieldVendorName),
                  validator: (v) => (v == null || v.trim().isEmpty) ? l10n.errNameRequired : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(l10n.fieldVendorKind, style: text.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: [
                    for (final kind in ['company', 'aop', 'individual', 'foreign'])
                      ButtonSegment(value: kind, label: Text(kindLabel(l10n, kind))),
                  ],
                  selected: {_kind},
                  onSelectionChanged: (value) => setState(() => _kind = value.first),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (foreign)
                  TextFormField(
                    controller: _country,
                    decoration: InputDecoration(labelText: l10n.fieldCountry, helperText: l10n.hintForeignVendor),
                  )
                else ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _ntn,
                          decoration: InputDecoration(labelText: l10n.fieldNtn),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: TextFormField(
                          controller: _cnic,
                          decoration: InputDecoration(labelText: l10n.fieldCnic),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  if (noTaxId) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(l10n.hintNoTaxId, style: text.bodySmall?.copyWith(color: colors.pending)),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  Text(l10n.fieldFilerStatus, style: text.labelLarge),
                  const SizedBox(height: AppSpacing.sm),
                  SegmentedButton<String>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(value: 'atl', label: Text(l10n.filerYes)),
                      ButtonSegment(value: 'non_atl', label: Text(l10n.filerNo)),
                      ButtonSegment(value: 'unknown', label: Text(l10n.filerUnknown)),
                    ],
                    selected: {_atl},
                    onSelectionChanged: (value) => setState(() => _atl = value.first),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _atl == 'unknown' ? l10n.hintFilerUnknown : l10n.hintFilerChecked,
                    style: text.bodySmall,
                  ),
                  if (_atl != 'unknown') ...[
                    const SizedBox(height: AppSpacing.md),
                    DateField(
                      value: _checkedOn,
                      onChanged: (value) => _checkedOn = value,
                      label: l10n.fieldCheckedOn,
                      hint: l10n.hintDateFormat,
                      pickTooltip: l10n.actionPickDate,
                    ),
                  ],
                ],
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(labelText: l10n.fieldEmailOptional),
                        validator: (v) => v == null || v.trim().isEmpty || RegExp(r'^\S+@\S+\.\S+$').hasMatch(v.trim())
                            ? null
                            : l10n.errEmailInvalid,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextFormField(
                        controller: _phone,
                        decoration: InputDecoration(labelText: l10n.fieldPhoneOptional),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _notes,
                  maxLines: 2,
                  decoration: InputDecoration(labelText: l10n.fieldNotesOptional),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.actionCancel)),
        FilledButton(onPressed: _save, child: Text(l10n.actionSave)),
      ],
    );
  }
}
