import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central place for everything that must survive an app restart:
/// the logged-in session (token/user info) and the user's chosen
/// language. Backed by [SharedPreferences] — the project's existing
/// declared local-storage dependency.
class SessionService extends GetxService {
  static const _keyIsLoggedIn = 'auth_is_logged_in';
  static const _keyToken = 'auth_token';
  static const _keyUserId = 'auth_user_id';
  static const _keyUserName = 'auth_user_name';
  static const _keyUserEmail = 'auth_user_email';
  static const _keyAuthUserId = 'auth_portal_user_id';
  static const _keyAuthUsername = 'auth_portal_username';
  static const _keyUserType = 'auth_user_type';
  static const _keyLoginRecordId = 'auth_login_record_id';
  static const _keyRedirectionPage = 'auth_redirection_page';
  static const _keyLanguageCode = 'app_language_code';
  static const _keyCountryCode = 'app_country_code';

  final Rx<String?> userName = Rx<String?>(null);
  final Rx<String?> userEmail = Rx<String?>(null);
  final Rx<String?> userId = Rx<String?>(null);
  final Rx<String?> token = Rx<String?>(null);
  final RxBool isLoggedIn = false.obs;

  // Extra profile data returned by the new auth API (auth.php). The
  // password returned by that API is deliberately never stored.
  final Rx<String?> authUserId = Rx<String?>(null);
  final Rx<String?> authUsername = Rx<String?>(null);
  final Rx<String?> userType = Rx<String?>(null);
  final Rx<int?> loginRecordId = Rx<int?>(null);
  final Rx<String?> redirectionPage = Rx<String?>(null);

  late final SharedPreferences _prefs;

  /// Loads any persisted session/language before the first frame is
  /// drawn. Must be awaited in `main()` (via `Get.putAsync`) so the
  /// splash screen can decide Dashboard-vs-Onboarding synchronously.
  Future<SessionService> init() async {
    _prefs = await SharedPreferences.getInstance();

    isLoggedIn.value = _prefs.getBool(_keyIsLoggedIn) ?? false;
    token.value = _prefs.getString(_keyToken);
    userId.value = _prefs.getString(_keyUserId);
    userName.value = _prefs.getString(_keyUserName);
    userEmail.value = _prefs.getString(_keyUserEmail);
    authUserId.value = _prefs.getString(_keyAuthUserId);
    authUsername.value = _prefs.getString(_keyAuthUsername);
    userType.value = _prefs.getString(_keyUserType);
    loginRecordId.value = _prefs.getInt(_keyLoginRecordId);
    redirectionPage.value = _prefs.getString(_keyRedirectionPage);

    return this;
  }

  /// Persists the session after a successful login and updates the
  /// in-memory/reactive state used across the app (drawer header,
  /// profile screen, etc.).
  Future<void> setUser({
    required String name,
    required String email,
    String? id,
    String? authToken,
  }) async {
    userName.value = name;
    userEmail.value = email;
    userId.value = id;
    token.value = authToken;
    isLoggedIn.value = true;

    await _prefs.setBool(_keyIsLoggedIn, true);
    await _prefs.setString(_keyUserName, name);
    await _prefs.setString(_keyUserEmail, email);
    await _prefs.setString(_keyUserId, id ?? '');
    await _prefs.setString(_keyToken, authToken ?? '');
  }

  /// Persists the extra profile fields returned by the new auth API
  /// (`auth.php`) so other features (e.g. PR create) can use them later.
  Future<void> setAuthProfile({
    String? userId,
    String? username,
    String? userType,
    int? loginRecordId,
    String? redirectionPage,
  }) async {
    authUserId.value = userId;
    authUsername.value = username;
    this.userType.value = userType;
    this.loginRecordId.value = loginRecordId;
    this.redirectionPage.value = redirectionPage;

    await _setOrRemoveString(_keyAuthUserId, userId);
    await _setOrRemoveString(_keyAuthUsername, username);
    await _setOrRemoveString(_keyUserType, userType);
    await _setOrRemoveString(_keyRedirectionPage, redirectionPage);
    if (loginRecordId == null) {
      await _prefs.remove(_keyLoginRecordId);
    } else {
      await _prefs.setInt(_keyLoginRecordId, loginRecordId);
    }
  }

  Future<void> _setOrRemoveString(String key, String? value) {
    return (value == null || value.isEmpty)
        ? _prefs.remove(key)
        : _prefs.setString(key, value);
  }

  /// Clears the session on sign-out, both in memory and on disk.
  Future<void> clear() async {
    userName.value = null;
    userEmail.value = null;
    userId.value = null;
    token.value = null;
    isLoggedIn.value = false;
    authUserId.value = null;
    authUsername.value = null;
    userType.value = null;
    loginRecordId.value = null;
    redirectionPage.value = null;

    await _prefs.remove(_keyAuthUserId);
    await _prefs.remove(_keyAuthUsername);
    await _prefs.remove(_keyUserType);
    await _prefs.remove(_keyLoginRecordId);
    await _prefs.remove(_keyRedirectionPage);
    await _prefs.remove(_keyIsLoggedIn);
    await _prefs.remove(_keyToken);
    await _prefs.remove(_keyUserId);
    await _prefs.remove(_keyUserName);
    await _prefs.remove(_keyUserEmail);
  }

  // ---- Language persistence -------------------------------------------

  /// The language saved from a previous session, or `null` on a fresh
  /// install (in which case the app falls back to its default locale).
  Locale? get savedLocale {
    final code = _prefs.getString(_keyLanguageCode);
    if (code == null || code.isEmpty) return null;
    final country = _prefs.getString(_keyCountryCode);
    return Locale(code, (country == null || country.isEmpty) ? null : country);
  }

  Future<void> saveLocale(Locale locale) async {
    await _prefs.setString(_keyLanguageCode, locale.languageCode);
    await _prefs.setString(_keyCountryCode, locale.countryCode ?? '');
  }
}
