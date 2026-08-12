import 'package:iungo/features/auth/domain/entities/auth_user.dart';
import 'package:iungo/features/auth/domain/repositories/auth_repository.dart';

class LoginUseCase {
  LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthUser> call({
    required String email,
    required String password,
    required String role,
  }) {
    return _repository.login(email: email, password: password, role: role);
  }
}
