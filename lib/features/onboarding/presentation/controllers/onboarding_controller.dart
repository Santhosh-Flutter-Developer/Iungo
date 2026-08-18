import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/routes/app_routes.dart';
import 'package:iungo/core/services/session_service.dart';
import 'package:iungo/features/onboarding/domain/entities/user_role.dart';

class OnboardingController extends GetxController {
  final SessionService _session = Get.find<SessionService>();

  // Reflects whatever locale is already active on launch (restored from
  // storage in main()), not a hardcoded default.
  late final RxBool isEnglish =
      ((Get.locale ?? const Locale('en', 'US')).languageCode != 'ar').obs;
  final Rx<UserRole?> selectedRole = Rx<UserRole?>(null);

  void selectEnglish() {
    if (isEnglish.value) return;
    isEnglish.value = true;
    const locale = Locale('en', 'US');
    Get.updateLocale(locale);
    _session.saveLocale(locale);
  }

  void selectArabic() {
    if (!isEnglish.value) return;
    isEnglish.value = false;
    const locale = Locale('ar', 'SA');
    Get.updateLocale(locale);
    _session.saveLocale(locale);
  }

  void chooseRole(UserRole role) {
    selectedRole.value = role;
    Get.toNamed(AppRoutes.login, arguments: role);
  }
}
