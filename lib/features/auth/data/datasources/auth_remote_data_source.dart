import 'dart:convert';

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

/// Talks to the Iungo login API:
///
///   GET https://citgroup.facilioclients.com/api/integ/apilogin
///
/// with a JSON body of `{ "username": ..., "password": ... }` under
/// `Content-Type: application/json`. Confirmed against the real server
/// via Postman with this exact header/body shape (200 OK, response
/// `{ "jsonresponse": { "authtoken": ..., "username": ... } }`).
///
/// Built on `dio`, not `package:http`: on Flutter Web, `package:http`
/// uses the browser's Fetch API, which *forbids* a body on a GET
/// request outright — it throws a client-side `ClientException`
/// ("Request with GET/HEAD method cannot have body") before any network
/// call is even attempted. Dio's web adapter uses the older
/// `XMLHttpRequest` API instead, which does allow a body on GET, so it
/// can actually reach the network (where CORS/server behaviour then
/// applies — see the note on [AuthForbiddenException] below and the
/// accompanying chat explanation for why Flutter Web may still be
/// unable to reach this endpoint).
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  static const _loginUrl =
      'https://citgroup.facilioclients.com/api/integ/apilogin';

  @override
  Future<AuthUserModel> login({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await _dio.request<dynamic>(
        _loginUrl,
        data: {
          'username': email,
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
        throw const AuthServerException('Unexpected response from server');
      }

      if (_isFailure(body)) {
        final message = _extractMessage(body);
        if (message != null) {
          throw AuthServerException(message);
        }
        throw const AccountNotFoundException();
      }

      return AuthUserModel.fromJson(body, fallbackEmail: email);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw const AccountNotFoundException();
      }

      final errorBody = _asMap(e.response?.data);
      final message = errorBody != null ? _extractMessage(errorBody) : null;

      if (e.response?.statusCode == 403) {
        // A 403 with no app-level error body (no `message`/`error` field)
        // is very unlikely to be "wrong credentials" — real login
        // rejections normally come back with a JSON body explaining why.
        // A bare 403 like this is the signature of something blocking
        // the request before it reaches the login logic (a gateway/WAF,
        // or — on Web specifically — the browser's own CORS enforcement
        // rejecting the preflight).
        throw message != null
            ? AuthServerException(message)
            : const AuthForbiddenException();
      }

      throw AuthServerException(message ?? e.message ?? 'Something went wrong');
    } on AccountNotFoundException {
      rethrow;
    } on AuthForbiddenException {
      rethrow;
    } on AuthServerException {
      rethrow;
    } catch (_) {
      throw const AuthServerException('Something went wrong');
    }
  }

  Map<String, dynamic>? _asMap(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map<String, dynamic>) return raw;
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// The API's failure shape isn't fully documented beyond the observed
  /// success shape, so this also checks a handful of common failure
  /// conventions: an explicit `success: false`, a `status` field that
  /// reads as an error, or a populated `error` field.
  bool _isFailure(Map<String, dynamic> body) {
    final success = body['success'] ?? body['Success'];
    if (success is bool && success == false) return true;

    final status = body['status'] ?? body['Status'];
    if (status != null) {
      final normalized = status.toString().trim().toLowerCase();
      if (['false', 'error', 'fail', 'failed', 'failure', '0']
          .contains(normalized)) {
        return true;
      }
    }

    final error = body['error'] ?? body['Error'];
    if (error != null && error.toString().trim().isNotEmpty) return true;

    return false;
  }

  String? _extractMessage(Map<String, dynamic> body) {
    for (final key in ['message', 'Message', 'error', 'Error', 'msg']) {
      final value = body[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return null;
  }
}
