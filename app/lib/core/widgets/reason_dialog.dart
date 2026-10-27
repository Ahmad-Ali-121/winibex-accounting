import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';

/// Asks for a short reason, such as why an entry is rejected or why a flag
/// needs nothing more. Returns the trimmed text, or null if cancelled.
///
/// One dialog for both, so they behave the same way:
/// - wide enough that the hint under the box reads in full (O4)
/// - a reason under [minLength] characters keeps the dialog open and says so,
///   rather than closing as if it had worked and sending nothing (O5). The
///   server refuses under three characters too
Future<String?> askForReason(
  BuildContext context, {
  required String title,
  required String label,
  required String hint,
  required String confirmLabel,
  int minLength = 3,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _ReasonDialog(
      title: title,
      label: label,
      hint: hint,
      confirmLabel: confirmLabel,
      minLength: minLength,
    ),
  );
}

class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog({
    required this.title,
    required this.label,
    required this.hint,
    required this.confirmLabel,
    required this.minLength,
  });

  final String title;
  final String label;
  final String hint;
  final String confirmLabel;
  final int minLength;

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final reason = _controller.text.trim();
    if (reason.length < widget.minLength) {
      setState(() => _error = AppLocalizations.of(context).errNoteTooShort);
      return;
    }
    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: AppSizes.dialogWidth,
        child: TextField(
          controller: _controller,
          autofocus: true,
          maxLength: 255,
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          onSubmitted: (_) => _confirm(),
          decoration: InputDecoration(
            labelText: widget.label,
            helperText: widget.hint,
            helperMaxLines: 3,
            errorText: _error,
            errorMaxLines: 3,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(onPressed: _confirm, child: Text(widget.confirmLabel)),
      ],
    );
  }
}
