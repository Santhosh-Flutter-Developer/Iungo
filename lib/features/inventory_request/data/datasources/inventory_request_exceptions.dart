import 'package:dio/dio.dart';

/// Thrown by any Inventory Request data source when an API call fails
/// (network error, non-2xx response, or an unexpected/unparseable body).
///
/// [statusCode] is the HTTP status that produced this error, when known —
/// callers can use it to react differently (e.g. force a re-login on a
/// 401/440) without having to parse [message]. Mirrors
/// [WorkOrderException]/[ServiceRequestException] exactly.
class InventoryRequestException implements Exception {
  const InventoryRequestException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  /// True for the two "not authenticated" codes the Portal API Guide
  /// documents (§1.6) — a plain 401 and Facilio's own 440 "session
  /// expired" code.
  bool get isUnauthorized => statusCode == 401 || statusCode == 440;

  @override
  String toString() => message;
}

/// Turns a failed request into an [InventoryRequestException] with a
/// message appropriate to the HTTP status code, per the Portal API
/// Guide's error table (§1.6):
///
///   401 / 440  Not logged in, or session expired
///   403        Logged in but the portal role has no permission
///   400        Bad parameter or malformed filters JSON
///   404        Record not found, or not under the given parent record
///   422        Validation error
///   429        Rate limited — back off and retry
///   500        Server error
///
/// A server-provided message (when present in the response body) always
/// takes priority over these generic ones. [fallbackMessage] is used only
/// when neither the server nor this mapping has anything more specific.
InventoryRequestException mapInventoryRequestError(
  Object error, {
  required String fallbackMessage,
}) {
  if (error is InventoryRequestException) return error;

  if (error is DioException) {
    final statusCode = error.response?.statusCode;
    final body = _asMap(error.response?.data);
    final serverMessage = body != null ? _extractMessage(body) : null;

    if (serverMessage != null) {
      return InventoryRequestException(serverMessage, statusCode: statusCode);
    }

    switch (statusCode) {
      case 400:
        return InventoryRequestException(
          'The request was invalid. Please try again.',
          statusCode: statusCode,
        );
      case 401:
      case 440:
        return InventoryRequestException(
          'Your session has expired. Please sign in again.',
          statusCode: statusCode,
        );
      case 403:
        return InventoryRequestException(
          "You don't have permission to do this.",
          statusCode: statusCode,
        );
      case 404:
        return InventoryRequestException(
          'This inventory request could not be found.',
          statusCode: statusCode,
        );
      case 422:
        return InventoryRequestException(
          'This request could not be processed. Please check your input.',
          statusCode: statusCode,
        );
      case 429:
        return const InventoryRequestException(
          'Too many requests. Please wait a moment and try again.',
          statusCode: 429,
        );
      case 500:
        return InventoryRequestException(
          'Something went wrong on the server. Please try again later.',
          statusCode: statusCode,
        );
      default:
        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.sendTimeout ||
            error.type == DioExceptionType.receiveTimeout) {
          return const InventoryRequestException(
            'The request timed out. Please check your connection and try again.',
          );
        }
        if (error.type == DioExceptionType.connectionError) {
          return const InventoryRequestException(
            'No internet connection. Please check your network and try again.',
          );
        }
        return InventoryRequestException(
          error.message ?? fallbackMessage,
          statusCode: statusCode,
        );
    }
  }

  return InventoryRequestException(fallbackMessage);
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
