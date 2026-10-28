import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/error_message.dart';
import '../../../core/files/csv_files.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../ledger_codes/application/ledger_codes_providers.dart';
import '../../taxes/application/taxes_admin_providers.dart';
import '../../transactions/application/categories_providers.dart';
import '../data/bulk_repository.dart';
import '../domain/import_plan.dart';

/// Ledger codes and taxes in and out as spreadsheet files, for the accountant.
/// The owner's, under Settings. Decision 069.
///
/// Nothing is saved until the person has seen what the file will change,
/// row by row, and confirmed it.
class ImportExportScreen extends StatelessWidget {
  const ImportExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        Text(l10n.bulkTitle, style: text.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(l10n.bulkIntro, style: text.bodyMedium),
        const SizedBox(height: AppSpacing.xl),
        const _Steps(),
        const SizedBox(height: AppSpacing.xl),
        const _BulkCard(kind: BulkKind.ledgerCodes),
        const SizedBox(height: AppSpacing.lg),
        const _BulkCard(kind: BulkKind.taxes),
      ],
    );
  }
}

class _Steps extends StatelessWidget {
  const _Steps();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final steps = [l10n.bulkStep1, l10n.bulkStep2, l10n.bulkStep3];
    final wide = MediaQuery.sizeOf(context).width >= AppSizes.twoColumnBreakpoint;
    final tiles = [for (var i = 0; i < steps.length; i++) _StepTile(number: i + 1, text: steps[i])];

    if (!wide) {
      return Column(
        children: [
          for (final tile in tiles)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: tile,
            ),
        ],
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.md),
            Expanded(child: tiles[i]),
          ],
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({required this.number, required this.text});
  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: colors.surfaceSunken, borderRadius: BorderRadius.circular(AppRadii.container)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppSizes.stepBadge,
            height: AppSizes.stepBadge,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: colors.accentSoft, shape: BoxShape.circle),
            child: Text('$number', style: theme.labelLarge?.copyWith(color: colors.accent)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(text, style: theme.bodyMedium)),
        ],
      ),
    );
  }
}

class _BulkCard extends ConsumerStatefulWidget {
  const _BulkCard({required this.kind});
  final BulkKind kind;

  @override
  ConsumerState<_BulkCard> createState() => _BulkCardState();
}

class _BulkCardState extends ConsumerState<_BulkCard> {
  bool _busy = false;

  Future<void> _download({required bool template}) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final repository = ref.read(bulkRepositoryProvider);
      final file = template ? await repository.template(widget.kind) : await repository.exportList(widget.kind);
      await ref.read(csvFilesProvider).save(filename: file.filename, csv: file.csv);
      messenger.showSnackBar(SnackBar(content: Text(l10n.bulkDownloaded(file.filename))));
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(errorMessageFor(error, network: l10n.errNetwork, server: l10n.errServer)),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final picked = await ref.read(csvFilesProvider).pick();
    if (picked == null || !mounted) return;

    setState(() => _busy = true);
    ImportPlan plan;
    try {
      plan = await ref.read(bulkRepositoryProvider).importFile(widget.kind, picked.text, apply: false);
    } catch (error) {
      if (mounted) setState(() => _busy = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(errorMessageFor(error, network: l10n.errNetwork, server: l10n.errServer)),
        ),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);

    final saved = await showDialog<ImportPlan>(
      context: context,
      builder: (_) => ImportPreviewDialog(kind: widget.kind, filename: picked.name, csv: picked.text, plan: plan),
    );
    if (saved != null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.bulkSaved(saved.added, saved.updated, saved.skipped))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final isLedger = widget.kind == BulkKind.ledgerCodes;

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
              children: [
                _IconTile(icon: isLedger ? Icons.account_tree_outlined : Icons.percent),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text(isLedger ? l10n.ledgerTitle : l10n.taxesTitle, style: text.titleMedium)),
                if (_busy) const SizedBox.square(dimension: AppSizes.iconMedium, child: CircularProgressIndicator()),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(isLedger ? l10n.bulkLedgerExplain : l10n.bulkTaxesExplain, style: text.bodyMedium),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                OutlinedButton.icon(
                  key: ValueKey('bulk-template-${widget.kind.path}'),
                  onPressed: _busy ? null : () => _download(template: true),
                  icon: const Icon(Icons.description_outlined, size: AppSizes.iconSmall),
                  label: Text(l10n.actionDownloadTemplate),
                ),
                OutlinedButton.icon(
                  key: ValueKey('bulk-export-${widget.kind.path}'),
                  onPressed: _busy ? null : () => _download(template: false),
                  icon: const Icon(Icons.download_outlined, size: AppSizes.iconSmall),
                  label: Text(l10n.actionDownloadCurrent),
                ),
                FilledButton.icon(
                  key: ValueKey('bulk-import-${widget.kind.path}'),
                  onPressed: _busy ? null : _import,
                  icon: const Icon(Icons.upload_file_outlined, size: AppSizes.iconSmall),
                  label: Text(l10n.actionImportFile),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: AppSizes.avatar,
      height: AppSizes.avatar,
      decoration: BoxDecoration(color: colors.accentSoft, borderRadius: BorderRadius.circular(AppRadii.control)),
      child: Icon(icon, color: colors.accent, size: AppSizes.iconMedium),
    );
  }
}

/// What a file will change, row by row, before anything is saved. Closes
/// with the saved plan, or null if the person went back.
class ImportPreviewDialog extends ConsumerStatefulWidget {
  const ImportPreviewDialog({
    super.key,
    required this.kind,
    required this.filename,
    required this.csv,
    required this.plan,
  });

  final BulkKind kind;
  final String filename;
  final String csv;
  final ImportPlan plan;

  @override
  ConsumerState<ImportPreviewDialog> createState() => _ImportPreviewDialogState();
}

class _ImportPreviewDialogState extends ConsumerState<ImportPreviewDialog> {
  bool _busy = false;
  bool _showUnchanged = false;
  Object? _refusal;

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _refusal = null;
    });
    final navigator = Navigator.of(context);
    try {
      final saved = await ref.read(bulkRepositoryProvider).importFile(widget.kind, widget.csv, apply: true);
      ref.invalidate(ledgerCodesProvider);
      ref.invalidate(taxesOverviewProvider);
      ref.invalidate(categoryGroupsProvider);
      navigator.pop(saved);
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
    final plan = widget.plan;
    final shown = plan.rows.where((row) => _showUnchanged || row.action != 'unchanged').toList();

    return AlertDialog(
      title: Text(l10n.bulkPreviewTitle(widget.filename)),
      content: SizedBox(
        width: AppSizes.dialogPreviewWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.bulkPreviewHint, style: text.bodySmall),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _CountChip(
                  label: l10n.bulkCountAdd(plan.added),
                  background: colors.accentSoft,
                  foreground: colors.accent,
                ),
                _CountChip(
                  label: l10n.bulkCountUpdate(plan.updated),
                  background: colors.pendingSoft,
                  foreground: colors.pending,
                ),
                _CountChip(
                  label: l10n.bulkCountUnchanged(plan.unchanged),
                  background: colors.reversedSoft,
                  foreground: colors.reversed,
                ),
                _CountChip(
                  label: l10n.bulkCountSkip(plan.skipped),
                  background: colors.negativeSoft,
                  foreground: colors.negative,
                ),
              ],
            ),
            if (plan.unchanged > 0)
              Material(
                type: MaterialType.transparency,
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _showUnchanged,
                  onChanged: (value) => setState(() => _showUnchanged = value),
                  title: Text(l10n.bulkShowUnchanged, style: text.bodyMedium),
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxHeight: AppSizes.previewListHeight),
                decoration: BoxDecoration(
                  border: Border.all(color: colors.rule),
                  borderRadius: BorderRadius.circular(AppRadii.control),
                ),
                child: shown.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Text(l10n.bulkNothingToShow, style: text.bodyMedium),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: shown.length,
                        separatorBuilder: (context, index) => Divider(height: 1, color: colors.rule),
                        itemBuilder: (context, index) => _PlanRow(row: shown[index]),
                      ),
              ),
            ),
            if (plan.toSave == 0) ...[
              const SizedBox(height: AppSpacing.md),
              Text(l10n.bulkNothingToSave, style: text.bodyMedium?.copyWith(color: colors.pending)),
            ],
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
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.of(context).pop(), child: Text(l10n.actionCancel)),
        FilledButton(
          key: const ValueKey('bulk-confirm'),
          onPressed: _busy || plan.toSave == 0 ? null : _save,
          child: Text(l10n.bulkSaveChanges(plan.toSave)),
        ),
      ],
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label, required this.background, required this.foreground});
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadii.pill)),
      child: Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: foreground)),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.row});
  final ImportRow row;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = Theme.of(context).textTheme;

    final (icon, color, label) = switch (row.action) {
      'add' => (Icons.add_circle_outline, colors.accent, l10n.bulkActionAdd),
      'update' => (Icons.edit_outlined, colors.pending, l10n.bulkActionUpdate),
      'skip' => (Icons.block, colors.negative, l10n.bulkActionSkip),
      _ => (Icons.check, colors.textMuted, l10n.bulkActionUnchanged),
    };
    final where = row.rows.length == 1 ? l10n.bulkRow(row.rows.first) : l10n.bulkRows(row.rows.join(', '));
    final details = row.action == 'skip' ? [row.reason ?? ''] : row.changes;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: AppSizes.iconMedium),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text([row.code, row.name].where((part) => part.isNotEmpty).join('  '), style: text.titleSmall),
                Text('$where  ·  $label', style: text.labelSmall?.copyWith(color: color)),
                for (final detail in details)
                  if (detail.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xxs),
                      child: Text(detail, style: text.bodySmall),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
