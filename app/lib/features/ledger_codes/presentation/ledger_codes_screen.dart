import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/error_message.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_panel.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/ledger_codes_providers.dart';
import '../data/ledger_codes_repository.dart';
import '../domain/ledger_code.dart';

/// The chart of accounts: every code the books file amounts under, grouped by
/// headings. The owner's, under Settings. Decisions 068 and 069.
///
/// Migration 002 puts the whole chart back on a fresh database, so this is
/// not needed after a reset. It is for the codes and headings added later,
/// such as a new expense head the accountant asks for. Many at once come in
/// through Import and export. Nothing is ever deleted: a code no longer
/// needed is switched off, and the entries that used it keep it.
class LedgerCodesScreen extends ConsumerStatefulWidget {
  const LedgerCodesScreen({super.key, this.onImportExport});

  /// Opens Import and export. Null hides the button.
  final VoidCallback? onImportExport;

  @override
  ConsumerState<LedgerCodesScreen> createState() => _LedgerCodesScreenState();
}

class _LedgerCodesScreenState extends ConsumerState<LedgerCodesScreen> {
  String _search = '';
  bool _showOff = false;

  bool _matches(LedgerCode code) {
    final query = _search.trim().toLowerCase();
    if (query.isEmpty) return true;
    return code.code.startsWith(query) || code.name.toLowerCase().contains(query);
  }

  void _add(List<LedgerCode> all, {required bool heading}) => _openAndConfirm(
    context,
    (context) => showDialog<bool>(
      context: context,
      builder: (_) => AddCodeDialog(all: all, isHeading: heading),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final codes = ref.watch(ledgerCodesProvider);
    final all = codes.value ?? const <LedgerCode>[];

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        Text(l10n.ledgerTitle, style: text.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(l10n.ledgerIntro, style: text.bodyMedium),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            FilledButton.icon(
              key: const ValueKey('ledger-add-code'),
              onPressed: codes.hasValue ? () => _add(all, heading: false) : null,
              icon: const Icon(Icons.add),
              label: Text(l10n.actionAddCode),
            ),
            OutlinedButton.icon(
              key: const ValueKey('ledger-add-heading'),
              onPressed: codes.hasValue ? () => _add(all, heading: true) : null,
              icon: const Icon(Icons.create_new_folder_outlined),
              label: Text(l10n.actionAddHeading),
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
        const _HowItWorks(),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          key: const ValueKey('ledger-search'),
          onChanged: (value) => setState(() => _search = value),
          decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: l10n.ledgerSearchHint),
        ),
        Material(
          type: MaterialType.transparency,
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _showOff,
            onChanged: (value) => setState(() => _showOff = value),
            title: Text(l10n.ledgerShowOff, style: text.bodyMedium),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        switch (codes) {
          AsyncData(:final value) => _Chart(
            all: value,
            shown: value.where((code) => (_showOff || code.isActive) && _matches(code)).toList(),
            searching: _search.trim().isNotEmpty,
          ),
          AsyncError(:final error) => ErrorPanel.from(
            error,
            networkMessage: l10n.errNetwork,
            serverMessage: l10n.errServer,
            retryLabel: l10n.actionRetry,
            onRetry: () => ref.invalidate(ledgerCodesProvider),
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ],
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

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
          Text(l10n.ledgerHowTitle, style: text.titleSmall),
          line(Icons.looks_one_outlined, l10n.ledgerHowDigits),
          line(Icons.folder_outlined, l10n.ledgerHowHeadings),
          line(Icons.lock_outline, l10n.ledgerHowBuiltIn),
          line(Icons.toggle_off_outlined, l10n.ledgerHowSwitchOff),
        ],
      ),
    );
  }
}

/// Opens a dialog that saves by itself and closes with true when it did,
/// then says so.
Future<void> _openAndConfirm(BuildContext context, Future<bool?> Function(BuildContext) open) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final done = await open(context);
  if (done == true) messenger.showSnackBar(SnackBar(content: Text(l10n.ledgerSaved)));
}

String ledgerClassName(AppLocalizations l10n, int digit) => switch (digit) {
  1 => l10n.ledgerClass1,
  2 => l10n.ledgerClass2,
  3 => l10n.ledgerClass3,
  4 => l10n.ledgerClass4,
  5 => l10n.ledgerClass5,
  6 => l10n.ledgerClass6,
  7 => l10n.ledgerClass7,
  8 => l10n.ledgerClass8,
  _ => l10n.ledgerClass9,
};

class _Chart extends StatelessWidget {
  const _Chart({required this.all, required this.shown, required this.searching});
  final List<LedgerCode> all;
  final List<LedgerCode> shown;
  final bool searching;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    if (shown.isEmpty) {
      return Text(searching ? l10n.ledgerNoMatch : l10n.ledgerEmpty, style: text.bodyMedium);
    }

    final byId = {for (final code in all) code.id: code};
    final classes = <int, List<LedgerCode>>{};
    for (final code in shown) {
      classes.putIfAbsent(code.classDigit, () => []).add(code);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in classes.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
            child: Text('${entry.key}000  ${ledgerClassName(l10n, entry.key)}', style: text.titleMedium),
          ),
          _ClassCard(codes: entry.value, all: all, byId: byId, indent: !searching),
        ],
      ],
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({required this.codes, required this.all, required this.byId, required this.indent});
  final List<LedgerCode> codes;
  final List<LedgerCode> all;
  final Map<int, LedgerCode> byId;
  final bool indent;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.rule),
        borderRadius: BorderRadius.circular(AppRadii.container),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < codes.length; i++) ...[
            if (i > 0) Divider(height: 1, color: colors.rule),
            _CodeRow(code: codes[i], all: all, depth: indent ? depthOf(codes[i], byId) : 0),
          ],
        ],
      ),
    );
  }
}

class _CodeRow extends ConsumerWidget {
  const _CodeRow({required this.code, required this.all, required this.depth});
  final LedgerCode code;
  final List<LedgerCode> all;
  final int depth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final muted = !code.isActive;
    final heading = code.isHeader;

    final baseStyle = heading ? text.labelLarge : text.bodyMedium;
    final textStyle = baseStyle?.copyWith(
      color: muted || heading ? colors.textMuted : null,
      decoration: muted ? TextDecoration.lineThrough : null,
    );

    return Container(
      color: heading ? colors.surfaceSunken : null,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        heading ? AppSpacing.sm : AppSpacing.md,
        AppSpacing.xs,
        heading ? AppSpacing.sm : AppSpacing.md,
      ),
      child: Row(
        children: [
          SizedBox(
            width: AppSizes.ledgerCodeColumnWidth,
            child: Text(code.code, style: textStyle?.copyWith(fontFeatures: AppFonts.tabular)),
          ),
          SizedBox(width: AppSizes.ledgerIndent * depth),
          if (heading) ...[
            Icon(Icons.folder_outlined, size: AppSizes.iconSmall, color: colors.textMuted),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(code.name, style: textStyle),
                if (code.isSystem || code.onEntryForm || muted) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      if (code.isSystem)
                        _Chip(
                          label: l10n.ledgerBuiltIn,
                          tooltip: l10n.ledgerBuiltInExplain,
                          background: colors.reversedSoft,
                          foreground: colors.reversed,
                        ),
                      if (code.onEntryForm)
                        _Chip(
                          label: l10n.ledgerOnEntryForm,
                          tooltip: l10n.ledgerOnEntryFormExplain,
                          background: colors.accentSoft,
                          foreground: colors.accent,
                        ),
                      if (muted)
                        _Chip(
                          label: l10n.ledgerSwitchedOff,
                          tooltip: l10n.ledgerSwitchedOffExplain,
                          background: colors.pendingSoft,
                          foreground: colors.pending,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (heading && !code.canChange)
            Tooltip(
              message: l10n.ledgerHeadingExplain,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Icon(Icons.info_outline, size: AppSizes.iconSmall, color: colors.textMuted),
              ),
            ),
          if (code.canChange)
            PopupMenuButton<String>(
              key: ValueKey('ledger-menu-${code.code}'),
              tooltip: l10n.actionMore,
              icon: const Icon(Icons.more_vert, size: AppSizes.iconMedium),
              onSelected: (choice) => _choose(context, ref, choice),
              itemBuilder: (context) => [
                PopupMenuItem(value: 'edit', child: Text(l10n.actionEdit)),
                PopupMenuItem(value: 'active', child: Text(code.isActive ? l10n.actionSwitchOff : l10n.actionSwitchOn)),
              ],
            )
          else if (!heading)
            const SizedBox(width: AppSizes.avatar),
        ],
      ),
    );
  }

  Future<void> _choose(BuildContext context, WidgetRef ref, String choice) async {
    if (choice == 'edit') {
      await _openAndConfirm(
        context,
        (context) => showDialog<bool>(
          context: context,
          builder: (_) => EditCodeDialog(code: code, all: all),
        ),
      );
      return;
    }
    if (code.isActive) {
      await _openAndConfirm(
        context,
        (context) => showDialog<bool>(
          context: context,
          builder: (_) => SwitchOffCodeDialog(code: code),
        ),
      );
      return;
    }

    // Switching back on loses nothing, so it needs no question first.
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final refusal = await ref
        .read(ledgerCodeActionsProvider.notifier)
        .run((repository) => repository.setActive(code.id, isActive: true));
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          refusal == null
              ? l10n.ledgerSaved
              : errorMessageFor(refusal, network: l10n.errNetwork, server: l10n.errServer),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.tooltip, required this.background, required this.foreground});
  final String label;
  final String tooltip;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadii.pill)),
        child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: foreground)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dialogs. Each saves through LedgerCodeActions and closes with true when it
// worked; a refusal is shown inside it, in the server's words.
// ---------------------------------------------------------------------------

final _codeShape = RegExp(r'^[1-9]\d{3}$');

mixin _Saving<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  bool busy = false;
  Object? refusal;

  Future<void> save(Future<void> Function(LedgerCodesRepository repository) call) async {
    setState(() {
      busy = true;
      refusal = null;
    });
    final navigator = Navigator.of(context);
    final result = await ref.read(ledgerCodeActionsProvider.notifier).run(call);
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

String? _checkName(AppLocalizations l10n, String? value) =>
    value != null && value.trim().length >= 3 ? null : l10n.errLedgerNameShort;

/// The heading picker: the nearest one automatically, or one chosen.
class _ParentPicker extends StatelessWidget {
  const _ParentPicker({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.allowAutomatic,
  });

  final List<LedgerCode> options;
  final String selected;
  final ValueChanged<String> onSelected;

  /// Adding: empty means the server picks the nearest heading.
  final bool allowAutomatic;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DropdownMenu<String>(
      initialSelection: selected,
      expandedInsets: EdgeInsets.zero,
      menuHeight: AppSizes.menuMaxHeight,
      label: Text(l10n.fieldLedgerParent),
      helperText: l10n.hintLedgerParent,
      dropdownMenuEntries: [
        if (allowAutomatic) DropdownMenuEntry(value: '', label: l10n.ledgerParentNearest),
        for (final heading in options)
          DropdownMenuEntry(value: heading.code, label: '${heading.code}  ${heading.name}'),
      ],
      onSelected: (value) => onSelected(value ?? ''),
    );
  }
}

class AddCodeDialog extends ConsumerStatefulWidget {
  const AddCodeDialog({super.key, required this.all, required this.isHeading});
  final List<LedgerCode> all;
  final bool isHeading;

  @override
  ConsumerState<AddCodeDialog> createState() => _AddCodeDialogState();
}

class _AddCodeDialogState extends ConsumerState<AddCodeDialog> with _Saving {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _name = TextEditingController();
  bool _onEntryForm = true;
  String _parent = '';

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final valid = _codeShape.hasMatch(_code.text);
    final digit = valid ? classOfCode(_code.text) : null;
    final heading = widget.isHeading;

    return AlertDialog(
      title: Text(heading ? l10n.ledgerAddHeadingTitle : l10n.ledgerAddTitle),
      content: SizedBox(
        width: AppSizes.dialogWidth,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(heading ? l10n.ledgerAddHeadingHint : l10n.ledgerAddHint, style: text.bodySmall),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  key: const ValueKey('ledger-code-field'),
                  controller: _code,
                  autofocus: true,
                  maxLength: 4,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() => _parent = ''),
                  decoration: InputDecoration(
                    labelText: l10n.fieldLedgerCode,
                    helperText: digit == null
                        ? l10n.ledgerCodeHelp
                        : l10n.ledgerGoesUnder(ledgerClassName(l10n, digit)),
                  ),
                  validator: (value) => value != null && _codeShape.hasMatch(value) ? null : l10n.errLedgerCodeShape,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  key: const ValueKey('ledger-name-field'),
                  controller: _name,
                  decoration: InputDecoration(labelText: l10n.fieldLedgerName),
                  validator: (value) => _checkName(l10n, value),
                ),
                if (valid) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _ParentPicker(
                    key: ValueKey('ledger-parent-${_code.text}'),
                    options: headingsFor(_code.text, widget.all),
                    selected: _parent,
                    allowAutomatic: true,
                    onSelected: (value) => setState(() => _parent = value),
                  ),
                ],
                if (!heading && canJoinEntryForm(digit)) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Material(
                    type: MaterialType.transparency,
                    child: SwitchListTile(
                      key: const ValueKey('ledger-entry-form-switch'),
                      contentPadding: EdgeInsets.zero,
                      value: _onEntryForm,
                      onChanged: (value) => setState(() => _onEntryForm = value),
                      title: Text(l10n.ledgerAddToEntryForm, style: text.bodyMedium),
                      subtitle: Text(l10n.ledgerAddToEntryFormHint, style: text.bodySmall),
                    ),
                  ),
                ],
                refusalText(context),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: busy ? null : () => Navigator.of(context).pop(), child: Text(l10n.actionCancel)),
        FilledButton(
          key: const ValueKey('ledger-add-save'),
          onPressed: busy
              ? null
              : () {
                  if (!_formKey.currentState!.validate()) return;
                  save(
                    (repository) => repository.create(
                      code: _code.text,
                      name: _name.text.trim(),
                      isHeading: heading,
                      parentCode: _parent.isEmpty ? null : _parent,
                      addToEntryForm: !heading && canJoinEntryForm(digit) && _onEntryForm,
                    ),
                  );
                },
          child: Text(heading ? l10n.actionAddHeading : l10n.actionAddCode),
        ),
      ],
    );
  }
}

class EditCodeDialog extends ConsumerStatefulWidget {
  const EditCodeDialog({super.key, required this.code, required this.all});
  final LedgerCode code;
  final List<LedgerCode> all;

  @override
  ConsumerState<EditCodeDialog> createState() => _EditCodeDialogState();
}

class _EditCodeDialogState extends ConsumerState<EditCodeDialog> with _Saving {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.code.name);
  late String _parent = widget.code.parentCode ?? '';

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final code = widget.code;
    final options = [
      ...headingsFor(code.code, widget.all, exceptId: code.id),
      ...widget.all.where(
        (item) => item.code == code.parentCode && !(item.isActive && item.code.compareTo(code.code) < 0),
      ),
    ];

    return AlertDialog(
      title: Text(l10n.ledgerEditTitle('${code.code} ${code.name}')),
      content: SizedBox(
        width: AppSizes.dialogWidth,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.ledgerEditHint(code.code), style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                key: const ValueKey('ledger-rename-field'),
                controller: _name,
                autofocus: true,
                decoration: InputDecoration(labelText: l10n.fieldLedgerName),
                validator: (value) => _checkName(l10n, value),
              ),
              if (options.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                _ParentPicker(
                  options: options,
                  selected: _parent,
                  allowAutomatic: _parent.isEmpty,
                  onSelected: (value) => setState(() => _parent = value),
                ),
              ],
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
                  final name = _name.text.trim();
                  final nameChanged = name != code.name;
                  final parentChanged = _parent.isNotEmpty && _parent != code.parentCode;
                  if (!nameChanged && !parentChanged) {
                    Navigator.of(context).pop();
                    return;
                  }
                  save(
                    (repository) => repository.update(
                      code.id,
                      name: nameChanged ? name : null,
                      parentCode: parentChanged ? _parent : null,
                    ),
                  );
                },
          child: Text(l10n.actionSave),
        ),
      ],
    );
  }
}

class SwitchOffCodeDialog extends ConsumerStatefulWidget {
  const SwitchOffCodeDialog({super.key, required this.code});
  final LedgerCode code;

  @override
  ConsumerState<SwitchOffCodeDialog> createState() => _SwitchOffCodeDialogState();
}

class _SwitchOffCodeDialogState extends ConsumerState<SwitchOffCodeDialog> with _Saving {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.ledgerSwitchOffTitle('${widget.code.code} ${widget.code.name}')),
      content: SizedBox(
        width: AppSizes.dialogWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.code.isHeader ? l10n.ledgerSwitchOffHeadingHint : l10n.ledgerSwitchOffHint,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            refusalText(context),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: busy ? null : () => Navigator.of(context).pop(), child: Text(l10n.actionCancel)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: context.colors.negative),
          onPressed: busy ? null : () => save((repository) => repository.setActive(widget.code.id, isActive: false)),
          child: Text(l10n.actionSwitchOff),
        ),
      ],
    );
  }
}
