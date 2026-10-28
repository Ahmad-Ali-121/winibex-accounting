/// What the bulk import and export work on. Decision 069.
enum BulkKind {
  ledgerCodes('ledger-codes'),
  taxes('taxes');

  const BulkKind(this.path);

  /// The address segment on the server: /ledger-codes/import, /taxes/import.
  final String path;
}

/// A file the server made: a template or an export.
class BulkFile {
  const BulkFile({required this.filename, required this.csv});

  factory BulkFile.fromJson(Map<String, dynamic> json) =>
      BulkFile(filename: json['filename'] as String, csv: json['csv'] as String);

  final String filename;
  final String csv;
}

/// One row, or one tax made of several rows, and what the import does to it.
class ImportRow {
  const ImportRow({
    required this.rows,
    required this.code,
    required this.name,
    required this.action,
    required this.changes,
    this.reason,
  });

  factory ImportRow.fromJson(Map<String, dynamic> json) => ImportRow(
    rows: ((json['rows'] as List<dynamic>?) ?? [json['row']]).map((item) => item as int).toList(growable: false),
    code: json['code'] as String? ?? '',
    name: json['name'] as String? ?? '',
    action: json['action'] as String,
    changes: ((json['changes'] as List<dynamic>?) ?? const []).map((item) => item as String).toList(growable: false),
    reason: json['reason'] as String?,
  );

  /// The row numbers in the file, counting the headings as row 1.
  final List<int> rows;
  final String code;
  final String name;

  /// add, update, unchanged or skip. The server's word.
  final String action;
  final List<String> changes;

  /// Why a skipped row was skipped, in the server's words.
  final String? reason;
}

/// What a file would change, or did change once confirmed.
class ImportPlan {
  const ImportPlan({
    required this.applied,
    required this.added,
    required this.updated,
    required this.unchanged,
    required this.skipped,
    required this.rows,
  });

  factory ImportPlan.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>;
    return ImportPlan(
      applied: json['applied'] as bool? ?? false,
      added: summary['add'] as int,
      updated: summary['update'] as int,
      unchanged: summary['unchanged'] as int,
      skipped: summary['skip'] as int,
      rows: (json['rows'] as List<dynamic>)
          .map((item) => ImportRow.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  final bool applied;
  final int added;
  final int updated;
  final int unchanged;
  final int skipped;
  final List<ImportRow> rows;

  /// How many rows confirming would save.
  int get toSave => added + updated;
}
