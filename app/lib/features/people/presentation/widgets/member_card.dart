import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/money_text.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/team_member.dart';
import 'role_guide.dart';

/// What can be done to a person from their card.
enum MemberAction { edit, resetPassword, switchOff, switchOn }

/// One person: who they are, their role, and in plain words what is special
/// about them. The office login gets no actions; it always has full access.
class MemberCard extends StatelessWidget {
  const MemberCard({super.key, required this.member, required this.onAction});

  final TeamMember member;
  final ValueChanged<MemberAction> onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = Theme.of(context).textTheme;

    final chips = <Widget>[
      if (member.isOwner)
        StatusChip(icon: Icons.verified, label: l10n.peopleFullAccess, tone: ChipTone.accent),
      if (member.isAdmin)
        member.approvalLimit == null
            ? StatusChip(icon: Icons.all_inclusive, label: l10n.peopleNoLimit, tone: ChipTone.accent)
            : StatusChip(
                icon: Icons.payments_outlined,
                label: l10n.peopleApprovesUpTo,
                tone: ChipTone.accent,
                trailing: MoneyText(
                  member.approvalLimit!,
                  size: 12.5,
                  weight: FontWeight.w600,
                  withCurrency: true,
                ),
              ),
      if (member.isAdmin && member.autoApproveOwn)
        StatusChip(icon: Icons.bolt_outlined, label: l10n.peoplePostsOwn, tone: ChipTone.neutral),
      if (member.isAdmin && !member.autoApproveOwn)
        StatusChip(icon: Icons.hourglass_empty, label: l10n.peopleOwnNeedApproval, tone: ChipTone.neutral),
      if (!member.isOwner && !member.isAdmin)
        StatusChip(icon: Icons.hourglass_empty, label: l10n.peopleNeedsApproval, tone: ChipTone.neutral),
      if (member.sharesOwnerLogin)
        StatusChip(icon: Icons.key_outlined, label: l10n.peopleSharesLogin, tone: ChipTone.neutral),
      if (member.mustChangePassword)
        StatusChip(icon: Icons.lock_clock_outlined, label: l10n.peopleMustChange, tone: ChipTone.pending),
      if (!member.isActive)
        StatusChip(icon: Icons.block, label: l10n.peopleSwitchedOff, tone: ChipTone.negative),
    ];

    return Opacity(
      // A switched-off person stays readable, just quieter.
      opacity: member.isActive ? 1 : 0.7,
      // A Material, so the buttons' ink shows on the card.
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: member.isOwner ? colors.accent : colors.rule),
          borderRadius: BorderRadius.circular(AppRadii.container),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          // Two halves pushed apart, so when two cards share a row the buttons
          // line up at the bottom.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _Initials(name: member.name, role: member.role, active: member.isActive),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              member.name,
                              style: text.titleSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              member.email,
                              style: text.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      RolePill(role: member.role),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: chips),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.md),
                  Divider(height: 1, color: colors.rule),
                  const SizedBox(height: AppSpacing.sm),
                  if (member.isOwner)
                    Text(l10n.peopleOwnerNote, style: text.bodySmall)
                  else
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => onAction(MemberAction.edit),
                          icon: const Icon(Icons.edit_outlined, size: AppSizes.iconSmall),
                          label: Text(l10n.actionEdit),
                        ),
                        const Spacer(),
                        PopupMenuButton<MemberAction>(
                          tooltip: l10n.actionMore,
                          icon: const Icon(Icons.more_horiz),
                          onSelected: onAction,
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: MemberAction.resetPassword,
                              child: _MenuRow(icon: Icons.lock_reset, label: l10n.actionResetPassword),
                            ),
                            member.isActive
                                ? PopupMenuItem(
                                    value: MemberAction.switchOff,
                                    child: _MenuRow(
                                      icon: Icons.person_off_outlined,
                                      label: l10n.actionSwitchOff,
                                      color: colors.negative,
                                    ),
                                  )
                                : PopupMenuItem(
                                    value: MemberAction.switchOn,
                                    child: _MenuRow(icon: Icons.person_outline, label: l10n.actionSwitchOn),
                                  ),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label, this.color});
  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: AppSizes.iconMedium, color: color),
      const SizedBox(width: AppSpacing.md),
      Text(label, style: color == null ? null : TextStyle(color: color)),
    ],
  );
}

/// The first letters of a name, so a list of people scans by face rather than
/// by reading every line.
class _Initials extends StatelessWidget {
  const _Initials({required this.name, required this.role, required this.active});
  final String name;
  final String role;
  final bool active;

  String get _letters {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    final first = words.first.characters.first;
    final last = words.length > 1 ? words.last.characters.first : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (background, foreground) = !active
        ? (colors.reversedSoft, colors.textMuted)
        : role == 'owner'
        ? (colors.accent, colors.surface)
        : (colors.accentSoft, colors.accent);
    return Container(
      width: AppSizes.avatar,
      height: AppSizes.avatar,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Text(
        _letters,
        style: Theme.of(context).textTheme.labelLarge
            ?.copyWith(color: foreground, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// The role as a small badge with its icon.
class RolePill extends StatelessWidget {
  const RolePill({super.key, required this.role});
  final String role;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final (background, foreground) = switch (role) {
      'owner' => (colors.accent, colors.surface),
      'admin' => (colors.accentSoft, colors.accent),
      _ => (colors.reversedSoft, colors.text),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadii.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(roleIcon(role), size: AppSizes.iconSmall, color: foreground),
          const SizedBox(width: AppSpacing.xs),
          Text(
            roleLabel(l10n, role),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}

enum ChipTone { accent, neutral, pending, negative }

/// A fact about a person, with an icon so it never relies on colour alone.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.icon, required this.label, required this.tone, this.trailing});

  final IconData icon;
  final String label;
  final ChipTone tone;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (background, foreground) = switch (tone) {
      ChipTone.accent => (colors.accentSoft, colors.accent),
      ChipTone.neutral => (colors.surfaceSunken, colors.textMuted),
      ChipTone.pending => (colors.pendingSoft, colors.pending),
      ChipTone.negative => (colors.negativeSoft, colors.negative),
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
          if (trailing != null) ...[const SizedBox(width: AppSpacing.xs), trailing!],
        ],
      ),
    );
  }
}
