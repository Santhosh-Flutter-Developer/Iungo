class AccountNotFoundException implements Exception {
  const AccountNotFoundException([this.message = 'Account not found']);
  final String message;

  @override
  String toString() => message;
}

/// Thrown when the server returns 403 with no usable error body — this
/// shape (empty body, no app-level JSON) typically means a gateway/WAF
/// in front of the API rejected the request outright (e.g. blocking
/// requests that carry a browser `Origin` header), rather than the
/// login itself being rejected for bad credentials. Surfaced separately
/// from [AuthServerException] so the UI/logs don't conflate "wrong
/// password" with "this client isn't allowed to call the API at all".
class AuthForbiddenException implements Exception {
  const AuthForbiddenException([
    this.message =
        'Access to the login service was denied (403). This usually means '
        'the server is blocking requests from this origin — it is not a '
        'wrong username/password.',
  ]);
  final String message;

  @override
  String toString() => message;
}

/// Thrown for any other network / server failure during authentication.
class AuthServerException implements Exception {
  const AuthServerException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Why the *new* authentication API (`auth.php`) call failed. Kept as a
/// type (rather than a hard-coded English string) so the UI can show a
/// translated message for each case.
enum AuthApiFailureType {
  /// No connectivity / server unreachable.
  noInternet,

  /// Connect / send / receive timeout.
  timeout,

  /// Response wasn't JSON, or `code` / `data.email` / `data.password`
  /// were missing or empty.
  invalidResponse,

  /// HTTP 400 (or body `code` 400).
  badRequest,

  /// HTTP 401 (or body `code` 401) — typically wrong credentials.
  unauthorized,

  /// HTTP 403 (or body `code` 403).
  forbidden,

  /// HTTP 404 (or body `code` 404).
  notFound,

  /// HTTP 5xx (500 / 502 / 503 / ...).
  serverError,

  /// Any other non-success application `code` (e.g. 422).
  rejected,

  /// Anything unexpected.
  unknown,
}

/// Thrown by the new authentication API. When this is thrown the old
/// login API is never called.
///
/// [message] is only ever the server's own JSON `message` field (never a
/// raw exception string), and it never contains credentials.
class AuthApiException implements Exception {
  const AuthApiException(this.type, {this.message, this.statusCode});

  final AuthApiFailureType type;
  final String? message;
  final int? statusCode;

  @override
  String toString() => 'AuthApiException(${type.name}, status: $statusCode)';
}
