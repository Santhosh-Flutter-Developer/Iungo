import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/routes/app_routes.dart';
import 'package:iungo/features/onboarding/domain/entities/user_role.dart';

class OnboardingController extends GetxController {
  final RxBool isEnglish = true.obs;
  final Rx<UserRole?> selectedRole = Rx<UserRole?>(null);

  void selectEnglish() {
    if (isEnglish.value) return;
    isEnglish.value = true;
    Get.updateLocale(const Locale('en', 'US'));
  }

  void selectArabic() {
    if (!isEnglish.value) return;
    isEnglish.value = false;
    Get.updateLocale(const Locale('ar', 'SA'));
  }

  void chooseRole(UserRole role) {
    selectedRole.value = role;
    Get.toNamed(AppRoutes.login, arguments: role);
  }
}