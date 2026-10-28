import '../../../core/money/money.dart';

/// Someone who can sign in, as the owner sees them on the People screen.
///
/// Named TeamMember, not Person: Person is the thin picker entry used on the
/// entry form, which carries a name and nothing else.
class TeamMember {
  const TeamMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.approvalLimit,
    this.autoApproveOwn = false,
    this.sharesOwnerLogin = false,
    this.isActive = true,
    this.mustChangePassword = false,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) => TeamMember(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
        approvalLimit: json['approvalLimit'] == null
            ? null
            : Money.fromJson(json['approvalLimit'] as Map<String, dynamic>),
        autoApproveOwn: json['autoApproveOwn'] as bool? ?? false,
        sharesOwnerLogin: json['sharesOwnerLogin'] as bool? ?? false,
        isActive: json['isActive'] as bool? ?? true,
        mustChangePassword: json['mustChangePassword'] as bool? ?? false,
      );

  final int id;
  final String name;
  final String email;

  /// owner, admin or staff.
  final String role;

  /// The biggest entry an admin may approve. Null means no limit.
  final Money? approvalLimit;
  final bool autoApproveOwn;
  final bool sharesOwnerLogin;
  final bool isActive;
  final bool mustChangePassword;

  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'admin';
}

/// What the owner fills in to add someone, or to change them. Fields left null
/// on a change are not sent, so the server keeps what it has.
class TeamMemberForm {
  const TeamMemberForm({
    required this.name,
    required this.role,
    this.email,
    this.temporaryPassword,
    this.approvalLimit,
    this.autoApproveOwn = false,
    this.sharesOwnerLogin = false,
  });

  final String name;
  final String role;
  final String? email;
  final String? temporaryPassword;
  final Money? approvalLimit;
  final bool autoApproveOwn;
  final bool sharesOwnerLogin;

  Map<String, dynamic> toAddRequest() => {
        'name': name,
        'email': email,
        'role': role,
        'temporaryPassword': temporaryPassword,
        'approvalLimit': approvalLimit?.toJson(),
        'autoApproveOwn': autoApproveOwn,
        'sharesOwnerLogin': sharesOwnerLogin,
      };

  Map<String, dynamic> toChangeRequest() => {
        'name': name,
        'role': role,
        'approvalLimit': approvalLimit?.toJson(),
        'autoApproveOwn': autoApproveOwn,
        'sharesOwnerLogin': sharesOwnerLogin,
      };
}
