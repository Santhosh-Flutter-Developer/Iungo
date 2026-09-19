/// Result of the new authentication API (`auth.php`).
///
/// [email] + [password] are what the existing login API must be called
/// with. The remaining fields describe the signed-in portal user and are
/// persisted by `SessionService` for later features (e.g. the PR create
/// page). The password is NEVER persisted.
class AuthCredentials {
  const AuthCredentials({
    required this.email,
    required this.password,
    this.userId,
    this.username,
    this.userType,
    this.loginRecordId,
    this.redirectionPage,
  });

  final String email;
  final String password;

  final String? userId;
  final String? username;
  final String? userType;
  final int? loginRecordId;
  final String? redirectionPage;

  /// Deliberately masks the password so accidentally printing/logging this
  /// object can never leak it.
  @override
  String toString() => 'AuthCredentials(email: $email, password: ****)';
}
