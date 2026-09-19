import 'package:iungo/features/auth/domain/entities/login_result.dart';
import 'package:iungo/features/auth/domain/repositories/auth_repository.dart';

/// Full sign-in sequence:
///
///   1. NEW auth API  (username/email + password from the form)
///   2. EXISTING login API, called with the email + password RETURNED by
///      step 1 (not the typed values)
///
/// If step 1 throws (network, HTTP error, auth failure, malformed /
/// incomplete response) step 2 is never called and the exception
/// propagates to the caller unchanged. Step 2 and everything after it
/// behave exactly as before.
class LoginUseCase {
  LoginUseCase(this._repository);

  final AuthRepository _repository;

  /// [email] is whatever the user typed in the username/email field.
  Future<LoginResult> call({
    required String email,
    required String password,
    required String role,
  }) async {
    final credentials = await _repository.authenticate(
      username: email,
      password: password,
    );

    final user = await _repository.login(
      email: credentials.email,
      password: credentials.password,
      role: role,
    );

    return LoginResult(user: user, auth: credentials);
  }
}
