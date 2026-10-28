import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// The icon each role carries everywhere on the People screen, so the owner
/// learns three shapes once and recognises them on every card.
IconData roleIcon(String role) => switch (role) {
  'owner' => Icons.workspace_premium_outlined,
  'admin' => Icons.verified_user_outlined,
  _ => Icons.edit_note_outlined,
};

String roleLabel(AppLocalizations l10n, String role) => switch (role) {
  'owner' => l10n.roleOwner,
  'admin' => l10n.roleAdmin,
  _ => l10n.roleStaff,
};

/// What each role can do, in two layers. Three tiles say it in one line each,
/// always visible. Below them, a table answers "can an admin reverse an
/// entry?" without reading a paragraph. Decision 063.
class RoleGuide extends StatelessWidget {
  const RoleGuide({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    final tiles = [
      _RoleTile(role: 'owner', title: l10n.roleOwner, text: l10n.roleOwnerShort),
      _RoleTile(role: 'admin', title: l10n.roleAdmin, text: l10n.roleAdminShort),
      _RoleTile(role: 'staff', title: l10n.roleStaff, text: l10n.roleStaffShort),
    ];

    // A Material, not a coloured box, because the expanding row below paints
    // its ink on the nearest Material and a coloured box would hide it.
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.rule),
        borderRadius: BorderRadius.circular(AppRadii.container),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.roleHelpTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.roleGuideSubtitle, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSpacing.lg),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < AppSizes.formMaxWidth) {
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
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            Theme(
              // The tile's own divider lines would cut through the card.
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: Text(
                  l10n.roleGuideShowTable,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: colors.accent),
                ),
                children: const [_PermissionTable()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({required this.role, required this.title, required this.text});
  final String role;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
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
          RoleBadgeIcon(role: role),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xxs),
                Text(text, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The role's icon on a round tinted background. The owner is solid, an admin
/// tinted, staff neutral, so rank reads before the label does.
class RoleBadgeIcon extends StatelessWidget {
  const RoleBadgeIcon({super.key, required this.role});
  final String role;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (background, foreground) = switch (role) {
      'owner' => (colors.accent, colors.surface),
      'admin' => (colors.accentSoft, colors.accent),
      _ => (colors.reversedSoft, colors.text),
    };
    return Container(
      width: AppSizes.controlHeight,
      height: AppSizes.controlHeight,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(roleIcon(role), color: foreground, size: AppSizes.iconMedium),
    );
  }
}

enum _Can { yes, limited, no }

class _PermissionTable extends StatelessWidget {
  const _PermissionTable();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final small = Theme.of(context).textTheme.bodySmall;

    // Owner, admin, staff. Matches what the server enforces: approving,
    // reversing, transfers, vendors and cheques are owner or admin; people
    // and settings are the owner's alone.
    final rows = <(String, _Can, _Can, _Can)>[
      (l10n.capRecord, _Can.yes, _Can.yes, _Can.yes),
      (l10n.capPostOwn, _Can.yes, _Can.limited, _Can.no),
      (l10n.capApprove, _Can.yes, _Can.limited, _Can.no),
      (l10n.capMoveMoney, _Can.yes, _Can.yes, _Can.no),
      (l10n.capReverse, _Can.yes, _Can.yes, _Can.no),
      (l10n.capPayBack, _Can.yes, _Can.yes, _Can.no),
      (l10n.capVendorsCheques, _Can.yes, _Can.yes, _Can.no),
      (l10n.capClearFlags, _Can.yes, _Can.yes, _Can.no),
      (l10n.capPeople, _Can.yes, _Can.no, _Can.no),
    ];

    Widget cell(_Can can) => SizedBox(
      width: AppSizes.roleColumnWidth,
      child: Center(
        child: switch (can) {
          _Can.yes => Icon(
            Icons.check_circle,
            color: colors.accent,
            size: AppSizes.iconMedium,
            semanticLabel: l10n.a11yYes,
          ),
          _Can.limited => Tooltip(
            message: l10n.capLimitedTip,
            child: Icon(
              Icons.tune,
              color: colors.pending,
              size: AppSizes.iconMedium,
              semanticLabel: l10n.capLimited,
            ),
          ),
          _Can.no => Icon(
            Icons.remove,
            color: colors.ruleStrong,
            size: AppSizes.iconMedium,
            semanticLabel: l10n.a11yNo,
          ),
        },
      ),
    );

    Widget heading(String text) => SizedBox(
      width: AppSizes.roleColumnWidth,
      child: Text(text, textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelMedium),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.ruleStrong)),
          ),
          child: Row(
            children: [
              Expanded(child: Text(l10n.roleGuideTask, style: Theme.of(context).textTheme.labelMedium)),
              heading(l10n.roleOwner),
              heading(l10n.roleAdmin),
              heading(l10n.roleStaff),
            ],
          ),
        ),
        for (final (task, owner, admin, staff) in rows)
          Container(
            constraints: const BoxConstraints(minHeight: AppSizes.rowCompact),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.rule)),
            ),
            child: Row(
              children: [
                Expanded(child: Text(task, style: Theme.of(context).textTheme.bodyMedium)),
                cell(owner),
                cell(admin),
                cell(staff),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        _Note(icon: Icons.tune, color: colors.pending, text: l10n.capLimitedTip, style: small),
        const SizedBox(height: AppSpacing.sm),
        _Note(icon: Icons.key_outlined, color: colors.textMuted, text: l10n.officeLoginHelp, style: small),
        const SizedBox(height: AppSpacing.sm),
        _Note(
          icon: Icons.person_off_outlined,
          color: colors.textMuted,
          text: l10n.peopleNobodyDeleted,
          style: small,
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.color, required this.text, required this.style});
  final IconData icon;
  final Color color;
  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: AppSizes.iconSmall, color: color),
      const SizedBox(width: AppSpacing.sm),
      Expanded(child: Text(text, style: style)),
    ],
  );
}
