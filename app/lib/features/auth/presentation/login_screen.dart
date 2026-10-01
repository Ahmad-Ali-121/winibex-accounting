import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();

  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  String _messageFor(ApiException e, AppLocalizations l10n) {
    return switch (e.code) {
      'INVALID_CREDENTIALS' => l10n.errSignIn,
      'ACCOUNT_INACTIVE' => l10n.errAccountInactive,
      'RATE_LIMITED' => l10n.errTooManyAttempts,
      'NETWORK' || 'UNKNOWN' => l10n.errNetwork,
      _ => l10n.errServer,
    };
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) return;

    // Read the notifier before awaiting. Reaching for ref after the await is
    // unsafe, because on a failed login the widget rebuilds and this ref may
    // already be pointing at a deactivated element.
    final controller = ref.read(authControllerProvider.notifier);

    setState(() => _submitting = true);
    final error = await controller.login(
      email: _email.text.trim(),
      password: _password.text,
    );
    if (!mounted) return;

    setState(() {
      _submitting = false;
      _errorMessage = error == null ? null : _messageFor(ApiException.from(error), l10n);
    });
    // On success the router redirect takes over; nothing more to do here.
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
                  Text(l10n.loginHeading, style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.loginSubheading,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  TextFormField(
                    controller: _email,
                    decoration: InputDecoration(labelText: l10n.fieldEmail),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.username],
                    enabled: !_submitting,
                    onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                    validator: (value) =>
                    (value == null || value.trim().isEmpty) ? l10n.loginEmailRequired : null,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  TextFormField(
                    controller: _password,
                    focusNode: _passwordFocus,
                    decoration: InputDecoration(labelText: l10n.fieldPassword),
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    enabled: !_submitting,
                    onFieldSubmitted: (_) => _submit(),
                    validator: (value) =>
                    (value == null || value.isEmpty) ? l10n.loginPasswordRequired : null,
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
                        Text(l10n.loginSigningIn),
                      ],
                    )
                        : Text(l10n.actionSignIn),
                  ),
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
