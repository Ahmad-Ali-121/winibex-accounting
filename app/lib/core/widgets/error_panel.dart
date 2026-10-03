import 'package:flutter/material.dart';

import '../api/api_exception.dart';
import '../theme/app_theme.dart';

/// What went wrong, and whether it was us or the connection.
///
/// A server-sent error carries a message written for a person, so it is shown
/// as it stands. Everything else gets a general line, because a Dio stack
/// trace means nothing to Maryam.
class ErrorPanel extends StatelessWidget {
  const ErrorPanel({super.key, required this.message, this.onRetry, this.retryLabel});

  factory ErrorPanel.from(
    Object error, {
    required String networkMessage,
    required String serverMessage,
    VoidCallback? onRetry,
    String? retryLabel,
  }) {
    final failure = ApiException.from(error);
    return ErrorPanel(
      message: switch (failure) {
        final value when value.isNetwork => networkMessage,
        final value when value.status != null && value.status! >= 500 => serverMessage,
        _ => failure.message,
      },
      onRetry: onRetry,
      retryLabel: retryLabel,
    );
  }

  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: colors.negativeSoft,
                borderRadius: BorderRadius.circular(AppRadii.container),
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.negative),
              ),
            ),
            if (onRetry != null && retryLabel != null) ...[
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton(onPressed: onRetry, child: Text(retryLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
