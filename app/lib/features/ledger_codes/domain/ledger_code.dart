/// One line of the chart of accounts, as the ledger codes screen shows it.
/// Decisions 068 and 069.
class LedgerCode {
  const LedgerCode({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.isHeader,
    required this.isSystem,
    required this.isActive,
    required this.onEntryForm,
    this.parentId,
    this.parentCode,
  });

  factory LedgerCode.fromJson(Map<String, dynamic> json) => LedgerCode(
    id: json['id'] as int,
    code: json['code'] as String,
    name: json['name'] as String,
    type: json['type'] as String,
    isHeader: json['isHeader'] as bool? ?? false,
    isSystem: json['isSystem'] as bool? ?? false,
    isActive: json['isActive'] as bool? ?? true,
    onEntryForm: json['onEntryForm'] as bool? ?? false,
    parentId: json['parentId'] as int?,
    parentCode: json['parentCode'] as String?,
  );

  final int id;
  final String code;
  final String name;

  /// asset, liability, equity, income or expense. Set by the first digit.
  final String type;

  /// A heading only groups the codes under it. Nothing posts to it.
  final bool isHeader;

  /// Built in: posting, transfers, tax or the opening entry depend on it, so
  /// its name, heading and switch stay as they are.
  final bool isSystem;
  final bool isActive;

  /// It has a category, so people can pick it on the entry form.
  final bool onEntryForm;

  /// The heading it sits under, if any.
  final int? parentId;
  final String? parentCode;

  /// The first digit: 1 assets up to 9 taxation.
  int get classDigit => int.tryParse(code.substring(0, 1)) ?? 0;

  /// The owner may change it or switch it off.
  bool get canChange => !isSystem;
}

/// What a code's first digit makes it. Null for anything else.
int? classOfCode(String code) {
  if (code.isEmpty) return null;
  final digit = int.tryParse(code.substring(0, 1));
  return digit == null || digit == 0 ? null : digit;
}

/// Income and expense codes can join the entry form; balance sheet codes
/// cannot, because nobody picks them as what money was for.
bool canJoinEntryForm(int? classDigit) => classDigit != null && classDigit >= 4;

/// How many headings a code sits under, for indenting the list.
int depthOf(LedgerCode code, Map<int, LedgerCode> byId) {
  var depth = 0;
  var parent = code.parentId == null ? null : byId[code.parentId];
  final seen = <int>{};
  while (parent != null && seen.add(parent.id)) {
    depth++;
    parent = parent.parentId == null ? null : byId[parent.parentId];
  }
  return depth;
}

/// The headings a code may sit under: on, in its class, before it.
List<LedgerCode> headingsFor(String code, List<LedgerCode> all, {int? exceptId}) {
  final digit = classOfCode(code);
  return all
      .where(
        (item) =>
            item.isHeader &&
            item.isActive &&
            item.id != exceptId &&
            item.classDigit == digit &&
            item.code.compareTo(code) < 0,
      )
      .toList(growable: false);
}
