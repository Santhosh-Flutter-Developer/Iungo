import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/core/widgets/language_toggle.dart';
import 'package:iungo/features/onboarding/domain/entities/user_role.dart';
import 'package:iungo/features/onboarding/presentation/controllers/onboarding_controller.dart';

class OnboardingPage extends StatelessWidget {
  OnboardingPage({super.key});

  final controller = Get.isRegistered<OnboardingController>()
      ? Get.find<OnboardingController>()
      : Get.put(OnboardingController());

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: AppColors.scaffoldWhite,
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 24.0),
                Text(
                  'welcome'.tr,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w600,
                    color: AppColors.headingBlueGrey,
                  ),
                ),
                Image.asset(
                  'assets/images/png/ic_logo.png',
                  width: width * 0.9,
                  height: width * 0.9 * 0.75,
                  fit: BoxFit.cover,
                ),
                Text(
                  'app_name'.tr,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'powered_by'.tr,
                  style: TextStyle(fontSize: 15, color: AppColors.textMuted),
                ),
                Spacer(),
                Obx(
                  () => LanguageToggle(
                    isEnglishSelected: controller.isEnglish.value,
                    onEnglishTap: controller.selectEnglish,
                    onArabicTap: controller.selectArabic,
                  ),
                ),
                const SizedBox(height: 48),
                 Spacer(),
                // Text(
                //   'which_one_are_you'.tr,
                //   style: const TextStyle(
                //     fontSize: 17,
                //     fontWeight: FontWeight.w600,
                //     color: AppColors.headingBlueGrey,
                //   ),
                // ),
                // const SizedBox(height: 20),
                // SizedBox(
                //   width: double.infinity,
                //   height: 52,
                //   child: ElevatedButton(
                //     onPressed: () {
                //       // controller.chooseRole(UserRole.tenant);
                //     },
                //     style: ElevatedButton.styleFrom(
                //       backgroundColor: AppColors.primary,
                //       foregroundColor: AppColors.white,
                //       elevation: 0,
                //       shape: RoundedRectangleBorder(
                //         borderRadius: BorderRadius.circular(6),
                //       ),
                //     ),
                //     child: Text(
                //       'tenant'.tr,
                //       style: const TextStyle(
                //         fontSize: 16,
                //         fontWeight: FontWeight.w600,
                //       ),
                //     ),
                //   ),
                // ),
                // const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => controller.chooseRole(UserRole.client),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      'client'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
