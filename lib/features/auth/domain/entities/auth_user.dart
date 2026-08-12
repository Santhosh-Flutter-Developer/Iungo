import 'package:equatable/equatable.dart';

class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.email,
    required this.token,
    required this.role,
  });

  final String id;
  final String email;
  final String token;
  final String role;

  @override
  List<Object?> get props => [id, email, token, role];
}
