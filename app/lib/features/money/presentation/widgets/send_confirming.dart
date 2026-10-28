import 'package:flutter/material.dart';

import '../../../../core/api/api_exception.dart';
import '../../../transactions/presentation/widgets/warnings_dialog.dart';

/// Sends a money-moving request. When the server asks for warnings to be
/// confirmed first, shows them, and on "Save anyway" sends the same request
/// again with them acknowledged, under the same idempotency key.
///
/// Returns the result, or null if the person went back. A refusal is thrown
/// as the ApiException, for the caller to show.
Future<T?> sendConfirming<T>(
  BuildContext context,
  Future<T> Function(List<String> acknowledged) send,
) async {
  var acknowledged = <String>[];
  while (true) {
    try {
      return await send(acknowledged);
    } on ApiException catch (error) {
      if (!error.isWarnings || !context.mounted) rethrow;
      final goAhead = await showWarningsDialog(context, error.warnings);
      if (!goAhead) return null;
      acknowledged = [...acknowledged, ...error.warnings.map((warning) => warning.code)];
    }
  }
}
