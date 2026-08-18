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
