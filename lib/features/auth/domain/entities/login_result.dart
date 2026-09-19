import 'auth_credentials.dart';
import 'auth_user.dart';

/// Everything a successful sign-in produces.
class LoginResult {
  const LoginResult({required this.user, required this.auth});

  /// From the existing (old) login API — token, id, email, name.
  final AuthUser user;

  /// From the new auth API — portal user id, username, user type,
  /// login record id, redirection page.
  final AuthCredentials auth;
}
