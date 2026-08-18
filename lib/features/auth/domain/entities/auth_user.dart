import 'package:equatable/equatable.dart';

class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.email,
    required this.token,
    required this.role,
    this.name,
  });

  final String id;
  final String email;
  final String token;
  final String role;

  /// Display name, when the API returns one. Falls back to the local
  /// part of the email in the UI when absent.
  final String? name;

  @override
  List<Object?> get props => [id, email, token, role, name];
}
