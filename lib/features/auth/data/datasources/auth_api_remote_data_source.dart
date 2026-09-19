import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/auth_credentials.dart';
import '../models/auth_api_response_model.dart';
import 'auth_exceptions.dart';

abstract class AuthApiRemoteDataSource {
  /// Calls the new authentication API and returns the email + password it
  /// hands back. Throws [AuthApiException] for every failure — in which
  /// case the caller must NOT go on to call the old login API.
  Future<AuthCredentials> authenticate({
    required String username,
    required String password,
  });
}

/// Talks to the new authentication API:
///
///   GET https://iungo.citgroupltd.com/api/auth.php
///
/// with a JSON body of `{ "username": ..., "password": ... }` — the same
/// request shape (GET + JSON body, via `dio`) that the existing login API
/// in `AuthRemoteDataSourceImpl` already uses successfully, so both auth
/// calls behave identically on every platform.
///
/// Security: nothing from the request or the response body is logged.
/// The only debug output is the HTTP status / application `code` / failure
/// type. Credentials are never hard-coded here.
class AuthApiRemoteDataSourceImpl implements AuthApiRemoteDataSource {
  AuthApiRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  static const _authUrl = 'https://iungo.citgroupltd.com/api/auth.php';
  static const _successCode = 200;

  @override
  Future<AuthCredentials> authenticate({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.request<dynamic>(
        _authUrl,
        data: {
          'username': username,
          'password': password,
        },
        options: Options(
          method: 'GET',
          contentType: Headers.jsonContentType,
          headers: {'Accept': 'application/json'},
        ),
      );

      final body = _asMap(response.data);
      if (body == null) {
        throw const AuthApiException(AuthApiFailureType.invalidResponse);
      }

      final parsed = AuthApiResponseModel.fromJson(body);
      if (kDebugMode) {
        debugPrint(
          '[AuthApi] HTTP ${response.statusCode}, code=${parsed.code}',
        );
      }

      final code = parsed.code;
      if (code == null) {
        throw const AuthApiException(AuthApiFailureType.invalidResponse);
      }

      // Application-level failure (some backends answer HTTP 200 with a
      // failure `code` in the body).
      if (code != _successCode) {
        throw AuthApiException(
          _typeForCode(code, fallback: AuthApiFailureType.rejected),
          message: _cleanMessage(parsed.message),
          statusCode: code,
        );
      }

      // Success is only accepted with BOTH credentials present. The
      // password is passed on exactly as returned (never trimmed).
      final email = parsed.data?.email?.trim();
      final returnedPassword = parsed.data?.password;
      if (email == null ||
          email.isEmpty ||
          returnedPassword == null ||
          returnedPassword.trim().isEmpty) {
        throw const AuthApiException(AuthApiFailureType.invalidResponse);
      }

      final data = parsed.data;
      return AuthCredentials(
        email: email,
        password: returnedPassword,
        userId: data?.userId,
        username: data?.username,
        userType: data?.userType,
        loginRecordId: data?.loginRecordId,
        redirectionPage: data?.redirectionPage,
      );
    } on DioException catch (e) {
      throw _fromDioException(e);
    } on AuthApiException {
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AuthApi] unexpected error: ${e.runtimeType}');
      }
      throw const AuthApiException(AuthApiFailureType.unknown);
    }
  }

  AuthApiException _fromDioException(DioException e) {
    if (kDebugMode) {
      debugPrint(
        '[AuthApi] request failed: ${e.type.name}, '
        'HTTP ${e.response?.statusCode}, '
        'inner error: ${e.error.runtimeType}',
      );
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const AuthApiException(AuthApiFailureType.timeout);

      case DioExceptionType.connectionError:
        return const AuthApiException(AuthApiFailureType.noInternet);

      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        final body = _asMap(e.response?.data);
        final message = body == null ? null : _extractMessage(body);
        return AuthApiException(
          status == null
              ? AuthApiFailureType.unknown
              : _typeForCode(status, fallback: AuthApiFailureType.unknown),
          message: message,
          statusCode: status,
        );

      case DioExceptionType.badCertificate:
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        // A raw socket failure can surface as `unknown` on some platforms.
        if (e.error.toString().contains('SocketException')) {
          return const AuthApiException(AuthApiFailureType.noInternet);
        }
        return const AuthApiException(AuthApiFailureType.unknown);
    }
  }

  AuthApiFailureType _typeForCode(
    int code, {
    required AuthApiFailureType fallback,
  }) {
    if (code == 400) return AuthApiFailureType.badRequest;
    if (code == 401) return AuthApiFailureType.unauthorized;
    if (code == 403) return AuthApiFailureType.forbidden;
    if (code == 404) return AuthApiFailureType.notFound;
    if (code >= 500 && code < 600) return AuthApiFailureType.serverError;
    return fallback;
  }

  Map<String, dynamic>? _asMap(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Only ever returns a plain string `message`-style field from the JSON
  /// body; never a stringified map/exception.
  String? _extractMessage(Map<String, dynamic> body) {
    for (final key in ['message', 'Message', 'msg', 'error']) {
      final value = body[key];
      if (value is String) {
        final cleaned = _cleanMessage(value);
        if (cleaned != null) return cleaned;
      }
    }
    return null;
  }

  String? _cleanMessage(String? raw) {
    final trimmed = raw?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}
