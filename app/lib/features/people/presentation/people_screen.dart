import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/error_message.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_panel.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/people_providers.dart';
import '../domain/team_member.dart';
import 'widgets/member_card.dart';
import 'widgets/member_dialog.dart';
import 'widgets/role_guide.dart';

/// People and what each may do. The owner's screen: the router shows it only
/// to the owner, and the server refuses everyone else anyway.
///
/// Laid out to be understood without training: what each role means first,
/// then everyone grouped by role, each card saying in plain words what is
/// special about that person. Nobody is deleted, only switched off. Decision
/// 063.
class PeopleScreen extends ConsumerWidget {
  const PeopleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final team = ref.watch(teamProvider);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        _Header(onAdd: () => _add(context, ref)),
        const SizedBox(height: AppSpacing.xl),
        const RoleGuide(),
        const SizedBox(height: AppSpacing.xl),
        switch (team) {
          AsyncData(:final value) => _Groups(people: value),
          AsyncError(:final error) => ErrorPanel.from(
            error,
            networkMessage: l10n.errNetwork,
            serverMessage: l10n.errServer,
            retryLabel: l10n.actionRetry,
            onRetry: () => ref.invalidate(teamProvider),
          ),
          _ => const Padding(
            padding: EdgeInsets.all(AppSpacing.xxl),
            child: Center(child: CircularProgressIndicator()),
          ),
        },
      ],
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final form = await showDialog<TeamMemberForm>(context: context, builder: (_) => const MemberDialog());
    if (form == null) return;

    final refusal = await ref.read(peopleActionsProvider.notifier).add(form);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          refusal == null
              ? l10n.personAdded(form.name)
              : errorMessageFor(refusal, network: l10n.errNetwork, server: l10n.errServer),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;

    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.peopleTitle, style: text.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(l10n.peopleIntro, style: text.bodySmall),
      ],
    );
    final button = FilledButton.icon(
      onPressed: onAdd,
      icon: const Icon(Icons.person_add_alt_outlined),
      label: Text(l10n.actionAddPerson),
    );

    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth < AppSizes.formMaxWidth
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                const SizedBox(height: AppSpacing.md),
                button,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: title),
                const SizedBox(width: AppSpacing.lg),
                button,
              ],
            ),
    );
  }
}

/// Everyone, grouped the way the owner thinks about them: the office login,
/// the admins, the staff, and anyone switched off, last.
class _Groups extends ConsumerWidget {
  const _Groups({required this.people});
  final List<TeamMember> people;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final active = people.where((p) => p.isActive);

    final groups = [
      (l10n.peopleSectionOffice, active.where((p) => p.isOwner).toList()),
      (l10n.peopleSectionAdmins, active.where((p) => p.isAdmin).toList()),
      (l10n.peopleSectionStaff, active.where((p) => !p.isOwner && !p.isAdmin).toList()),
      (l10n.peopleSectionOff, people.where((p) => !p.isActive).toList()),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (title, members) in groups)
          if (members.isNotEmpty) ...[
            _GroupTitle(title: title, count: members.length),
            const SizedBox(height: AppSpacing.md),
            _CardGrid(
              children: [
                for (final member in members)
                  MemberCard(member: member, onAction: (action) => _act(context, ref, member, action)),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
      ],
    );
  }

  Future<void> _act(BuildContext context, WidgetRef ref, TeamMember member, MemberAction action) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final actions = ref.read(peopleActionsProvider.notifier);

    void say(Object? refusal, String done) => messenger.showSnackBar(
      SnackBar(
        content: Text(
          refusal == null ? done : errorMessageFor(refusal, network: l10n.errNetwork, server: l10n.errServer),
        ),
      ),
    );

    switch (action) {
      case MemberAction.edit:
        final form = await showDialog<TeamMemberForm>(
          context: context,
          builder: (_) => MemberDialog(existing: member),
        );
        if (form == null) return;
        say(await actions.change(member.id, form.toChangeRequest()), l10n.personSaved);
      case MemberAction.resetPassword:
        final temporary = await showDialog<String>(
          context: context,
          builder: (_) => ResetPasswordDialog(name: member.name),
        );
        if (temporary == null) return;
        say(await actions.resetPassword(member.id, temporary), l10n.passwordReset);
      case MemberAction.switchOff:
        if (!await confirmSwitchOff(context, member.name)) return;
        say(await actions.change(member.id, {'isActive': false}), l10n.personSwitchedOff(member.name));
      case MemberAction.switchOn:
        say(await actions.change(member.id, {'isActive': true}), l10n.personSwitchedOn(member.name));
    }
  }
}

class _GroupTitle extends StatelessWidget {
  const _GroupTitle({required this.title, required this.count});
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(width: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
          decoration: BoxDecoration(
            color: colors.surfaceSunken,
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
          child: Text('$count', style: AppText.amount(context, size: 12, weight: FontWeight.w600)),
        ),
      ],
    );
  }
}

/// One column on a narrow screen, two side by side on a wide one, each row
/// as tall as its taller card so the buttons line up.
class _CardGrid extends StatelessWidget {
  const _CardGrid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < AppSizes.twoColumnBreakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.md),
                children[i],
              ],
            ],
          );
        }
        return Column(
          children: [
            for (var i = 0; i < children.length; i += 2) ...[
              if (i > 0) const SizedBox(height: AppSpacing.md),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: children[i]),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: i + 1 < children.length ? children[i + 1] : const SizedBox()),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
