/// Someone Winibex pays other than staff: a contractor, a supplier, a
/// platform. Their NTN or CNIC is what the quarterly withholding statement
/// reports, and their filer status sets the rate of any tax kept back.
class Vendor {
  const Vendor({
    required this.id,
    required this.name,
    required this.kind,
    required this.atlStatus,
    required this.isActive,
    this.ntn,
    this.cnic,
    this.atlCheckedOn,
    this.atlCheckIsStale = false,
    this.canBeWithheldFrom = false,
    this.country,
    this.email,
    this.phone,
    this.notes,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) => Vendor(
        id: json['id'] as int,
        name: json['name'] as String,
        kind: json['kind'] as String? ?? 'company',
        ntn: _text(json['ntn']),
        cnic: _text(json['cnic']),
        atlStatus: json['atlStatus'] as String? ?? 'unknown',
        atlCheckedOn: _date(json['atlCheckedOn']),
        atlCheckIsStale: json['atlCheckIsStale'] as bool? ?? false,
        canBeWithheldFrom: json['canBeWithheldFrom'] as bool? ?? false,
        country: _text(json['country']),
        email: _text(json['email']),
        phone: _text(json['phone']),
        notes: _text(json['notes']),
        isActive: json['isActive'] as bool? ?? true,
      );

  static String? _text(Object? value) {
    final text = value as String?;
    return text == null || text.trim().isEmpty ? null : text;
  }

  /// The server may send a date or a full timestamp; only the day matters.
  static String? _date(Object? value) {
    final text = value as String?;
    return text == null || text.length < 10 ? text : text.substring(0, 10);
  }

  final int id;
  final String name;

  /// company, aop, individual or foreign.
  final String kind;
  final String? ntn;
  final String? cnic;

  /// atl (filer), non_atl (non-filer) or unknown (not checked yet).
  final String atlStatus;
  final String? atlCheckedOn;

  /// Checked more than 30 days ago, or never. The server decides.
  final bool atlCheckIsStale;

  /// A local payee needs an NTN or a CNIC before tax can be kept back.
  final bool canBeWithheldFrom;
  final String? country;
  final String? email;
  final String? phone;
  final String? notes;
  final bool isActive;

  bool get isForeign => kind == 'foreign';
}

/// What the form sends. Empty fields are left out, so the server keeps
/// nothing as an empty string.
class VendorForm {
  const VendorForm({
    required this.name,
    required this.kind,
    required this.atlStatus,
    this.ntn = '',
    this.cnic = '',
    this.atlCheckedOn,
    this.country = '',
    this.email = '',
    this.phone = '',
    this.notes = '',
  });

  final String name;
  final String kind;
  final String ntn;
  final String cnic;
  final String atlStatus;
  final String? atlCheckedOn;
  final String country;
  final String email;
  final String phone;
  final String notes;

  Map<String, dynamic> toRequest() {
    String? filled(String value) => value.trim().isEmpty ? null : value.trim();
    return {
      'name': name.trim(),
      'kind': kind,
      'atlStatus': atlStatus,
      if (filled(ntn) != null) 'ntn': filled(ntn),
      if (filled(cnic) != null) 'cnic': filled(cnic),
      if (atlStatus != 'unknown' && atlCheckedOn != null) 'atlCheckedOn': atlCheckedOn,
      if (filled(country) != null) 'country': filled(country),
      if (filled(email) != null) 'email': filled(email),
      if (filled(phone) != null) 'phone': filled(phone),
      if (filled(notes) != null) 'notes': filled(notes),
    };
  }
}
