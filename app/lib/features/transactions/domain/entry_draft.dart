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
    required this.id,
    required this.type,
    required this.amount,
    this.coaId,
    this.note,
  });

  /// The form's own number for the line, so its fields keep their text when
  /// another line is removed. Never sent.
  final int id;

  final String type; // bank_charge, forex_fee, platform_fee, card_fee, other
  final Money amount;

  /// Null means the usual account for the type, which the server fills in:
  /// bank charge 8100, forex and card fees 8200, platform fee 5400. Decision 064.
  final int? coaId;
  final String? note;

  bool get isFilledIn => amount.minorUnits > 0;

  DraftCharge copyWith({String? type, Money? amount, int? coaId, bool usualAccount = false}) => DraftCharge(
        id: id,
        type: type ?? this.type,
        amount: amount ?? this.amount,
        coaId: usualAccount ? null : (coaId ?? this.coaId),
        note: note,
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'amount': amount.toJson(),
        if (coaId != null) 'coaId': coaId,
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
    this.taxesChecked = false,
    this.existingId,
    this.sentBackReason,
  });

  /// A draft already on the server, opened again to be fixed: one being
  /// edited, one taken back before approval, or one sent back. Built from
  /// `GET /transactions/:id`. Saving edits that draft rather than creating a
  /// new one. Decision 067.
  factory EntryDraft.fromDetail(Map<String, dynamic> detail, {required String idempotencyKey}) {
    final row = detail['transaction'] as Map<String, dynamic>;
    int? asInt(Object? value) => value == null ? null : (value is int ? value : int.parse('$value'));
    String day(Object? value) {
      final text = '$value';
      return text.length < 10 ? text : text.substring(0, 10);
    }

    final currency = (row['currency'] as String?) ?? 'PKR';
    final foreign = asInt(row['foreign_amount']);
    // DECIMAL(18,6) arrives as "280.000000". Shown as "280", as it was typed.
    String? plainRate(Object? value) {
      if (value == null) return null;
      var text = '$value';
      if (!text.contains('.')) return text;
      text = text.replaceFirst(RegExp(r'0+$'), '');
      return text.endsWith('.') ? text.substring(0, text.length - 1) : text;
    }

    final rate = plainRate(row['fx_rate']);
    final reason = row['rejection_reason'] as String?;

    final taxes = <DraftTax>[
      for (final tax in (detail['taxes'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>())
        DraftTax(
          taxId: asInt(tax['tax_id'])!,
          name: (tax['tax_name'] as String?) ?? '',
          shortCode: (tax['tax_short_code'] as String?) ?? '',
          baseAmount: Money.pkr(asInt(tax['base_amount'])!),
          rateApplied: '${tax['rate_applied']}',
          atlStatusUsed: (tax['atl_status_used'] as String?) ?? 'non_atl',
          atlParty: (tax['atl_party'] as String?) ?? 'company',
          amount: Money.pkr(asInt(tax['tax_amount'])!),
          deductedBy: (tax['deducted_by'] as String?) ?? 'bank',
          isOverride: tax['is_override'] == true || tax['is_override'] == 1,
        ),
    ];

    var chargeId = 1;
    final charges = <DraftCharge>[
      for (final charge in (detail['charges'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>())
        DraftCharge(
          id: chargeId++,
          type: (charge['type'] as String?) ?? 'other',
          amount: Money.pkr(asInt(charge['amount'])!),
          coaId: asInt(charge['coa_id']),
          note: charge['note'] as String?,
        ),
    ];

    return EntryDraft(
      idempotencyKey: idempotencyKey,
      existingId: asInt(row['id']),
      sentBackReason: reason == null || reason.trim().isEmpty ? null : reason,
      date: day(row['date']),
      direction: row['direction'] == 'in' ? EntryDirection.moneyIn : EntryDirection.moneyOut,
      accountId: asInt(row['account_id']),
      paidByType: row['paid_by_type'] == 'person' ? PaidByType.person : PaidByType.company,
      paidByUserId: asInt(row['paid_by_user_id']),
      currency: currency,
      foreignAmount: foreign == null ? null : Money(minorUnits: foreign, currency: currency),
      fxRate: rate,
      pkrAmount: Money.pkr(asInt(row['gross_amount']) ?? 0),
      categoryId: asInt(row['category_id']),
      description: (row['description'] as String?) ?? '',
      method: (row['method'] as String?) ?? 'account',
      vendorId: asInt(row['vendor_id']),
      clientId: asInt(row['client_id']),
      isRebillable: row['is_rebillable'] == true || row['is_rebillable'] == 1,
      taxes: taxes,
      charges: charges,
      // The lines were worked out when the draft was saved. They are kept as
      // they are; changing a figure they depend on throws them away and
      // suggests again, as for a new entry.
      taxesChecked: true,
    );
  }

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

  /// Whether the taxes have been suggested for the figures now on the form.
  /// Anything the taxes depend on (date, direction, amount, account,
  /// category) sets this back to false and clears the lines, so a tax worked
  /// out on an old amount can never be saved with a new one. Decision 064.
  final bool taxesChecked;

  /// Set when this form is fixing a draft already on the server.
  final int? existingId;

  /// Why an approver sent it back, shown above the form while it is fixed.
  final String? sentBackReason;

  /// Tax kept back from the payee needs the payee chosen. Decision 062.
  bool get withholds => taxes.any((tax) => tax.isWithheldByUs);

  bool get isForeign => currency != 'PKR';
  bool get paidPersonally => paidByType == PaidByType.person;

  /// Enough to ask the server for a preview. Not the same as valid: the server
  /// decides that, and will say what is wrong.
  bool get canPreview =>
      categoryId != null &&
      description.trim().isNotEmpty &&
      (pkrAmount?.minorUnits ?? 0) > 0 &&
      (paidPersonally ? paidByUserId != null : accountId != null) &&
      (!isForeign || (fxRate != null && (foreignAmount?.minorUnits ?? 0) > 0)) &&
      charges.every((charge) => charge.isFilledIn);

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
    bool clearCategory = false,
    String? description,
    String? method,
    int? vendorId,
    bool clearVendor = false,
    int? clientId,
    bool? isRebillable,
    List<DraftTax>? taxes,
    List<DraftCharge>? charges,
    List<String>? acknowledgedWarnings,
    DraftAttachment? receipt,
    bool clearReceipt = false,
    bool? taxesChecked,
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
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      description: description ?? this.description,
      method: method ?? this.method,
      vendorId: clearVendor ? null : (vendorId ?? this.vendorId),
      clientId: clientId ?? this.clientId,
      isRebillable: isRebillable ?? this.isRebillable,
      taxes: taxes ?? this.taxes,
      charges: charges ?? this.charges,
      acknowledgedWarnings: acknowledgedWarnings ?? this.acknowledgedWarnings,
      receipt: clearReceipt ? null : (receipt ?? this.receipt),
      taxesChecked: taxesChecked ?? this.taxesChecked,
      existingId: existingId,
      sentBackReason: sentBackReason,
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
