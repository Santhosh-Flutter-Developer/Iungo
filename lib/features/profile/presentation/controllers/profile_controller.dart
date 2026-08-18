import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/services/session_service.dart';

/// Drives the "Profile" screen reached from the drawer. Exposes the
/// session's name/email, the current language's native display name, and
/// the (in-memory only) push-notifications toggle.
class ProfileController extends GetxController {
  ProfileController(this._session);

  final SessionService _session;

  String? get userName => _session.userName.value;
  String? get userEmail => _session.userEmail.value;

  final RxBool pushNotificationsEnabled = true.obs;

  /// Native-script display name for the language currently applied to
  /// the whole app (e.g. "English" or "عربي") — shown as the read-only
  /// value under the "Language" row.
  String get currentLanguageLabel {
    final isArabic = Get.locale?.languageCode == 'ar';
    return (isArabic ? 'language_arabic_native' : 'language_english_native')
        .tr;
  }

  bool get isArabicSelected => Get.locale?.languageCode == 'ar';

  void togglePushNotifications() {
    pushNotificationsEnabled.value = !pushNotificationsEnabled.value;
  }

  /// Applies a newly chosen locale app-wide (mirrors the whole UI —
  /// same mechanism used from onboarding's language toggle) and
  /// persists it so it is restored on the next app launch.
  void applyLocale(Locale locale) {
    Get.updateLocale(locale);
    _session.saveLocale(locale);
  }
}
