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
    this.addPurchaseRequest,
  });

  final String email;
  final String password;

  final String? userId;
  final String? username;
  final String? userType;
  final int? loginRecordId;
  final String? redirectionPage;

  /// `add_purchase_request` from login: `true` (1) = Requestor,
  /// `false` (0) = Approver, `null` = the API didn't say.
  final bool? addPurchaseRequest;

  /// Deliberately masks the password so accidentally printing/logging this
  /// object can never leak it.
  @override
  String toString() => 'AuthCredentials(email: $email, password: ****)';
}
