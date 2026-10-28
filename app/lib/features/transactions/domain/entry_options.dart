/// The six currencies the entry form offers, in the order it shows them.
/// The same six the server seeds in `currencies` (migration 002). Adding one
/// means a row there and a code here.
const entryCurrencies = ['PKR', 'USD', 'GBP', 'AED', 'QAR', 'EUR'];

/// A tax that can be added to an entry by hand: in force on the entry's date
/// and for its direction. The amount is never worked out here; picking one
/// asks the server for the line. Decision 064.
class TaxOption {
  const TaxOption({
    required this.id,
    required this.name,
    required this.shortCode,
    this.lawReference,
  });

  factory TaxOption.fromJson(Map<String, dynamic> json) => TaxOption(
        id: json['id'] as int,
        name: json['name'] as String,
        shortCode: json['shortCode'] as String? ?? '',
        lawReference: json['lawReference'] as String?,
      );

  final int id;
  final String name;
  final String shortCode;
  final String? lawReference;
}

/// Someone Winibex pays, as the entry form needs them: enough to pick one and
/// to say when tax cannot be kept back from them.
class VendorOption {
  const VendorOption({
    required this.id,
    required this.name,
    required this.canBeWithheldFrom,
    required this.atlStatus,
  });

  factory VendorOption.fromJson(Map<String, dynamic> json) => VendorOption(
        id: json['id'] as int,
        name: json['name'] as String,
        canBeWithheldFrom: json['canBeWithheldFrom'] as bool? ?? false,
        atlStatus: json['atlStatus'] as String? ?? 'unknown',
      );

  final int id;
  final String name;

  /// False for a local payee with no NTN and no CNIC. The server refuses tax
  /// kept back from them, so the form says so beside their name.
  final bool canBeWithheldFrom;

  /// atl, non_atl or unknown. Unknown gets the higher, non-filer rate.
  final String atlStatus;
}

/// A cost account a charge may go to, for the account picker on a charge line.
class ChargeAccount {
  const ChargeAccount({required this.id, required this.code, required this.name});

  final int id;
  final String code;
  final String name;
}
