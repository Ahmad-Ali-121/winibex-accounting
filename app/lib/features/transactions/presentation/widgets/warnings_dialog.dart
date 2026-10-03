import 'package:flutter/material.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// What the server wants confirmed before it saves.
///
/// Each warning already names the record it matched, which is the difference
/// between a warning that gets read and one that gets dismissed by reflex.
/// "Possible duplicate" means nothing. "Same amount as JV-0042 on 3 July,
/// Office rent" is something a person can check.
///
/// Returns true when the person chose to go ahead, which sends the same entry
/// back with these codes acknowledged. The acknowledgement is recorded against
/// the entry with who made it. Decision 013.
Future<bool> showWarningsDialog(BuildContext context, List<ApiWarning> warnings) async {
  final l10n = AppLocalizations.of(context);
  final colors = context.colors;

  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.warnTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.warnIntro, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSpacing.lg),
            for (final warning in warnings)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: colors.pendingSoft,
                    borderRadius: BorderRadius.circular(AppRadii.control),
                  ),
                  child: Text(
                    warning.message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.pending),
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.actionGoBack),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.actionSaveAnyway),
        ),
      ],
    ),
  );

  return result ?? false;
}
