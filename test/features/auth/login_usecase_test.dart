import 'package:flutter_test/flutter_test.dart';
import 'package:iungo/features/auth/data/datasources/auth_exceptions.dart';
import 'package:iungo/features/auth/domain/entities/auth_credentials.dart';
import 'package:iungo/features/auth/domain/entities/auth_user.dart';
import 'package:iungo/features/auth/domain/repositories/auth_repository.dart';
import 'package:iungo/features/auth/domain/usecases/login_usecase.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.credentials, this.authError, this.loginError});

  final AuthCredentials? credentials;
  final Object? authError;
  final Object? loginError;

  int authCalls = 0;
  int loginCalls = 0;
  String? authUsername;
  String? authPassword;
  String? loginEmail;
  String? loginPassword;
  String? loginRole;

  @override
  Future<AuthCredentials> authenticate({
    required String username,
    required String password,
  }) async {
    authCalls++;
    authUsername = username;
    authPassword = password;
    if (authError != null) throw authError!;
    return credentials!;
  }

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
    required String role,
  }) async {
    loginCalls++;
    loginEmail = email;
    loginPassword = password;
    loginRole = role;
    if (loginError != null) throw loginError!;
    return AuthUser(id: '1', email: email, token: 'tok', role: role);
  }
}

void main() {
  const returned = AuthCredentials(
    email: 'returned@example.com',
    password: 'returned-pass',
    userId: 'abc',
    username: 'mareeswari',
    userType: 'employee',
    loginRecordId: 3779,
    redirectionPage: 'home.php',
  );

  test('Scenario 1: old login is called with the RETURNED email/password',
      () async {
    final repo = _FakeAuthRepository(credentials: returned);

    final result = await LoginUseCase(repo)(
      email: 'typed-username',
      password: 'typed-pass',
      role: 'tenant',
    );

    expect(repo.authCalls, 1);
    expect(repo.authUsername, 'typed-username');
    expect(repo.authPassword, 'typed-pass');

    expect(repo.loginCalls, 1);
    expect(repo.loginEmail, 'returned@example.com');
    expect(repo.loginPassword, 'returned-pass');
    expect(repo.loginRole, 'tenant');
    expect(result.user.email, 'returned@example.com');
    // Profile data from the new auth API is carried through for the session.
    expect(result.auth.username, 'mareeswari');
    expect(result.auth.userType, 'employee');
    expect(result.auth.loginRecordId, 3779);
  });

  // Scenarios 2, 3, 4, 6, 7: any new-auth failure (auth rejected, missing
  // email / password -> invalidResponse, no internet, timeout) must stop
  // before the old login API.
  for (final type in AuthApiFailureType.values) {
    test('new auth failure (${type.name}) -> old login NOT called', () async {
      final repo = _FakeAuthRepository(authError: AuthApiException(type));

      await expectLater(
        LoginUseCase(repo)(email: 'u', password: 'p', role: 'tenant'),
        throwsA(
          isA<AuthApiException>().having((e) => e.type, 'type', type),
        ),
      );

      expect(repo.authCalls, 1);
      expect(repo.loginCalls, 0);
    });
  }

  test('Scenario 5: old login failure propagates with its existing '
      'exception type', () async {
    final repo = _FakeAuthRepository(
      credentials: returned,
      loginError: const AccountNotFoundException(),
    );

    await expectLater(
      LoginUseCase(repo)(email: 'u', password: 'p', role: 'tenant'),
      throwsA(isA<AccountNotFoundException>()),
    );

    expect(repo.authCalls, 1);
    expect(repo.loginCalls, 1);
  });

  test('AuthCredentials.toString never exposes the password', () {
    expect(returned.toString(), isNot(contains('returned-pass')));
  });
}
