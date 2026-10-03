import '../../../core/money/money.dart';

/// The journal entry an entry would produce, worked out by the server and
/// shown before anything is saved.
///
/// The app never builds this. AGENTS.md: nothing financial is calculated on
/// this side. A preview built here would be a second opinion, and the lines
/// actually written would be the ones nobody checked.
class JournalPreview {
  const JournalPreview({required this.lines, required this.totals});

  factory JournalPreview.fromJson(Map<String, dynamic> json) => JournalPreview(
        lines: (json['lines'] as List<dynamic>)
            .map((item) => JournalLine.fromJson(item as Map<String, dynamic>))
            .toList(growable: false),
        totals: PreviewTotals.fromJson(json['totals'] as Map<String, dynamic>),
      );

  final List<JournalLine> lines;
  final PreviewTotals totals;

  Money get debits => Money.pkr(lines.fold(0, (sum, line) => sum + line.debit.minorUnits));
  Money get credits => Money.pkr(lines.fold(0, (sum, line) => sum + line.credit.minorUnits));

  /// Shown on the review step. The server already refuses an entry that does
  /// not balance, so this is a reassurance rather than a check.
  bool get balances => debits == credits;
}

class JournalLine {
  const JournalLine({
    required this.coaId,
    required this.code,
    required this.name,
    required this.debit,
    required this.credit,
    this.memo,
  });

  factory JournalLine.fromJson(Map<String, dynamic> json) => JournalLine(
        coaId: json['coaId'] as int,
        code: json['code'] as String? ?? '',
        name: json['name'] as String? ?? '',
        debit: Money.pkr(json['debit'] as int? ?? 0),
        credit: Money.pkr(json['credit'] as int? ?? 0),
        memo: json['memo'] as String?,
      );

  final int coaId;

  /// 6400, and so on. On screen beside the name, because the code is what the
  /// accountant recognises.
  final String code;
  final String name;
  final Money debit;
  final Money credit;
  final String? memo;

  bool get isDebit => debit.minorUnits > 0;
}

class PreviewTotals {
  const PreviewTotals({
    required this.gross,
    required this.taxTotal,
    required this.chargesTotal,
    required this.withheldTotal,
    required this.amount,
  });

  factory PreviewTotals.fromJson(Map<String, dynamic> json) => PreviewTotals(
        gross: Money.pkr(json['gross'] as int? ?? 0),
        taxTotal: Money.pkr(json['taxTotal'] as int? ?? 0),
        chargesTotal: Money.pkr(json['chargesTotal'] as int? ?? 0),
        withheldTotal: Money.pkr(json['withheldTotal'] as int? ?? 0),
        amount: Money.pkr(json['amount'] as int? ?? 0),
      );

  final Money gross;
  final Money taxTotal;
  final Money chargesTotal;

  /// Tax Winibex held back from the payee and owes FBR. Reduces the payment
  /// rather than adding to it. Decision 052.
  final Money withheldTotal;

  /// What actually moves on the account.
  final Money amount;
}
