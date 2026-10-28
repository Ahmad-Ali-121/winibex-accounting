import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../import_export/presentation/import_export_screen.dart';
import '../../ledger_codes/application/ledger_codes_providers.dart';
import '../../ledger_codes/presentation/ledger_codes_screen.dart';
import '../../people/application/people_providers.dart';
import '../../people/presentation/people_screen.dart';
import '../../taxes/application/taxes_admin_providers.dart';
import '../../taxes/presentation/taxes_screen.dart';

/// The parts of Settings, each its own page.
enum SettingsSection { people, taxes, ledgerCodes, importExport }

/// Settings: a home of cards, each opening its own page. All the owner's;
/// anyone else sees one line saying so, and the server refuses them anyway.
/// Decisions 063, 067, 068 and 069.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.isOwner, required this.onOpen, this.section});

  final bool isOwner;

  /// Null for the home of cards.
  final SettingsSection? section;

  /// Opens a section, or the home for null. The router decides the address.
  final ValueChanged<SettingsSection?> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (!isOwner) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            l10n.settingsOwnerOnly,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    final page = section;
    if (page == null) return _SettingsHome(onOpen: onOpen);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const ValueKey('settings-back'),
              onPressed: () => onOpen(null),
              icon: const Icon(Icons.arrow_back, size: AppSizes.iconSmall),
              label: Text(l10n.settingsBack),
            ),
          ),
        ),
        Expanded(
          child: switch (page) {
            SettingsSection.people => const PeopleScreen(),
            SettingsSection.taxes => TaxesScreen(onImportExport: () => onOpen(SettingsSection.importExport)),
            SettingsSection.ledgerCodes => LedgerCodesScreen(
              onImportExport: () => onOpen(SettingsSection.importExport),
            ),
            SettingsSection.importExport => const ImportExportScreen(),
          },
        ),
      ],
    );
  }
}

class _SettingsHome extends ConsumerWidget {
  const _SettingsHome({required this.onOpen});
  final ValueChanged<SettingsSection?> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final colors = context.colors;

    final people = ref.watch(teamProvider).value;
    final taxes = ref.watch(taxesOverviewProvider).value;
    final codes = ref.watch(ledgerCodesProvider).value;

    final cards = [
      _SectionCard(
        key: const ValueKey('settings-card-people'),
        icon: Icons.group_outlined,
        title: l10n.peopleTitle,
        body: l10n.settingsPeopleExplain,
        summary: people == null ? null : l10n.settingsPeopleSummary(people.where((person) => person.isActive).length),
        onTap: () => onOpen(SettingsSection.people),
      ),
      _SectionCard(
        key: const ValueKey('settings-card-taxes'),
        icon: Icons.percent,
        title: l10n.taxesTitle,
        body: l10n.settingsTaxesExplain,
        summary: taxes == null
            ? null
            : l10n.settingsTaxesSummary(taxes.taxes.where((tax) => tax.standing == 'in_force').length),
        onTap: () => onOpen(SettingsSection.taxes),
      ),
      _SectionCard(
        key: const ValueKey('settings-card-ledger'),
        icon: Icons.account_tree_outlined,
        title: l10n.ledgerTitle,
        body: l10n.settingsLedgerExplain,
        summary: codes == null
            ? null
            : l10n.settingsLedgerSummary(
                codes.where((code) => code.isActive && !code.isHeader).length,
                codes.where((code) => code.isActive && code.isHeader).length,
              ),
        onTap: () => onOpen(SettingsSection.ledgerCodes),
      ),
      _SectionCard(
        key: const ValueKey('settings-card-import'),
        icon: Icons.import_export,
        title: l10n.bulkTitle,
        body: l10n.settingsImportExplain,
        summary: l10n.settingsImportSummary,
        onTap: () => onOpen(SettingsSection.importExport),
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        Text(l10n.navSettings, style: text.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(l10n.settingsIntro, style: text.bodyMedium),
        const SizedBox(height: AppSpacing.xl),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= AppSizes.twoColumnBreakpoint ? 2 : 1;
            final rows = <Widget>[];
            for (var i = 0; i < cards.length; i += columns) {
              final slice = cards.sublist(i, (i + columns).clamp(0, cards.length));
              rows.add(
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var j = 0; j < slice.length; j++) ...[
                          if (j > 0) const SizedBox(width: AppSpacing.lg),
                          Expanded(child: slice[j]),
                        ],
                        if (slice.length < columns) ...[
                          const SizedBox(width: AppSpacing.lg),
                          const Expanded(child: SizedBox.shrink()),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }
            return Column(children: rows);
          },
        ),
        Row(
          children: [
            Icon(Icons.history, size: AppSizes.iconSmall, color: colors.textMuted),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(l10n.settingsAuditNote, style: text.bodySmall?.copyWith(color: colors.textMuted)),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
    this.summary,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;

    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.rule),
        borderRadius: BorderRadius.circular(AppRadii.container),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: AppSizes.settingsIconTile,
                height: AppSizes.settingsIconTile,
                decoration: BoxDecoration(
                  color: colors.accentSoft,
                  borderRadius: BorderRadius.circular(AppRadii.container),
                ),
                child: Icon(icon, color: colors.accent),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: text.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(body, style: text.bodyMedium?.copyWith(color: colors.textMuted)),
                    if (summary != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                        decoration: BoxDecoration(
                          color: colors.surfaceSunken,
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                        ),
                        child: Text(summary!, style: text.labelMedium),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(Icons.chevron_right, color: colors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
