/// The signed-in user, as the server describes them. Mirrors publicUser() in
/// the API, so every field here exists in the login response.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.mustChangePassword,
  });

  final int id;
  final String name;
  final String email;
  final String role;
  final bool mustChangePassword;

  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'admin';
  bool get canApprove => role == 'owner' || role == 'admin';

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      mustChangePassword: json['mustChangePassword'] as bool? ?? false,
    );
  }
}
