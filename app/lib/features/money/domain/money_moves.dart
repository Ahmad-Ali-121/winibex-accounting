import '../../../core/money/money.dart';

/// Someone the company owes, because they paid a company cost themselves.
class PersonOwed {
  const PersonOwed({required this.userId, required this.name, required this.owed});

  factory PersonOwed.fromJson(Map<String, dynamic> json) => PersonOwed(
        userId: json['userId'] as int,
        name: json['name'] as String,
        owed: Money.fromJson(json['owed'] as Map<String, dynamic>),
      );

  final int userId;
  final String name;
  final Money owed;
}

/// One cost a person paid, with what is still to be paid back on it.
class OwedCost {
  const OwedCost({
    required this.transactionId,
    required this.date,
    required this.description,
    required this.remaining,
    this.journalNumber,
  });

  factory OwedCost.fromJson(Map<String, dynamic> json) => OwedCost(
        transactionId: json['transactionId'] as int,
        journalNumber: json['journalNumber'] as String?,
        date: json['date'] as String,
        description: json['description'] as String,
        remaining: Money.fromJson(json['remaining'] as Map<String, dynamic>),
      );

  final int transactionId;
  final String? journalNumber;
  final String date;
  final String description;
  final Money remaining;
}

/// A ledger account an opening balance can be given for.
class OpeningAccount {
  const OpeningAccount({required this.code, required this.name, required this.type});

  factory OpeningAccount.fromJson(Map<String, dynamic> json) => OpeningAccount(
        code: json['code'] as String,
        name: json['name'] as String,
        type: json['type'] as String,
      );

  final String code;
  final String name;

  /// asset, liability or equity.
  final String type;
}

class OpeningLine {
  const OpeningLine({required this.code, required this.name, required this.debit, required this.credit});

  factory OpeningLine.fromJson(Map<String, dynamic> json) => OpeningLine(
        code: json['code'] as String,
        name: json['name'] as String,
        debit: Money.fromJson(json['debit'] as Map<String, dynamic>),
        credit: Money.fromJson(json['credit'] as Map<String, dynamic>),
      );

  final String code;
  final String name;
  final Money debit;
  final Money credit;
}

class OpeningEntryView {
  const OpeningEntryView({
    required this.transactionId,
    required this.status,
    required this.lines,
    this.journalNumber,
  });

  factory OpeningEntryView.fromJson(Map<String, dynamic> json) => OpeningEntryView(
        transactionId: json['transactionId'] as int,
        journalNumber: json['journalNumber'] as String?,
        status: json['status'] as String,
        lines: (json['lines'] as List<dynamic>)
            .map((item) => OpeningLine.fromJson(item as Map<String, dynamic>))
            .toList(growable: false),
      );

  final int transactionId;
  final String? journalNumber;
  final String status;
  final List<OpeningLine> lines;
}

/// Everything the opening entry screen needs. Decision 065.
class OpeningInfo {
  const OpeningInfo({
    required this.booksLiveFrom,
    required this.balancesAt,
    required this.accounts,
    this.entry,
  });

  factory OpeningInfo.fromJson(Map<String, dynamic> json) => OpeningInfo(
        booksLiveFrom: json['booksLiveFrom'] as String,
        balancesAt: json['balancesAt'] as String,
        entry: json['entry'] == null ? null : OpeningEntryView.fromJson(json['entry'] as Map<String, dynamic>),
        accounts: (json['accounts'] as List<dynamic>)
            .map((item) => OpeningAccount.fromJson(item as Map<String, dynamic>))
            .toList(growable: false),
      );

  final String booksLiveFrom;
  final String balancesAt;
  final OpeningEntryView? entry;
  final List<OpeningAccount> accounts;
}
