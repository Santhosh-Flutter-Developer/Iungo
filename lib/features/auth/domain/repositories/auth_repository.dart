import '../entities/auth_user.dart';

abstract class AuthRepository {
  Future<AuthUser> login({
    required String email,
    required String password,
    required String role,
  });
}
