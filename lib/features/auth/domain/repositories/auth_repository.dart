import '../entities/auth_credentials.dart';
import '../entities/auth_user.dart';

abstract class AuthRepository {
  /// New authentication API. Returns the email + password that the
  /// existing [login] must then be called with.
  Future<AuthCredentials> authenticate({
    required String username,
    required String password,
  });

  Future<AuthUser> login({
    required String email,
    required String password,
    required String role,
  });
}
