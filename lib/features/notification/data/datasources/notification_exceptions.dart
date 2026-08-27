import 'package:dio/dio.dart';

/// Thrown by any Notification data source when an API call fails
/// (network error, non-2xx response, or an unexpected/unparseable body).
///
/// [statusCode] is the HTTP status that produced this error, when known —
/// callers can use it to react differently (e.g. force a re-login on a
/// 401/440) without having to parse [message].
class NotificationException implements Exception {
  const NotificationException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  /// True for the two "not authenticated" codes the Portal API Guide
  /// documents (§1.6) — a plain 401 and Facilio's own 440 "session
  /// expired" code.
  bool get isUnauthorized => statusCode == 401 || statusCode == 440;

  @override
  String toString() => message;
}

/// Turns a failed request into a [NotificationException] with a message
/// appropriate to the HTTP status code, per the Portal API Guide's error
/// table (§1.6):
///
///   401 / 440  Not logged in, or session expired
///   403        Logged in but the portal role has no permission
///   400        Bad parameter or malformed filters JSON
///   404        Record not found
///   429        Rate limited — back off and retry
///
/// A server-provided message (when present in the response body) always
/// takes priority over these generic ones. [fallbackMessage] is used only
/// when neither the server nor this mapping has anything more specific.
NotificationException mapNotificationError(
  Object error, {
  required String fallbackMessage,
}) {
  if (error is NotificationException) return error;

  if (error is DioException) {
    final statusCode = error.response?.statusCode;
    final body = _asMap(error.response?.data);
    final serverMessage = body != null ? _extractMessage(body) : null;

    if (serverMessage != null) {
      return NotificationException(serverMessage, statusCode: statusCode);
    }

    switch (statusCode) {
      case 401:
      case 440:
        return NotificationException(
          'Your session has expired. Please sign in again.',
          statusCode: statusCode,
        );
      case 403:
        return NotificationException(
          "You don't have permission to do this.",
          statusCode: statusCode,
        );
      case 404:
        return NotificationException(
          'This notification could not be found.',
          statusCode: statusCode,
        );
      case 429:
        return const NotificationException(
          'Too many requests. Please wait a moment and try again.',
          statusCode: 429,
        );
      default:
        return NotificationException(
          error.message ?? fallbackMessage,
          statusCode: statusCode,
        );
    }
  }

  return NotificationException(fallbackMessage);
}

Map<String, dynamic>? _asMap(dynamic raw) {
  if (raw == null) return null;
  if (raw is Map<String, dynamic>) return raw;
  return null;
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
