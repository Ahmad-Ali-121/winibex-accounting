import '../../../core/money/money.dart';

/// An account money actually moves on: a bank account, the cash tin, petty
/// cash, the cheque drawer.
///
/// The balance is not stored anywhere, here or on the server. It is the sum of
/// posted and reversed journal lines on this account's ledger code, computed
/// on every request. Decision 008. The app never adds to it or adjusts it
/// locally: after a write it asks again.
class Account {
  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.isActive,
    required this.ledger,
    required this.balance,
    this.openingDate,
    this.ownerUserId,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] as int,
      name: json['name'] as String,
      type: AccountType.from(json['type'] as String?),
      isActive: json['isActive'] as bool? ?? true,
      ledger: LedgerAccount.fromJson(json['ledger'] as Map<String, dynamic>),
      balance: Money.fromJson(json['balance'] as Map<String, dynamic>),
      openingDate: json['openingDate'] as String?,
      ownerUserId: json['ownerUserId'] as int?,
    );
  }

  final int id;
  final String name;
  final AccountType type;
  final bool isActive;
  final LedgerAccount ledger;
  final Money balance;
  final String? openingDate;

  /// Set only on a pass-through account: a person's own account holding
  /// company money in transit.
  final int? ownerUserId;
}

enum AccountType {
  bank,
  cash,
  pettyCash,
  cheque,
  passThrough,
  unknown;

  static AccountType from(String? value) => switch (value) {
        'bank' => AccountType.bank,
        'cash' => AccountType.cash,
        'petty_cash' => AccountType.pettyCash,
        'cheque' => AccountType.cheque,
        'pass_through' => AccountType.passThrough,
        _ => AccountType.unknown,
      };
}

class LedgerAccount {
  const LedgerAccount({required this.id, required this.code, required this.name});

  factory LedgerAccount.fromJson(Map<String, dynamic> json) => LedgerAccount(
        id: json['id'] as int,
        code: json['code'] as String,
        name: json['name'] as String,
      );

  final int id;

  /// The chart of accounts code, 1113 and so on. Shown because it is what the
  /// accountant recognises, where the account name is what the company calls it.
  final String code;
  final String name;
}

/// What `GET /accounts` returns whole: the accounts, the total the server
/// worked out, and whether history has been merged yet.
class AccountsSummary {
  const AccountsSummary({
    required this.accounts,
    required this.total,
    required this.historyMerged,
  });

  factory AccountsSummary.fromJson(Map<String, dynamic> json) => AccountsSummary(
        accounts: (json['accounts'] as List<dynamic>)
            .map((item) => Account.fromJson(item as Map<String, dynamic>))
            .toList(growable: false),
        total: Money.fromJson(json['total'] as Map<String, dynamic>),
        historyMerged: json['historyMerged'] as bool? ?? false,
      );

  final List<Account> accounts;

  /// From the server. Never recomputed here: two places that both know how to
  /// total a set of balances will eventually disagree.
  final Money total;

  /// While this is false, entries dated before 1 July 2026 are excluded from
  /// every balance above, because the opening entry already contains them.
  final bool historyMerged;
}

/// `GET /accounts/petty-cash`: the imprest float and what to draw to restore it.
class PettyCashStatus {
  const PettyCashStatus({required this.imprest, required this.accounts});

  factory PettyCashStatus.fromJson(Map<String, dynamic> json) => PettyCashStatus(
        imprest: json['imprest'] == null
            ? null
            : Money.fromJson(json['imprest'] as Map<String, dynamic>),
        accounts: (json['accounts'] as List<dynamic>)
            .map((item) => PettyCashAccount.fromJson(item as Map<String, dynamic>))
            .toList(growable: false),
      );

  final Money? imprest;
  final List<PettyCashAccount> accounts;
}

class PettyCashAccount {
  const PettyCashAccount({
    required this.account,
    required this.belowFloat,
    required this.suggestedTopUp,
  });

  factory PettyCashAccount.fromJson(Map<String, dynamic> json) => PettyCashAccount(
        account: Account.fromJson(json),
        belowFloat: json['belowFloat'] as bool? ?? false,
        suggestedTopUp: Money.fromJson(json['suggestedTopUp'] as Map<String, dynamic>),
      );

  final Account account;
  final bool belowFloat;
  final Money suggestedTopUp;
}
