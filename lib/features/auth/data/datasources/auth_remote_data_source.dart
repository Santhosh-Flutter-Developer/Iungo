import 'package:dio/dio.dart';

import '../models/auth_user_model.dart';
import 'auth_exceptions.dart';

abstract class AuthRemoteDataSource {
  Future<AuthUserModel> login({
    required String email,
    required String password,
    required String role,
  });
}

/// Dio-backed implementation. Point [Dio.options.baseUrl] at the real
/// Iungo API host via the DI binding before shipping.
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<AuthUserModel> login({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
          'role': role,
        },
      );

      final data = response.data as Map<String, dynamic>;
      return AuthUserModel.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw const AccountNotFoundException();
      }
      final message = e.response?.data is Map
          ? (e.response?.data['message']?.toString() ?? e.message)
          : e.message;
      throw AuthServerException(message ?? 'Something went wrong');
    }
  }
}
