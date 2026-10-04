import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/auth_controller.dart';

/// Setting a new password.
///
/// Reached two ways: the owner is forced here on first sign-in because the
/// bootstrap password must not stay, and anyone can reach it from Settings to
/// change their own. The [forced] flag only changes the wording and hides the
/// way out, since a forced change has nowhere to go back to.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key, this.forced = false});

  final bool forced;

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();

  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String _messageFor(ApiException e, AppLocalizations l10n) {
    // The server names the field for a wrong current password or a reused one,
    // so its own message is the most useful thing to show.
    return switch (e.code) {
      'INVALID_CREDENTIALS' => e.message,
      'VALIDATION_FAILED' => e.message,
      'RATE_LIMITED' => l10n.errTooManyAttempts,
      'NETWORK' || 'UNKNOWN' => l10n.errNetwork,
      _ => l10n.errServer,
    };
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(authControllerProvider.notifier);

    setState(() => _submitting = true);
    final error = await controller.changePassword(
      currentPassword: _current.text,
      newPassword: _next.text,
    );
    if (!mounted) return;

    if (error == null) {
      // The held user now has mustChangePassword false, so the router moves on
      // from here on its own. A note confirms it happened.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.changePasswordDone)),
      );
      return;
    }

    setState(() {
      _submitting = false;
      _errorMessage = _messageFor(ApiException.from(error), l10n);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.appName, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    widget.forced ? l10n.changePasswordForcedHeading : l10n.changePasswordHeading,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    widget.forced
                        ? l10n.changePasswordForcedSubheading
                        : l10n.changePasswordSubheading,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textMuted),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  TextFormField(
                    controller: _current,
                    decoration: InputDecoration(labelText: l10n.fieldCurrentPassword),
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                    enabled: !_submitting,
                    validator: (value) =>
                        (value == null || value.isEmpty) ? l10n.changePasswordCurrentRequired : null,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  TextFormField(
                    controller: _next,
                    decoration: InputDecoration(
                      labelText: l10n.fieldNewPassword,
                      helperText: l10n.changePasswordRule,
                    ),
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                    enabled: !_submitting,
                    validator: (value) {
                      if (value == null || value.length < 10) return l10n.changePasswordTooShort;
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  TextFormField(
                    controller: _confirm,
                    decoration: InputDecoration(labelText: l10n.fieldConfirmPassword),
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    enabled: !_submitting,
                    onFieldSubmitted: (_) => _submit(),
                    validator: (value) =>
                        value != _next.text ? l10n.changePasswordMismatch : null,
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _ErrorBanner(message: _errorMessage!),
                  ],

                  const SizedBox(height: AppSpacing.xl),
                  FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(l10n.changePasswordSaving),
                            ],
                          )
                        : Text(l10n.actionSetPassword),
                  ),

                  // A forced change has nothing to go back to. An optional one
                  // can sign out instead.
                  if (!widget.forced) ...[
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: _submitting ? null : () => Navigator.of(context).maybePop(),
                      child: Text(l10n.actionCancel),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.negativeSoft,
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 18, color: colors.negative),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.negative),
            ),
          ),
        ],
      ),
    );
  }
}
