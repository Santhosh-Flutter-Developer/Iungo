import 'dart:convert';

import 'package:dio/dio.dart';

/// Why a Create Purchase Request API call failed. Kept as a type (not a
/// hard-coded English string) so the UI can show a translated message.
enum PrCreateFailure {
  /// No connectivity / server unreachable.
  noInternet,

  /// Connect / send / receive timeout.
  timeout,

  /// Missing/expired session or token (HTTP 401/440, body `code` 401/440,
  /// or no stored user id / bearer token to send in the first place).
  unauthorized,

  /// HTTP 403 (or body `code` 403).
  forbidden,

  /// The body wasn't valid JSON or lacked a field the app depends on.
  invalidResponse,

  /// HTTP 5xx.
  server,

  /// The API answered but refused the request (4xx / non-success `code`).
  /// [PrCreateException.message] is the server's own explanation, if any.
  rejected,

  /// The request was cancelled by the app (e.g. attachment removed
  /// mid-upload). Never surfaced to the user.
  cancelled,

  /// Anything unexpected.
  unknown,
}

/// Thrown by every Create-PR data source. [message] is only ever the
/// server's own JSON `message` field — never a raw exception string.
class PrCreateException implements Exception {
  const PrCreateException(this.type, {this.message, this.statusCode});

  final PrCreateFailure type;
  final String? message;
  final int? statusCode;

  bool get isUnauthorized => type == PrCreateFailure.unauthorized;
  bool get isCancelled => type == PrCreateFailure.cancelled;

  @override
  String toString() => 'PrCreateException(${type.name}, status: $statusCode)';
}

/// Decodes a response body into a JSON object. Handles a body that
/// arrives as a `String` (PHP endpoints often reply with a non-JSON
/// content-type, so Dio doesn't auto-decode). Returns `null` for
/// anything that isn't a JSON object.
Map<String, dynamic>? prAsJsonMap(dynamic raw) {
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

/// The server's human-readable explanation, when the body carries one.
String? prServerMessage(Map<String, dynamic>? body) {
  if (body == null) return null;
  for (final key in const ['message', 'Message', 'msg', 'error']) {
    final value = body[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return null;
}

int? _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

/// Validates the application-level `code` of an `iungo.citgroupltd.com`
/// response (`{"code": 200, "data": ..., "message": ...}`). Some
/// backends answer HTTP 200 with a failure `code` in the body, so the
/// HTTP status alone isn't enough. Throws [PrCreateException] unless the
/// code is a success (200/201).
void prEnsureApiSuccess(Map<String, dynamic> body) {
  final code = _readInt(body['code']);
  if (code == null) {
    throw const PrCreateException(PrCreateFailure.invalidResponse);
  }
  if (code == 200 || code == 201) return;

  final message = prServerMessage(body);
  if (code == 401 || code == 440) {
    throw PrCreateException(
      PrCreateFailure.unauthorized,
      message: message,
      statusCode: code,
    );
  }
  if (code == 403) {
    throw PrCreateException(
      PrCreateFailure.forbidden,
      message: message,
      statusCode: code,
    );
  }
  throw PrCreateException(
    code >= 500 ? PrCreateFailure.server : PrCreateFailure.rejected,
    message: message,
    statusCode: code,
  );
}

/// Turns any [DioException] into a [PrCreateException]. Written as an
/// if-chain (not an exhaustive `switch`) so it doesn't depend on which
/// [DioExceptionType] members the locked Dio version has.
PrCreateException mapPrDioError(DioException e) {
  final type = e.type;

  if (type == DioExceptionType.connectionTimeout ||
      type == DioExceptionType.sendTimeout ||
      type == DioExceptionType.receiveTimeout) {
    return const PrCreateException(PrCreateFailure.timeout);
  }
  if (type == DioExceptionType.cancel) {
    return const PrCreateException(PrCreateFailure.cancelled);
  }
  if (type == DioExceptionType.connectionError) {
    return const PrCreateException(PrCreateFailure.noInternet);
  }
  if (type == DioExceptionType.badResponse) {
    final status = e.response?.statusCode;
    final message = prServerMessage(prAsJsonMap(e.response?.data));
    if (status == 401 || status == 440) {
      return PrCreateException(
        PrCreateFailure.unauthorized,
        message: message,
        statusCode: status,
      );
    }
    if (status == 403) {
      return PrCreateException(
        PrCreateFailure.forbidden,
        message: message,
        statusCode: status,
      );
    }
    if (status != null && status >= 500) {
      return PrCreateException(
        PrCreateFailure.server,
        message: message,
        statusCode: status,
      );
    }
    return PrCreateException(
      PrCreateFailure.rejected,
      message: message,
      statusCode: status,
    );
  }
  // A raw socket failure can surface as `unknown` on some platforms.
  if (e.error.toString().contains('SocketException')) {
    return const PrCreateException(PrCreateFailure.noInternet);
  }
  return const PrCreateException(PrCreateFailure.unknown);
}
