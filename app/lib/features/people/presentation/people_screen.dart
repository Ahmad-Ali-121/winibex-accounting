import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/error_message.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_panel.dart';
import '../../../core/widgets/money_text.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/people_providers.dart';
import '../domain/team_member.dart';

/// People and what each may do. The owner's screen: the router shows it only
/// to the owner, and the server refuses everyone else anyway.
///
/// Nobody is deleted here. Someone who leaves is switched off, so every entry
/// they made still names them. Decision 062.
class PeopleScreen extends ConsumerWidget {
  const PeopleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final team = ref.watch(teamProvider);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(l10n.peopleTitle, style: Theme.of(context).textTheme.headlineSmall),
            ),
            FilledButton.icon(
              onPressed: () => _add(context, ref),
              icon: const Icon(Icons.person_add_alt_outlined),
              label: Text(l10n.actionAddPerson),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        const _RolesExplained(),
        const SizedBox(height: AppSpacing.lg),
        switch (team) {
          AsyncData(:final value) => Column(
              children: [for (final member in value) _MemberCard(member: member)],
            ),
          AsyncError(:final error) => ErrorPanel.from(
              error,
              networkMessage: l10n.errNetwork,
              serverMessage: l10n.errServer,
              retryLabel: l10n.actionRetry,
              onRetry: () => ref.invalidate(teamProvider),
            ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ],
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final form = await showDialog<TeamMemberForm>(
      context: context,
      builder: (_) => const MemberDialog(),
    );
    if (form == null) return;

    final refusal = await ref.read(peopleActionsProvider.notifier).add(form);
    messenger.showSnackBar(SnackBar(
      content: Text(refusal == null
          ? l10n.personAdded
          : errorMessageFor(refusal, network: l10n.errNetwork, server: l10n.errServer)),
    ));
  }
}

/// The four things the owner needs to know before giving anyone a login.
class _RolesExplained extends StatelessWidget {
  const _RolesExplained();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final body = Theme.of(context).textTheme.bodySmall;
    final label = Theme.of(context).textTheme.labelLarge;

    Widget item(String title, String text) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text.rich(TextSpan(children: [
            TextSpan(text: '$title  ', style: label),
            TextSpan(text: text, style: body),
          ])),
        );

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.rule),
        borderRadius: BorderRadius.circular(AppRadii.container),
      ),
      child: ExpansionTile(
        title: Text(l10n.roleHelpTitle, style: label),
        childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        shape: const Border(),
        collapsedShape: const Border(),
        children: [
          item(l10n.roleOwner, l10n.roleOwnerHelp),
          item(l10n.roleAdmin, l10n.roleAdminHelp),
          item(l10n.roleStaff, l10n.roleStaffHelp),
          item(l10n.fieldSharesOfficeLogin, l10n.officeLoginHelp),
        ],
      ),
    );
  }
}

class _MemberCard extends ConsumerWidget {
  const _MemberCard({required this.member});
  final TeamMember member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final small = Theme.of(context).textTheme.bodySmall;

    final roleLabel = switch (member.role) {
      'owner' => l10n.roleOwner,
      'admin' => l10n.roleAdmin,
      _ => l10n.roleStaff,
    };

    final notes = <Widget>[
      if (member.isAdmin)
        member.approvalLimit == null
            ? Text(l10n.peopleNoLimit, style: small)
            : Row(mainAxisSize: MainAxisSize.min, children: [
                Text('${l10n.peopleApprovesUpTo} ', style: small),
                MoneyText(member.approvalLimit!, size: 12.5, weight: FontWeight.w400, muted: true),
              ]),
      if (member.isAdmin && member.autoApproveOwn) Text(l10n.peoplePostsOwn, style: small),
      if (member.sharesOwnerLogin) Text(l10n.peopleSharesLogin, style: small),
      if (member.mustChangePassword) Text(l10n.peopleMustChange, style: small),
      if (!member.isActive)
        Text(l10n.peopleSwitchedOff, style: small?.copyWith(color: colors.negative)),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.rule),
        borderRadius: BorderRadius.circular(AppRadii.container),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  member.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: member.isActive ? colors.text : colors.textMuted,
                      ),
                ),
              ),
              Text(roleLabel, style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(member.email, style: small),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(spacing: AppSpacing.lg, runSpacing: AppSpacing.xs, children: notes),
          ],
          // The office login always has every permission and changes its own
          // password, so it has nothing to change here.
          if (!member.isOwner) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                TextButton(onPressed: () => _edit(context, ref), child: Text(l10n.actionEdit)),
                TextButton(onPressed: () => _reset(context, ref), child: Text(l10n.actionResetPassword)),
                TextButton(
                  onPressed: () => _toggleActive(context, ref),
                  child: Text(member.isActive ? l10n.actionSwitchOff : l10n.actionSwitchOn),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _say(ScaffoldMessengerState messenger, AppLocalizations l10n, Object? refusal, String done) {
    messenger.showSnackBar(SnackBar(
      content: Text(refusal == null
          ? done
          : errorMessageFor(refusal, network: l10n.errNetwork, server: l10n.errServer)),
    ));
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final form = await showDialog<TeamMemberForm>(
      context: context,
      builder: (_) => MemberDialog(existing: member),
    );
    if (form == null) return;
    final refusal = await ref.read(peopleActionsProvider.notifier).change(member.id, form.toChangeRequest());
    _say(messenger, l10n, refusal, l10n.personSaved);
  }

  Future<void> _reset(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final temporary = await showDialog<String>(
      context: context,
      builder: (_) => _ResetDialog(name: member.name),
    );
    if (temporary == null) return;
    final refusal = await ref.read(peopleActionsProvider.notifier).resetPassword(member.id, temporary);
    _say(messenger, l10n, refusal, l10n.passwordReset);
  }

  Future<void> _toggleActive(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final refusal = await ref
        .read(peopleActionsProvider.notifier)
        .change(member.id, {'isActive': !member.isActive});
    _say(messenger, l10n, refusal, l10n.personSaved);
  }
}

/// Adding someone, or changing what they may do. Returns the form, or null if
/// cancelled. Email and the temporary password are asked only when adding.
class MemberDialog extends StatefulWidget {
  const MemberDialog({super.key, this.existing});
  final TeamMember? existing;

  @override
  State<MemberDialog> createState() => _MemberDialogState();
}

class _MemberDialogState extends State<MemberDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  final _email = TextEditingController();
  final _password = TextEditingController();
  late final _limit = TextEditingController(
    text: widget.existing?.approvalLimit == null
        ? ''
        : (widget.existing!.approvalLimit!.minorUnits ~/ 100).toString(),
  );
  late String _role = widget.existing?.role == 'admin' ? 'admin' : 'staff';
  late bool _postsOwn = widget.existing?.autoApproveOwn ?? false;
  late bool _sharesLogin = widget.existing?.sharesOwnerLogin ?? false;

  bool get _adding => widget.existing == null;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _limit.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final rupees = int.tryParse(_limit.text.replaceAll(',', '').trim());
    Navigator.of(context).pop(TeamMemberForm(
      name: _name.text.trim(),
      role: _role,
      email: _adding ? _email.text.trim() : null,
      temporaryPassword: _adding ? _password.text : null,
      approvalLimit: _role == 'admin' && rupees != null && rupees > 0 ? Money.pkr(rupees * 100) : null,
      autoApproveOwn: _role == 'admin' && _postsOwn,
      sharesOwnerLogin: _sharesLogin,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final small = Theme.of(context).textTheme.bodySmall;

    return AlertDialog(
      title: Text(_adding ? l10n.addPersonTitle : l10n.editPersonTitle),
      content: SizedBox(
        width: AppSizes.dialogWidth,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: InputDecoration(labelText: l10n.fieldFullName),
                  validator: (v) => (v == null || v.trim().isEmpty) ? l10n.errNameRequired : null,
                ),
                if (_adding) ...[
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(labelText: l10n.fieldEmail),
                    validator: (v) => (v == null || !v.contains('@')) ? l10n.errEmailInvalid : null,
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                Text(l10n.fieldRole, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(value: 'staff', label: Text(l10n.roleStaff)),
                    ButtonSegment(value: 'admin', label: Text(l10n.roleAdmin)),
                  ],
                  selected: {_role},
                  onSelectionChanged: (value) => setState(() => _role = value.first),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(_role == 'admin' ? l10n.roleAdminHelp : l10n.roleStaffHelp, style: small),
                if (_role == 'admin') ...[
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _limit,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,]'))],
                    decoration: InputDecoration(
                      labelText: l10n.fieldApprovalLimit,
                      helperText: l10n.hintApprovalLimit,
                      helperMaxLines: 3,
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _postsOwn,
                    onChanged: (value) => setState(() => _postsOwn = value),
                    title: Text(l10n.fieldPostsOwn),
                    subtitle: Text(l10n.hintPostsOwn),
                  ),
                ],
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _sharesLogin,
                  onChanged: (value) => setState(() => _sharesLogin = value),
                  title: Text(l10n.fieldSharesOfficeLogin),
                  subtitle: Text(l10n.hintSharesOfficeLogin),
                ),
                if (_adding) ...[
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _password,
                    decoration: InputDecoration(
                      labelText: l10n.fieldTemporaryPassword,
                      helperText: l10n.hintTemporaryPassword,
                      helperMaxLines: 3,
                    ),
                    validator: (v) => (v == null || v.length < 10) ? l10n.changePasswordTooShort : null,
                  ),
                ],
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

class _ResetDialog extends StatefulWidget {
  const _ResetDialog({required this.name});
  final String name;

  @override
  State<_ResetDialog> createState() => _ResetDialogState();
}

class _ResetDialogState extends State<_ResetDialog> {
  final _password = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  void _save() {
    if (_password.text.length < 10) {
      setState(() => _error = AppLocalizations.of(context).changePasswordTooShort);
      return;
    }
    Navigator.of(context).pop(_password.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text('${l10n.actionResetPassword}: ${widget.name}'),
      content: SizedBox(
        width: AppSizes.dialogWidth,
        child: TextField(
          controller: _password,
          autofocus: true,
          onSubmitted: (_) => _save(),
          decoration: InputDecoration(
            labelText: l10n.fieldTemporaryPassword,
            helperText: l10n.hintTemporaryPassword,
            helperMaxLines: 3,
            errorText: _error,
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.actionCancel)),
        FilledButton(onPressed: _save, child: Text(l10n.actionResetPassword)),
      ],
    );
  }
}
