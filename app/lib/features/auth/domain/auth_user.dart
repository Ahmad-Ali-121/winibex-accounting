/// The signed-in user, as the server describes them. Mirrors publicUser() in
/// the API, so every field here exists in the login response.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.mustChangePassword,
    this.autoApproveOwn = false,
    this.approvalLimit,
  });

  final int id;
  final String name;
  final String email;
  final String role;
  final bool mustChangePassword;

  /// An admin whose own entries post directly. The server has always sent
  /// this; the app did not read it until defect D4.
  final bool autoApproveOwn;

  /// An admin's approval limit in paisa, or null for none. Shown for
  /// information only: the server applies it.
  final int? approvalLimit;

  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'admin';
  bool get canApprove => role == 'owner' || role == 'admin';

  /// Whether this person's own new entry posts straight away, which is what
  /// decides "Save and post" against "Submit for approval". The owner login
  /// and admins with auto-approve can. Every other admin is like staff for
  /// their own entries: someone else approves them. Decision 036.
  ///
  /// Before D4 every admin was shown "Save and post", the server refused, and
  /// a stray draft was left behind.
  bool get canPostOwnEntries => isOwner || (isAdmin && autoApproveOwn);

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      mustChangePassword: json['mustChangePassword'] as bool? ?? false,
      autoApproveOwn: json['autoApproveOwn'] as bool? ?? false,
      approvalLimit: (json['approvalLimit'] as num?)?.toInt(),
    );
  }
}
