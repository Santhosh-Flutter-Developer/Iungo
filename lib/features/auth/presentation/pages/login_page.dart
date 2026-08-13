import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/core/routes/app_routes.dart';
import 'package:iungo/core/widgets/app_text_field.dart';
import 'package:iungo/core/widgets/primary_button.dart';
import 'package:iungo/features/auth/presentation/controllers/login_controller.dart';

class LoginPage extends GetView<LoginController> {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return  Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(isRtl ? Icons.arrow_forward : Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'welcome'.tr,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w600,
                  color: AppColors.headingBlueGrey,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'enter_credentials'.tr,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.headingBlueGrey,
                ),
              ),
              const SizedBox(height: 28),
              Obx(
                () => AppTextField(
                  label: 'enter_email_label'.tr,
                  hint: 'enter_email_hint'.tr,
                  controller: controller.emailController,
                  prefixIcon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  errorText: controller.emailError.value,
                ),
              ),
              const SizedBox(height: 20),
              Obx(
                () => AppTextField(
                  label: 'password_label'.tr,
                  hint: 'enter_password_hint'.tr,
                  controller: controller.passwordController,
                  prefixIcon: Icons.lock_outline,
                  obscureText: controller.obscurePassword.value,
                  errorText: controller.passwordError.value,
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.obscurePassword.value
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.inputIcon,
                    ),
                    onPressed: controller.toggleObscurePassword,
                  ),
                ),
              ),
              const SizedBox(height: 36),
              Obx(
                () => PrimaryButton(
                  label: 'sign_in'.tr,
                  isLoading: controller.isLoading.value,
                  onPressed: controller.submit,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                children: [
                  Text(
                    'agree_prefix'.tr,
                    style: const TextStyle(
                      fontSize: 13,
                      
                      color: AppColors.textMuted,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Get.toNamed(AppRoutes.privacyPolicy),
                    child: Text(
                      'privacy_policy'.tr,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.link,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
