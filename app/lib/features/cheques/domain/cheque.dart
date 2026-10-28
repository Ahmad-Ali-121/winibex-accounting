import '../../../core/money/money.dart';

/// A cheque in the register. The register records what was written, to whom,
/// and whether it cleared; the money itself is an ordinary entry with method
/// cheque, linked here. Decision 053.
class Cheque {
  const Cheque({
    required this.id,
    required this.accountId,
    required this.accountName,
    required this.chequeNumber,
    required this.payee,
    required this.amount,
    required this.issueDate,
    required this.status,
    this.clearedOn,
    this.transactionId,
    this.journalNumber,
    this.note,
  });

  factory Cheque.fromJson(Map<String, dynamic> json) => Cheque(
        id: json['id'] as int,
        accountId: json['accountId'] as int,
        accountName: json['accountName'] as String? ?? '',
        chequeNumber: json['chequeNumber'] as String,
        payee: json['payee'] as String,
        amount: Money.fromJson(json['amount'] as Map<String, dynamic>),
        issueDate: _day(json['issueDate'] as String),
        status: json['status'] as String,
        clearedOn: json['clearedOn'] == null ? null : _day(json['clearedOn'] as String),
        transactionId: json['transactionId'] as int?,
        journalNumber: json['journalNumber'] as String?,
        note: json['note'] as String?,
      );

  static String _day(String value) => value.length < 10 ? value : value.substring(0, 10);

  final int id;
  final int accountId;
  final String accountName;
  final String chequeNumber;
  final String payee;
  final Money amount;
  final String issueDate;

  /// issued, presented, cleared, bounced or cancelled.
  final String status;
  final String? clearedOn;
  final int? transactionId;
  final String? journalNumber;
  final String? note;

  /// What a cheque may become next. The server holds the same rule and is
  /// the one that enforces it; this only decides which buttons to show.
  /// A cheque moves forward, never back.
  List<String> get nextSteps => switch (status) {
        'issued' => const ['presented', 'bounced', 'cancelled'],
        'presented' => const ['cleared', 'bounced'],
        'bounced' => const ['cancelled'],
        _ => const [],
      };
}

class ChequeRegister {
  const ChequeRegister({required this.cheques, required this.outstanding});

  factory ChequeRegister.fromJson(Map<String, dynamic> json) => ChequeRegister(
        cheques: (json['cheques'] as List<dynamic>)
            .map((item) => Cheque.fromJson(item as Map<String, dynamic>))
            .toList(growable: false),
        outstanding: Money.fromJson(json['outstanding'] as Map<String, dynamic>),
      );

  final List<Cheque> cheques;

  /// Written but not yet taken by the bank. The server's sum.
  final Money outstanding;
}

/// A posted payment a cheque can be linked to.
class PaymentOption {
  const PaymentOption({
    required this.id,
    required this.date,
    required this.description,
    required this.amount,
    this.journalNumber,
  });

  factory PaymentOption.fromJson(Map<String, dynamic> json) => PaymentOption(
        id: json['id'] as int,
        journalNumber: json['journalNumber'] as String?,
        date: json['date'] as String,
        description: json['description'] as String,
        amount: Money.fromJson(json['amount'] as Map<String, dynamic>),
      );

  final int id;
  final String? journalNumber;
  final String date;
  final String description;
  final Money amount;
}
