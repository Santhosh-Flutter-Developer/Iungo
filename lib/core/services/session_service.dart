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
  static const _keyLanguageCode = 'app_language_code';
  static const _keyCountryCode = 'app_country_code';

  final Rx<String?> userName = Rx<String?>(null);
  final Rx<String?> userEmail = Rx<String?>(null);
  final Rx<String?> userId = Rx<String?>(null);
  final Rx<String?> token = Rx<String?>(null);
  final RxBool isLoggedIn = false.obs;

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

  /// Clears the session on sign-out, both in memory and on disk.
  Future<void> clear() async {
    userName.value = null;
    userEmail.value = null;
    userId.value = null;
    token.value = null;
    isLoggedIn.value = false;

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
