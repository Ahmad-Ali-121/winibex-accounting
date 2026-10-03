import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/entry_draft_controller.dart';
import '../../domain/entry_draft.dart';

/// Attaching the evidence.
///
/// A photo or a PDF, which is what the API accepts and what a Pakistani
/// company's evidence actually arrives as: a phone photo of a till slip, or a
/// bank advice emailed as a PDF.
///
/// The file is held in the draft and sent after the entry is created, because
/// there is nothing to attach it to until then.
class ReceiptField extends ConsumerWidget {
  const ReceiptField({super.key});

  static const _extensions = ['jpg', 'jpeg', 'png', 'webp', 'heic', 'pdf'];

  static const _mimeFor = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
    'heic': 'image/heic',
    'pdf': 'application/pdf',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final receipt = ref.watch(entryDraftControllerProvider).receipt;

    if (receipt != null) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surfaceSunken,
          borderRadius: BorderRadius.circular(AppRadii.container),
        ),
        child: Row(
          children: [
            Icon(
              receipt.isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
              size: 20,
              color: colors.textMuted,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    receipt.filename,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    l10n.receiptSize(_kilobytes(receipt.sizeBytes)),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => ref.read(entryDraftControllerProvider.notifier).clearReceipt(),
              child: Text(l10n.actionRemove),
            ),
          ],
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: () => _choose(ref),
      icon: const Icon(Icons.attach_file, size: 18),
      label: Text(l10n.actionAttachReceipt),
    );
  }

  Future<void> _choose(WidgetRef ref) async {
    // file_picker 13: pickFile returns one PlatformFile, and the bytes are
    // read on demand rather than loaded with the pick. There is no `size` or
    // `bytes` property any more.
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: _extensions,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();

    final extension = (file.extension ?? '').toLowerCase();
    ref.read(entryDraftControllerProvider.notifier).setReceipt(
      DraftAttachment(
        bytes: bytes,
        filename: file.name,
        mime: _mimeFor[extension] ?? 'application/octet-stream',
      ),
    );
  }
  /// Rounded for display only, and nowhere near money.
  int _kilobytes(int bytes) => (bytes + 1023) ~/ 1024;
}
