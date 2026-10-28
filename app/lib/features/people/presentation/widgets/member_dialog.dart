import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/money/money.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/team_member.dart';
import 'role_guide.dart';

/// A temporary password that is easy to read out and type: no 0, O, 1, l or I,
/// in three groups of four. Random.secure, never Random().
String generateTemporaryPassword() {
  const letters = 'ABCDEFGHJKMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
  final random = Random.secure();
  String group() => List.generate(4, (_) => letters[random.nextInt(letters.length)]).join();
  return '${group()}-${group()}-${group()}';
}

/// Shows whole rupees with thousands separators while typing: 50000 becomes
/// 50,000. Digits only, so a paste of "50,000.00" cannot slip in paisa.
class RupeesInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue();
    final trimmed = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final buffer = StringBuffer();
    for (var i = 0; i < trimmed.length; i++) {
      if (i > 0 && (trimmed.length - i) % 3 == 0) buffer.write(',');
      buffer.write(trimmed[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

String _groupedRupees(int rupees) =>
    RupeesInputFormatter().formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: '$rupees')).text;

/// Adding someone, or changing what they may do. Returns the form, or null if
/// cancelled. The email is fixed once added; the password is only set here
/// when adding, and later through Reset password.
class MemberDialog extends StatefulWidget {
  const MemberDialog({super.key, this.existing});
  final TeamMember? existing;

  @override
  State<MemberDialog> createState() => _MemberDialogState();
}

class _MemberDialogState extends State<MemberDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _email = TextEditingController(text: widget.existing?.email ?? '');
  final _password = TextEditingController();
  late final _limit = TextEditingController(
    text: widget.existing?.approvalLimit == null
        ? ''
        : _groupedRupees(widget.existing!.approvalLimit!.minorUnits ~/ 100),
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
    final rupees = int.tryParse(_limit.text.replaceAll(',', ''));
    Navigator.of(context).pop(
      TeamMemberForm(
        name: _name.text.trim(),
        role: _role,
        email: _adding ? _email.text.trim() : null,
        temporaryPassword: _adding ? _password.text : null,
        approvalLimit: _role == 'admin' && rupees != null && rupees > 0 ? Money.pkr(rupees * 100) : null,
        autoApproveOwn: _role == 'admin' && _postsOwn,
        sharesOwnerLogin: _sharesLogin,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final small = Theme.of(context).textTheme.bodySmall;

    return AlertDialog(
      title: Text(_adding ? l10n.addPersonTitle : l10n.editPersonTitle),
      content: SizedBox(
        width: AppSizes.dialogWideWidth,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Section(l10n.dialogSectionWho),
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: l10n.fieldFullName,
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? l10n.errNameRequired : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _email,
                  enabled: _adding,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: l10n.fieldEmail,
                    prefixIcon: const Icon(Icons.mail_outline),
                    helperText: _adding ? l10n.hintEmailIsLogin : l10n.hintEmailFixed,
                  ),
                  validator: (v) => !_adding || (v != null && RegExp(r'^\S+@\S+\.\S+$').hasMatch(v.trim()))
                      ? null
                      : l10n.errEmailInvalid,
                ),
                _Section(l10n.fieldRole),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _RoleChoice(
                        role: 'staff',
                        title: l10n.roleStaff,
                        text: l10n.roleStaffShort,
                        selected: _role == 'staff',
                        onTap: () => setState(() => _role = 'staff'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _RoleChoice(
                        role: 'admin',
                        title: l10n.roleAdmin,
                        text: l10n.roleAdminShort,
                        selected: _role == 'admin',
                        onTap: () => setState(() => _role = 'admin'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(_role == 'admin' ? l10n.roleAdminHelp : l10n.roleStaffHelp, style: small),
                if (_role == 'admin') ...[
                  _Section(l10n.dialogSectionApprovals),
                  TextFormField(
                    controller: _limit,
                    keyboardType: TextInputType.number,
                    inputFormatters: [RupeesInputFormatter()],
                    decoration: InputDecoration(
                      labelText: l10n.fieldApprovalLimit,
                      prefixText: '${l10n.currencyCodePkr} ',
                      hintText: l10n.hintNoLimit,
                      helperText: l10n.hintApprovalLimit,
                      helperMaxLines: 3,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _SwitchRow(
                    icon: Icons.bolt_outlined,
                    title: l10n.fieldPostsOwn,
                    text: l10n.hintPostsOwn,
                    value: _postsOwn,
                    onChanged: (value) => setState(() => _postsOwn = value),
                  ),
                ],
                _Section(l10n.dialogSectionSignIn),
                _SwitchRow(
                  icon: Icons.key_outlined,
                  title: l10n.fieldSharesOfficeLogin,
                  text: l10n.hintSharesOfficeLogin,
                  value: _sharesLogin,
                  onChanged: (value) => setState(() => _sharesLogin = value),
                ),
                if (_adding) ...[
                  const SizedBox(height: AppSpacing.md),
                  TemporaryPasswordField(controller: _password),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.actionCancel)),
        FilledButton(onPressed: _save, child: Text(_adding ? l10n.actionAddPerson : l10n.actionSave)),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
    child: Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 0.6),
    ),
  );
}

/// One role as a card to pick, with its icon and what it means in one line.
class _RoleChoice extends StatelessWidget {
  const _RoleChoice({
    required this.role,
    required this.title,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String role;
  final String title;
  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? colors.accentSoft : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.container),
          side: BorderSide(color: selected ? colors.accent : colors.rule, width: selected ? 1.5 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.container),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
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
                Icon(
                  selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  size: AppSizes.iconMedium,
                  color: selected ? colors.accent : colors.ruleStrong,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.text,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String text;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // A Material for the same reason as the role guide: the switch row paints
    // its ink on the nearest Material.
    return Material(
      color: colors.surfaceSunken,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.container)),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        secondary: Icon(icon, color: value ? colors.accent : colors.textMuted),
        title: Text(title, style: Theme.of(context).textTheme.labelLarge),
        subtitle: Text(text, style: Theme.of(context).textTheme.bodySmall),
      ),
    );
  }
}

/// The temporary password, with Generate, Show and Copy, because the owner has
/// to read it out or send it to the person.
class TemporaryPasswordField extends StatefulWidget {
  const TemporaryPasswordField({
    super.key,
    required this.controller,
    this.autofocus = false,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final bool autofocus;
  final VoidCallback? onSubmitted;

  @override
  State<TemporaryPasswordField> createState() => _TemporaryPasswordFieldState();
}

class _TemporaryPasswordFieldState extends State<TemporaryPasswordField> {
  bool _hidden = true;

  void _generate() {
    setState(() {
      widget.controller.text = generateTemporaryPassword();
      _hidden = false;
    });
  }

  Future<void> _copy() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (widget.controller.text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: widget.controller.text));
    messenger.showSnackBar(SnackBar(content: Text(l10n.passwordCopied)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: widget.controller,
          autofocus: widget.autofocus,
          obscureText: _hidden,
          autocorrect: false,
          enableSuggestions: false,
          onFieldSubmitted: (_) => widget.onSubmitted?.call(),
          style: AppText.amount(context, size: 15),
          decoration: InputDecoration(
            labelText: l10n.fieldTemporaryPassword,
            prefixIcon: const Icon(Icons.lock_outline),
            helperText: l10n.hintTemporaryPassword,
            helperMaxLines: 3,
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: _hidden ? l10n.a11yShowPassword : l10n.a11yHidePassword,
                  icon: Icon(_hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _hidden = !_hidden),
                ),
                IconButton(tooltip: l10n.actionCopy, icon: const Icon(Icons.copy_outlined), onPressed: _copy),
              ],
            ),
          ),
          validator: (v) => (v == null || v.length < 10) ? l10n.changePasswordTooShort : null,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _generate,
            icon: const Icon(Icons.auto_awesome_outlined, size: AppSizes.iconSmall),
            label: Text(l10n.actionGeneratePassword),
          ),
        ),
      ],
    );
  }
}

/// Reset password: a new temporary one, which signs them out everywhere.
class ResetPasswordDialog extends StatefulWidget {
  const ResetPasswordDialog({super.key, required this.name});
  final String name;

  @override
  State<ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<ResetPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_password.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.resetPasswordTitle(widget.name)),
      content: SizedBox(
        width: AppSizes.dialogWidth,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.resetPasswordBody, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.lg),
              TemporaryPasswordField(controller: _password, autofocus: true, onSubmitted: _save),
            ],
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

/// Switching someone off is asked once, because it signs them out at once.
Future<bool> confirmSwitchOff(BuildContext context, String name) async {
  final l10n = AppLocalizations.of(context);
  final colors = context.colors;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.switchOffTitle(name)),
      content: SizedBox(
        width: AppSizes.dialogWidth,
        child: Text(l10n.switchOffBody, style: Theme.of(context).textTheme.bodyMedium),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.actionCancel)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: colors.negative),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.actionSwitchOff),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
