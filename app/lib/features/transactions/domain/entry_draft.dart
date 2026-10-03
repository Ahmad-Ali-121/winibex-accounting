import 'dart:typed_data';

import '../../../core/money/money.dart';

/// A receipt the person has chosen but not yet sent.
///
/// It waits here because there is nothing to attach it to until the entry has
/// been created. The bytes are held rather than a path, because on web there
/// is no path to hold.
class DraftAttachment {
  const DraftAttachment({
    required this.bytes,
    required this.filename,
    required this.mime,
  });

  final Uint8List bytes;
  final String filename;
  final String mime;

  int get sizeBytes => bytes.length;
  bool get isPdf => mime == 'application/pdf';
}

enum EntryDirection { moneyIn, moneyOut }

enum PaidByType { company, person }

/// A charge the bank or a platform took on top of, or out of, the amount.
class DraftCharge {
  const DraftCharge({
    required this.type,
    required this.amount,
    required this.coaId,
    this.note,
  });

  final String type; // bank_charge, forex_fee, platform_fee, card_fee, other
  final Money amount;
  final int coaId;
  final String? note;

  Map<String, dynamic> toJson() => {
        'type': type,
        'amount': amount.toJson(),
        'coaId': coaId,
        if (note != null) 'note': note,
      };
}

/// A tax line, as suggested by the server and possibly edited by the person.
///
/// Everything here is a snapshot. The rate and whose filer status decided it
/// are stored with the entry, so revising a rate next year never rewrites what
/// was posted. Decision 018.
class DraftTax {
  const DraftTax({
    required this.taxId,
    required this.name,
    required this.shortCode,
    required this.baseAmount,
    required this.rateApplied,
    required this.atlStatusUsed,
    required this.atlParty,
    required this.amount,
    required this.deductedBy,
    this.isOverride = false,
    this.warning,
  });

  final int taxId;
  final String name;
  final String shortCode;
  final Money baseAmount;
  final String rateApplied;
  final String atlStatusUsed;

  /// Whose filer status picked the rate: the company, or the payee. Shown
  /// because the two give different answers and the difference is money.
  final String atlParty;
  final Money amount;

  /// 'us' means Winibex withheld it and owes FBR. Anything else means it was
  /// taken from Winibex.
  final String deductedBy;
  final bool isOverride;
  final String? warning;

  bool get isWithheldByUs => deductedBy == 'us';

  DraftTax copyWith({Money? amount, bool? isOverride}) => DraftTax(
        taxId: taxId,
        name: name,
        shortCode: shortCode,
        baseAmount: baseAmount,
        rateApplied: rateApplied,
        atlStatusUsed: atlStatusUsed,
        atlParty: atlParty,
        amount: amount ?? this.amount,
        deductedBy: deductedBy,
        isOverride: isOverride ?? this.isOverride,
        warning: warning,
      );

  factory DraftTax.fromSuggestion(Map<String, dynamic> json) => DraftTax(
        taxId: json['taxId'] as int,
        name: json['name'] as String,
        shortCode: json['shortCode'] as String? ?? '',
        baseAmount: Money.fromJson(json['baseAmount'] as Map<String, dynamic>),
        rateApplied: json['rateApplied'] as String? ?? '0',
        atlStatusUsed: json['atlStatusUsed'] as String? ?? 'non_atl',
        atlParty: json['atlParty'] as String? ?? 'company',
        amount: Money.fromJson(json['amount'] as Map<String, dynamic>),
        deductedBy: json['deductedBy'] as String? ?? 'bank',
        warning: json['warning'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'taxId': taxId,
        'baseAmount': baseAmount.toJson(),
        'rateApplied': rateApplied,
        'atlStatusUsed': atlStatusUsed,
        'atlParty': atlParty,
        'amount': amount.toJson(),
        'isOverride': isOverride,
        'deductedBy': deductedBy,
      };
}

/// Everything the entry form holds while it is being filled in.
///
/// Immutable: every change produces a new one, so a half-applied edit cannot
/// exist. Nothing here is a total the person sees as a balance; the amount
/// that actually moves comes back from the server's preview.
class EntryDraft {
  const EntryDraft({
    required this.idempotencyKey,
    required this.date,
    this.direction = EntryDirection.moneyOut,
    this.accountId,
    this.paidByType = PaidByType.company,
    this.paidByUserId,
    this.currency = 'PKR',
    this.foreignAmount,
    this.fxRate,
    this.pkrAmount,
    this.categoryId,
    this.description = '',
    this.method = 'account',
    this.vendorId,
    this.clientId,
    this.isRebillable = false,
    this.taxes = const [],
    this.charges = const [],
    this.acknowledgedWarnings = const [],
    this.receipt,
  });

  /// Generated once when the form opens, so a double tap or a retry cannot
  /// post the same expense twice. Decision 024.
  final String idempotencyKey;

  final String date;
  final EntryDirection direction;
  final int? accountId;
  final PaidByType paidByType;
  final int? paidByUserId;

  final String currency;

  /// In the foreign currency's minor units: 2000 is $20.00.
  final Money? foreignAmount;

  /// As a decimal string, never a double. '280.000000'.
  final String? fxRate;

  /// The PKR figure. For a PKR entry this is what was entered. For a foreign
  /// entry the person may type the PKR the bank actually gave instead of a
  /// rate, and the server derives the rate from it. Decision 017.
  final Money? pkrAmount;

  final int? categoryId;
  final String description;
  final String method;
  final int? vendorId;
  final int? clientId;
  final bool isRebillable;

  final List<DraftTax> taxes;
  final List<DraftCharge> charges;

  /// Warning codes the person has seen and confirmed. Sent back with the same
  /// request so it goes through, and recorded against the entry.
  final List<String> acknowledgedWarnings;

  /// Sent after the entry is created and before it is posted, because a
  /// payment above the threshold cannot enter the book without one.
  final DraftAttachment? receipt;

  bool get isForeign => currency != 'PKR';
  bool get paidPersonally => paidByType == PaidByType.person;

  /// Enough to ask the server for a preview. Not the same as valid: the server
  /// decides that, and will say what is wrong.
  bool get canPreview =>
      categoryId != null &&
      description.trim().isNotEmpty &&
      (pkrAmount?.minorUnits ?? 0) > 0 &&
      (paidPersonally ? paidByUserId != null : accountId != null) &&
      (!isForeign || (fxRate != null && (foreignAmount?.minorUnits ?? 0) > 0));

  EntryDraft copyWith({
    String? date,
    EntryDirection? direction,
    int? accountId,
    bool clearAccount = false,
    PaidByType? paidByType,
    int? paidByUserId,
    bool clearPaidBy = false,
    String? currency,
    Money? foreignAmount,
    String? fxRate,
    bool clearForeign = false,
    Money? pkrAmount,
    int? categoryId,
    String? description,
    String? method,
    int? vendorId,
    int? clientId,
    bool? isRebillable,
    List<DraftTax>? taxes,
    List<DraftCharge>? charges,
    List<String>? acknowledgedWarnings,
    DraftAttachment? receipt,
    bool clearReceipt = false,
  }) {
    return EntryDraft(
      idempotencyKey: idempotencyKey,
      date: date ?? this.date,
      direction: direction ?? this.direction,
      accountId: clearAccount ? null : (accountId ?? this.accountId),
      paidByType: paidByType ?? this.paidByType,
      paidByUserId: clearPaidBy ? null : (paidByUserId ?? this.paidByUserId),
      currency: currency ?? this.currency,
      foreignAmount: clearForeign ? null : (foreignAmount ?? this.foreignAmount),
      fxRate: clearForeign ? null : (fxRate ?? this.fxRate),
      pkrAmount: pkrAmount ?? this.pkrAmount,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      method: method ?? this.method,
      vendorId: vendorId ?? this.vendorId,
      clientId: clientId ?? this.clientId,
      isRebillable: isRebillable ?? this.isRebillable,
      taxes: taxes ?? this.taxes,
      charges: charges ?? this.charges,
      acknowledgedWarnings: acknowledgedWarnings ?? this.acknowledgedWarnings,
      receipt: clearReceipt ? null : (receipt ?? this.receipt),
    );
  }

  /// The request body, exactly as docs/API.md describes it. Money is always an
  /// object, never a bare number.
  Map<String, dynamic> toRequest() {
    return {
      'date': date,
      'direction': direction == EntryDirection.moneyIn ? 'in' : 'out',
      'method': method,
      'description': description.trim(),
      'categoryId': categoryId,
      'accountId': paidPersonally ? null : accountId,
      if (paidPersonally) 'paidByType': 'person',
      if (paidPersonally) 'paidByUserId': paidByUserId,
      'gross': (pkrAmount ?? Money.zero).toJson(),
      if (isForeign && foreignAmount != null) 'foreign': foreignAmount!.toJson(),
      if (isForeign && fxRate != null) 'fxRate': fxRate,
      if (isForeign) 'fxRateSource': 'manual',
      if (vendorId != null) 'vendorId': vendorId,
      if (clientId != null) 'clientId': clientId,
      if (isRebillable) 'isRebillable': true,
      if (taxes.isNotEmpty) 'taxes': taxes.map((tax) => tax.toJson()).toList(),
      if (charges.isNotEmpty) 'charges': charges.map((charge) => charge.toJson()).toList(),
      if (acknowledgedWarnings.isNotEmpty) 'acknowledged_warnings': acknowledgedWarnings,
    };
  }
}
