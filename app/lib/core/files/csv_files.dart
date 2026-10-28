import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'csv_files.g.dart';

/// A CSV file the person picked, as text.
class PickedCsv {
  const PickedCsv({required this.name, required this.text});
  final String name;
  final String text;
}

@Riverpod(keepAlive: true)
CsvFiles csvFiles(Ref ref) => const CsvFiles();

/// Picking a CSV file to import and saving one to the computer. Decision 069.
///
/// Behind a provider so widget tests can replace it: a test cannot open the
/// browser's file dialog.
class CsvFiles {
  const CsvFiles();

  /// Null when the person closed the dialog without choosing.
  Future<PickedCsv?> pick() async {
    final file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: const ['csv']);
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    return PickedCsv(name: file.name, text: utf8.decode(bytes, allowMalformed: true));
  }

  /// On the web this downloads the file; elsewhere it asks where to save it.
  Future<void> save({required String filename, required String csv}) async {
    await FilePicker.saveFile(fileName: filename, bytes: Uint8List.fromList(utf8.encode(csv)), mimeType: 'text/csv');
  }
}
