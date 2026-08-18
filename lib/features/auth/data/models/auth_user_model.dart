import 'package:iungo/features/auth/domain/entities/auth_user.dart';

class AuthUserModel extends AuthUser {
  const AuthUserModel({
    required super.id,
    required super.email,
    required super.token,
    required super.role,
    super.name,
  });

  /// The confirmed real success shape (verified via Postman) is:
  ///   { "jsonresponse": { "authtoken": "...", "username": "..." } }
  /// This still checks a few other common wrapper/field spellings as a
  /// safety net in case the shape varies by account/role.
  factory AuthUserModel.fromJson(
    Map<String, dynamic> json, {
    String? fallbackEmail,
  }) {
    Map<String, dynamic> user = json;
    for (final key in [
      'jsonresponse',
      'JsonResponse',
      'data',
      'Data',
      'result',
      'Result',
      'user',
      'User',
    ]) {
      final nested = json[key];
      if (nested is Map<String, dynamic>) {
        user = nested;
        break;
      }
    }

    String? read(List<String> keys) {
      for (final key in keys) {
        final value = user[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString();
        }
      }
      return null;
    }

    return AuthUserModel(
      id: read(['id', 'Id', 'ID', 'userId', 'user_id']) ?? '',
      email: read(['email', 'Email', 'username', 'userName', 'user_name']) ??
          fallbackEmail ??
          '',
      token: read([
            'authtoken',
            'authToken',
            'token',
            'Token',
            'access_token',
            'accessToken',
            'sessionId',
            'session_id',
          ]) ??
          '',
      role: read(['role', 'Role', 'userType', 'user_type']) ?? '',
      name: read([
        'name',
        'Name',
        'fullName',
        'full_name',
        'displayName',
        'display_name',
      ]),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'token': token,
        'role': role,
        'name': name,
      };
}
