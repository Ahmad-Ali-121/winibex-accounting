/// "4.0000" becomes "4", "0.5000" becomes "0.5". Only for showing a rate; the
/// rate itself stays a decimal string from end to end.
String plainRate(String rate) {
  if (!rate.contains('.')) return rate;
  final trimmed = rate.replaceFirst(RegExp(r'0+$'), '');
  return trimmed.endsWith('.') ? trimmed.substring(0, trimmed.length - 1) : trimmed;
}

/// When the entry form suggests a tax. Any field left null means "any".
class TaxRuleView {
  const TaxRuleView({
    required this.id,
    required this.direction,
    required this.isActive,
    this.currencyIsForeign,
    this.accountType,
    this.categoryId,
    this.categoryName,
  });

  factory TaxRuleView.fromJson(Map<String, dynamic> json) => TaxRuleView(
    id: json['id'] as int,
    direction: json['direction'] as String,
    currencyIsForeign: json['currencyIsForeign'] as bool?,
    accountType: json['accountType'] as String?,
    categoryId: json['categoryId'] as int?,
    categoryName: json['categoryName'] as String?,
    isActive: json['isActive'] as bool? ?? true,
  );

  final int id;
  final String direction;
  final bool? currencyIsForeign;
  final String? accountType;
  final int? categoryId;
  final String? categoryName;
  final bool isActive;
}

/// One tax row: one rate for one period. A rate change is a new row.
class TaxView {
  const TaxView({
    required this.id,
    required this.name,
    required this.shortCode,
    required this.kind,
    required this.appliesTo,
    required this.computation,
    required this.rateAtl,
    required this.rateNonAtl,
    required this.statusBasis,
    required this.ledgerCode,
    required this.ledgerName,
    required this.effectiveFrom,
    required this.standing,
    required this.isCurrent,
    required this.rules,
    this.lawReference,
    this.effectiveTo,
    this.authority = 'fbr',
    this.isAdjustable = false,
  });

  factory TaxView.fromJson(Map<String, dynamic> json) {
    final ledger = json['ledger'] as Map<String, dynamic>;
    return TaxView(
      id: json['id'] as int,
      name: json['name'] as String,
      shortCode: json['shortCode'] as String,
      lawReference: json['lawReference'] as String?,
      authority: json['authority'] as String? ?? 'fbr',
      isAdjustable: json['isAdjustable'] as bool? ?? false,
      kind: json['kind'] as String,
      appliesTo: json['appliesTo'] as String,
      computation: json['computation'] as String? ?? 'percent',
      rateAtl: json['rateAtl'] as String,
      rateNonAtl: json['rateNonAtl'] as String,
      statusBasis: json['statusBasis'] as String,
      ledgerCode: ledger['code'] as String,
      ledgerName: ledger['name'] as String,
      effectiveFrom: json['effectiveFrom'] as String,
      effectiveTo: json['effectiveTo'] as String?,
      standing: json['standing'] as String,
      isCurrent: json['isCurrent'] as bool? ?? false,
      rules: (json['rules'] as List<dynamic>? ?? const [])
          .map((item) => TaxRuleView.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  final int id;
  final String name;
  final String shortCode;
  final String? lawReference;

  /// fbr, pra, srb, ict, bank or other: who the tax is paid to.
  final String authority;

  /// Counts against our income tax later, rather than being a final cost.
  final bool isAdjustable;
  final String kind;

  /// sales (money in), purchases (money out) or both.
  final String appliesTo;
  final String computation;
  final String rateAtl;
  final String rateNonAtl;

  /// company: our status decides, the tax is taken from us. counterparty: the
  /// payee's status decides, we keep the tax back from them.
  final String statusBasis;
  final String ledgerCode;
  final String ledgerName;
  final String effectiveFrom;
  final String? effectiveTo;

  /// in_force, not_yet, ended or switched_off. The server's word.
  final String standing;

  /// The newest row of its tax, still open: the one a new rate replaces.
  final bool isCurrent;
  final List<TaxRuleView> rules;

  List<String> get directions => switch (appliesTo) {
    'sales' => const ['in'],
    'purchases' => const ['out'],
    _ => const ['in', 'out'],
  };
}

class TaxLedger {
  const TaxLedger({required this.id, required this.code, required this.name});

  factory TaxLedger.fromJson(Map<String, dynamic> json) =>
      TaxLedger(id: json['id'] as int, code: json['code'] as String, name: json['name'] as String);

  final int id;
  final String code;
  final String name;
}

class TaxesOverview {
  const TaxesOverview({required this.today, required this.taxes, required this.ledgers});

  factory TaxesOverview.fromJson(Map<String, dynamic> json) => TaxesOverview(
    today: json['today'] as String,
    taxes: (json['taxes'] as List<dynamic>)
        .map((item) => TaxView.fromJson(item as Map<String, dynamic>))
        .toList(growable: false),
    ledgers: (json['ledgers'] as List<dynamic>)
        .map((item) => TaxLedger.fromJson(item as Map<String, dynamic>))
        .toList(growable: false),
  );

  final String today;
  final List<TaxView> taxes;
  final List<TaxLedger> ledgers;
}
