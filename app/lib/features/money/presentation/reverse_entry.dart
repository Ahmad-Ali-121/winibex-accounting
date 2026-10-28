import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/error_message.dart';
import '../../../core/api/idempotency_key.dart';
import '../../../core/widgets/reason_dialog.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/money_providers.dart';
import '../data/money_repository.dart';

/// Reversing a posted entry: the correction for a mistake, since a posted
/// entry is never edited. Asks why, then posts the equal and opposite entry.
/// A transfer is reversed whole, both legs. Decisions 012 and 065.
///
/// Returns true when it was reversed.
Future<bool> reverseEntry(BuildContext context, WidgetRef ref, {required int transactionId}) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);

  final reason = await askForReason(
    context,
    title: l10n.reverseTitle,
    label: l10n.fieldReverseReason,
    hint: l10n.hintReverseReason,
    confirmLabel: l10n.actionReverse,
  );
  if (reason == null) return false;

  try {
    final journalNumber = await ref.read(moneyRepositoryProvider).reverse(
          transactionId: transactionId,
          reason: reason,
          key: newIdempotencyKey(),
        );
    refreshAfterMoneyMoved(ref);
    messenger.showSnackBar(SnackBar(content: Text(l10n.reverseDone(journalNumber))));
    return true;
  } catch (error) {
    messenger.showSnackBar(SnackBar(
      content: Text(errorMessageFor(error, network: l10n.errNetwork, server: l10n.errServer)),
    ));
    return false;
  }
}
