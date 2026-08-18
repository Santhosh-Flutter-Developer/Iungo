import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/routes/app_routes.dart';
import 'package:iungo/core/services/session_service.dart';
import 'package:iungo/core/utils/validators.dart';
import 'package:iungo/core/widgets/app_snackbar.dart';
import 'package:iungo/features/auth/data/datasources/auth_exceptions.dart';
import 'package:iungo/features/auth/domain/usecases/login_usecase.dart';
import 'package:iungo/features/onboarding/domain/entities/user_role.dart';

class LoginController extends GetxController {
  LoginController(this._loginUseCase, this._session);

  final LoginUseCase _loginUseCase;
  final SessionService _session;

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
    if (isLoading.value) return;
    if (!_validate()) return;

    isLoading.value = true;
    try {
      final email = emailController.text.trim();
      final password = passwordController.text;

      final user = await _loginUseCase(
        email: email,
        password: password,
        role: role.name,
      );

      final displayName = (user.name != null && user.name!.trim().isNotEmpty)
          ? user.name!.trim()
          : email.split('@').first;

      await _session.setUser(
        name: displayName,
        email: user.email.isNotEmpty ? user.email : email,
        id: user.id,
        authToken: user.token,
      );

      AppSnackbar.showSuccess('logged_in_success'.tr);
      Get.offAllNamed(AppRoutes.dashboard);
    } on AccountNotFoundException {
      AppSnackbar.showError('account_not_found'.tr);
    } on AuthForbiddenException catch (e) {
      AppSnackbar.showError(e.message);
    } on AuthServerException catch (e) {
      AppSnackbar.showError(
        e.message.trim().isNotEmpty ? e.message : 'account_not_found'.tr,
      );
    } catch (_) {
      AppSnackbar.showError('account_not_found'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
