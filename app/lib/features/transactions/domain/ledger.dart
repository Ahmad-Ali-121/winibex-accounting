import '../../../core/money/money.dart';

/// A row in the ledger. Enough to list and search, not the whole entry: the
/// journal lines are fetched only when someone opens one.
class TransactionSummary {
  const TransactionSummary({
    required this.id,
    required this.date,
    required this.direction,
    required this.amount,
    required this.description,
    required this.status,
    required this.entryType,
    required this.flagCount,
    required this.isReversed,
    required this.isReversal,
    this.journalNumber,
    this.accountName,
    this.categoryName,
    this.createdByName,
  });

  factory TransactionSummary.fromJson(Map<String, dynamic> json) => TransactionSummary(
        id: json['id'] as int,
        date: json['date'] as String,
        direction: json['direction'] as String,
        amount: Money.fromJson(json['amount'] as Map<String, dynamic>),
        description: json['description'] as String,
        status: json['status'] as String,
        entryType: json['entryType'] as String? ?? 'normal',
        flagCount: json['flagCount'] as int? ?? 0,
        isReversed: json['isReversed'] as bool? ?? false,
        isReversal: json['isReversal'] as bool? ?? false,
        journalNumber: json['journalNumber'] as String?,
        accountName: json['accountName'] as String?,
        categoryName: json['categoryName'] as String?,
        createdByName: json['createdByName'] as String?,
      );

  final int id;
  final String date;
  final String direction;
  final Money amount;
  final String description;
  final String status;
  final String entryType;

  /// Warnings confirmed and flags raised, for the small marker on the row.
  final int flagCount;

  /// Reversed entries stay in the ledger, struck through rather than removed.
  /// Decision 012: nothing is deleted, and both halves of a correction are
  /// visible.
  final bool isReversed;
  final bool isReversal;

  final String? journalNumber;
  final String? accountName;
  final String? categoryName;
  final String? createdByName;

  bool get isMoneyIn => direction == 'in';
  bool get isPosted => status == 'posted' || status == 'reversed';

  /// What the row shows in the balance column: money out reads as negative,
  /// because that is what it does to the account.
  Money get signedAmount =>
      isMoneyIn ? amount : Money(minorUnits: -amount.minorUnits, currency: amount.currency);
}

class LedgerPage {
  const LedgerPage({
    required this.transactions,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.hasMore,
  });

  factory LedgerPage.fromJson(Map<String, dynamic> json) => LedgerPage(
        transactions: (json['transactions'] as List<dynamic>)
            .map((item) => TransactionSummary.fromJson(item as Map<String, dynamic>))
            .toList(growable: false),
        page: json['page'] as int,
        pageSize: json['pageSize'] as int,
        total: json['total'] as int,
        hasMore: json['hasMore'] as bool? ?? false,
      );

  final List<TransactionSummary> transactions;
  final int page;
  final int pageSize;

  /// Everything matching, not just what was returned. The count is the server's
  /// so the app never says "50 results" when it only looked at 50.
  final int total;
  final bool hasMore;
}

/// What the ledger is currently filtered to. Held as one object so a change to
/// any part of it refetches once rather than four times.
class LedgerQuery {
  const LedgerQuery({
    this.search = '',
    this.accountId,
    this.status,
    this.direction,
    this.page = 1,
  });

  final String search;
  final int? accountId;
  final String? status;
  final String? direction;
  final int page;

  LedgerQuery copyWith({
    String? search,
    int? accountId,
    bool clearAccount = false,
    String? status,
    bool clearStatus = false,
    String? direction,
    bool clearDirection = false,
    int? page,
  }) {
    return LedgerQuery(
      search: search ?? this.search,
      accountId: clearAccount ? null : (accountId ?? this.accountId),
      status: clearStatus ? null : (status ?? this.status),
      direction: clearDirection ? null : (direction ?? this.direction),
      page: page ?? 1,
    );
  }

  Map<String, dynamic> toQueryParameters() => {
        if (search.trim().isNotEmpty) 'search': search.trim(),
        if (accountId != null) 'accountId': accountId,
        if (status != null) 'status': status,
        if (direction != null) 'direction': direction,
        'page': page,
        'pageSize': 50,
      };
}

/// An entry waiting for someone to approve it.
class Approval {
  const Approval({
    required this.summary,
    required this.createdBy,
    required this.isOwnEntry,
    this.submittedAt,
  });

  factory Approval.fromJson(Map<String, dynamic> json) => Approval(
        summary: TransactionSummary.fromJson(json),
        createdBy: json['createdBy'] as int,
        isOwnEntry: json['isOwnEntry'] as bool? ?? false,
        submittedAt: json['submittedAt'] as String?,
      );

  final TransactionSummary summary;
  final int createdBy;

  /// Nobody approves their own entry under the same login. The inbox says so
  /// on the row rather than letting someone press approve and get a 403.
  final bool isOwnEntry;
  final String? submittedAt;
}
