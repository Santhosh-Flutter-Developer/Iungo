/// Response of `GET https://iungo.citgroupltd.com/api/auth.php`:
///
///   {
///     "code": 200,
///     "data": {
///       "user_id": "...", "username": "...", "password": "...",
///       "email": "...", "user_type": "employee",
///       "login_record_id": 3784, "redirection_page": "home.php",
///       "add_purchase_request": 1
///     },
///     "message": "Login Successfully"
///   }
///
/// Parsing is deliberately forgiving about *types* (e.g. `code` as `"200"`,
/// `data` as an empty list, which is how PHP serialises an empty array) so
/// a malformed response degrades to "missing field" instead of throwing.
/// Whether the response is *acceptable* is decided by the data source.
///
/// No `toString` / `toJson` on purpose: [AuthApiDataModel] carries a
/// plaintext password that must never end up in logs.
class AuthApiResponseModel {
  const AuthApiResponseModel({this.code, this.message, this.data});

  final int? code;
  final String? message;
  final AuthApiDataModel? data;

  factory AuthApiResponseModel.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return AuthApiResponseModel(
      code: _readInt(json['code']),
      message: _readString(json['message']),
      data: rawData is Map
          ? AuthApiDataModel.fromJson(
              Map<String, dynamic>.from(rawData),
              // Tolerate the flag sitting beside `data` instead of in it.
              fallbackAddPurchaseRequest: json['add_purchase_request'],
            )
          : null,
    );
  }
}

class AuthApiDataModel {
  const AuthApiDataModel({
    this.userId,
    this.username,
    this.email,
    this.password,
    this.userType,
    this.loginRecordId,
    this.redirectionPage,
    this.addPurchaseRequest,
  });

  final String? userId;
  final String? username;
  final String? email;
  final String? password;
  final String? userType;
  final int? loginRecordId;
  final String? redirectionPage;

  /// `add_purchase_request`: `true` for `1` (Requestor), `false` for `0`
  /// (Approver), `null` when absent or not a recognisable 1/0.
  final bool? addPurchaseRequest;

  factory AuthApiDataModel.fromJson(
    Map<String, dynamic> json, {
    dynamic fallbackAddPurchaseRequest,
  }) {
    return AuthApiDataModel(
      userId: _readString(json['user_id']),
      username: _readString(json['username']),
      email: _readString(json['email']),
      password: _readString(json['password']),
      userType: _readString(json['user_type']),
      loginRecordId: _readInt(json['login_record_id']),
      redirectionPage: _readString(json['redirection_page']),
      addPurchaseRequest: _readFlag(
        json.containsKey('add_purchase_request')
            ? json['add_purchase_request']
            : fallbackAddPurchaseRequest,
      ),
    );
  }
}

String? _readString(dynamic value) => value?.toString();

/// PHP may send the flag as `1`, `"1"` or `true`; anything that isn't a
/// clear 1/0 is treated as unknown rather than guessed.
bool? _readFlag(dynamic value) {
  if (value is bool) return value;
  final number =
      value is num ? value : num.tryParse(value?.toString().trim() ?? '');
  if (number == 1) return true;
  if (number == 0) return false;
  return null;
}

int? _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}
