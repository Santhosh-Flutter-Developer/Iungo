class AccountNotFoundException implements Exception {
  const AccountNotFoundException([this.message = 'Account not found']);
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
