import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/routes/app_routes.dart';
import 'package:iungo/core/utils/validators.dart';
import 'package:iungo/core/widgets/app_snackbar.dart';
import 'package:iungo/features/auth/data/datasources/auth_exceptions.dart';
import 'package:iungo/features/auth/domain/usecases/login_usecase.dart';
import 'package:iungo/features/onboarding/domain/entities/user_role.dart';

class LoginController extends GetxController {
  LoginController(this._loginUseCase);

  final LoginUseCase _loginUseCase; 

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
    try {
      // await _loginUseCase(
      //   email: emailController.text.trim(),
      //   password: passwordController.text,
      //   role: role.name,
      // );
      // Authenticated successfully — hook up navigation to the app's
      // home/dashboard route here.
      //  Get.offAllNamed(AppRoutes.home, arguments: role);
      Get.snackbar('', 'Signed in successfully');
    } on AccountNotFoundException {
      AppSnackbar.showError('account_not_found'.tr);
    } on AuthServerException catch (e) {
      AppSnackbar.showError(e.message);
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
