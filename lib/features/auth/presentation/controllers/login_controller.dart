import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/routes/app_routes.dart';
import 'package:iungo/core/services/session_service.dart';
import 'package:iungo/core/utils/validators.dart';
import 'package:iungo/features/onboarding/domain/entities/user_role.dart';

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final RxBool obscurePassword = true.obs;
  final RxBool isLoading = false.obs;
  final RxnString emailError = RxnString();
  final RxnString passwordError = RxnString();

  UserRole get role =>
      (Get.arguments is UserRole) ? Get.arguments as UserRole : UserRole.tenant;

  void toggleObscurePassword() => obscurePassword.value = !obscurePassword.value;

  bool _validate() {
    emailError.value = null;
    passwordError.value = null;

    final email = emailController.text.trim();
    final password = passwordController.text;

    if (!Validators.isNotEmpty(email)) {
      emailError.value = 'email_required'.tr;
    } else if (!Validators.isValidEmail(email)) {
      emailError.value = 'email_invalid'.tr;
    }

    if (!Validators.isNotEmpty(password)) {
      passwordError.value = 'password_required'.tr;
    }

    return emailError.value == null && passwordError.value == null;
  }

  Future<void> submit() async {
    if (!_validate()) return;

    isLoading.value = true;
log("1 buddy");
    final email = emailController.text.trim();
    log("1 buddy");
    Get.find<SessionService>().setUser(
      name: email.split('@').first,
      email: email,
    );
    log("1 buddy");

    isLoading.value = false;
    Get.offAllNamed(AppRoutes.dashboard);
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
