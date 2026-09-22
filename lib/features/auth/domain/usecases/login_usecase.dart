import 'package:iungo/features/auth/domain/entities/auth_credentials.dart';
import 'package:iungo/features/auth/domain/entities/auth_user.dart';
import 'package:iungo/features/auth/domain/entities/login_result.dart';
import 'package:iungo/features/auth/domain/repositories/auth_repository.dart';

/// Full sign-in sequence:
///
///   1. NEW auth API  (username/email + password from the form)
///   2. EXISTING login API, called with the email + password RETURNED by
///      step 1 (not the typed values)
///
/// If step 1 throws (network, HTTP error, auth failure, malformed /
/// incomplete response), step 2 is never called and the exception
/// propagates to the caller unchanged — sign-in fails.
///
/// Step 2 no longer gates sign-in: whether it succeeds or fails, the
/// person is still signed in and taken to the dashboard, as long as
/// step 1 succeeded. If step 2 fails, [_fallbackUser] stands in for its
/// result, built entirely from step 1's data (so there's no token from
/// the old login API — features that need it may not work until step 2
/// succeeds on a later sign-in).
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

    AuthUser user;
    try {
      user = await _repository.login(
        email: credentials.email,
        password: credentials.password,
        role: role,
      );
    } catch (_) {
      user = _fallbackUser(credentials, role);
    }

    return LoginResult(user: user, auth: credentials);
  }

  /// Stands in for the old login API's [AuthUser] when that call fails,
  /// so sign-in can still proceed on step 1 alone.
  AuthUser _fallbackUser(AuthCredentials credentials, String role) {
    return AuthUser(
      id: credentials.userId ?? '',
      email: credentials.email,
      token: '',
      role: role,
      name: credentials.username,
    );
  }
}