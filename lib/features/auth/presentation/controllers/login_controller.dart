import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
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

      final result = await _loginUseCase(
        email: email,
        password: password,
        role: role.name,
      );
      final user = result.user;

      // The old login API was called with the email returned by the new
      // auth API, so `user.email` is that email (the typed value is only
      // a last-resort fallback).
      final sessionEmail = user.email.isNotEmpty ? user.email : email;

      final displayName = (user.name != null && user.name!.trim().isNotEmpty)
          ? user.name!.trim()
          : sessionEmail.split('@').first;

      await _session.setUser(
        name: displayName,
        email: sessionEmail,
        id: user.id,
        authToken: user.token,
      );

      // Extra profile data from the new auth API (kept for later screens,
      // e.g. PR create). The returned password is not stored.
      await _session.setAuthProfile(
        userId: result.auth.userId,
        username: result.auth.username,
        userType: result.auth.userType,
        loginRecordId: result.auth.loginRecordId,
        redirectionPage: result.auth.redirectionPage,
        addPurchaseRequest: result.auth.addPurchaseRequest,
      );

      AppSnackbar.showSuccess('logged_in_success'.tr);
      Get.offAllNamed(AppRoutes.dashboard);
    } on AuthApiException catch (e) {
      // New auth API failed — the old login API was never called.
      _debugLog('NEW auth API failed: ${e.type.name}, code ${e.statusCode}');
      AppSnackbar.showError(_authApiErrorMessage(e));
    } on AccountNotFoundException {
      _debugLog('OLD login failed: account not found');
      AppSnackbar.showError('account_not_found'.tr);
    } on AuthForbiddenException catch (e) {
      _debugLog('OLD login failed: forbidden');
      AppSnackbar.showError(e.message);
    } on AuthServerException catch (e) {
      _debugLog('OLD login failed: ${e.message}');
      AppSnackbar.showError(
        e.message.trim().isNotEmpty ? e.message : 'account_not_found'.tr,
      );
    } catch (e) {
      _debugLog('unexpected error: ${e.runtimeType}');
      AppSnackbar.showError('account_not_found'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  /// Debug-only breadcrumb showing WHICH step of the login failed. Never
  /// logs credentials or response bodies.
  void _debugLog(String message) {
    if (kDebugMode) debugPrint('[Login] $message');
  }

  /// User-facing text for a failed new-auth-API call. The server's own
  /// `message` is shown for credential/request rejections (that's the
  /// meaningful text, e.g. "Invalid credentials"); everything else gets a
  /// translated, non-technical message.
  String _authApiErrorMessage(AuthApiException e) {
    final trimmed = e.message?.trim();
    final serverMessage =
        (trimmed == null || trimmed.isEmpty) ? null : trimmed;

    switch (e.type) {
      case AuthApiFailureType.unauthorized:
      case AuthApiFailureType.rejected:
        return serverMessage ?? 'auth_invalid_credentials'.tr;
      case AuthApiFailureType.badRequest:
        return serverMessage ?? 'auth_bad_request'.tr;
      case AuthApiFailureType.forbidden:
        return serverMessage ?? 'auth_access_denied'.tr;
      case AuthApiFailureType.noInternet:
        return 'auth_no_internet'.tr;
      case AuthApiFailureType.timeout:
        return 'auth_timeout'.tr;
      case AuthApiFailureType.invalidResponse:
        return 'auth_invalid_response'.tr;
      case AuthApiFailureType.notFound:
        return 'auth_service_not_found'.tr;
      case AuthApiFailureType.serverError:
        return 'auth_server_error'.tr;
      case AuthApiFailureType.unknown:
        return 'auth_unknown_error'.tr;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
