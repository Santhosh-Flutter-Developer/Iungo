import 'package:iungo/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:iungo/features/auth/domain/entities/auth_user.dart';
import 'package:iungo/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
    required String role,
  }) {
    return _remote.login(email: email, password: password, role: role);
  }
}
