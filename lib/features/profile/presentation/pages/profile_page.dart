import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/features/profile/presentation/controllers/profile_controller.dart';
import 'package:iungo/features/profile/presentation/widgets/language_bottom_sheet.dart';

/// "Profile" screen reached from the drawer. Purple app bar, then four
/// rows on a light-grey background: Name, Email, Language (with a pencil
/// that opens the language bottom sheet), and — below a divider — Push
/// Notifications with a green toggle circle.
class ProfilePage extends GetView<ProfileController> {
  const ProfilePage({super.key});

  Future<void> _openLanguageSheet(BuildContext context) async {
    final result = await showLanguageBottomSheet(
      context,
      currentLocale: Get.locale ?? const Locale('en', 'US'),
    );
    if (result != null) {
      controller.applyLocale(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'profile'.tr,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileRow(
                icon: Icons.person_outline,
                label: 'name'.tr,
                value: controller.userName ?? '',
              ),
              const SizedBox(height: 30),
              _ProfileRow(
                icon: Icons.email_outlined,
                label: 'email'.tr,
                value: controller.userEmail ?? '',
              ),
              const SizedBox(height: 30),
            _ProfileRow(
                  icon: Icons.language,
                  label: 'language'.tr,
                  value: controller.currentLanguageLabel,
                  trailing: InkWell(
                    onTap: () => _openLanguageSheet(context),
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.edit_outlined,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              
              const SizedBox(height: 24),
              const Divider(color: AppColors.divider, height: 1, thickness: 1),
              const SizedBox(height: 24),
              Obx(
                () => _ProfileRow(
                  icon: Icons.notifications_none,
                  label: 'push_notifications'.tr,
                  value: 'push_notifications_description'.tr,
                  valueMaxLines: 2,
                  trailing: InkWell(
                    onTap: controller.togglePushNotifications,
                    customBorder: const CircleBorder(),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: _NotificationToggle(
                        enabled: controller.pushNotificationsEnabled.value,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
    this.valueMaxLines = 1,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;
  final int valueMaxLines;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 24, color: AppColors.profileIconGrey),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.inputIcon,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: valueMaxLines,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textDark,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class _NotificationToggle extends StatelessWidget {
  const _NotificationToggle({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (enabled) {
      return const CircleAvatar(
        radius: 13,
        backgroundColor: AppColors.toggleOnGreen,
        child: Icon(Icons.check, size: 16, color: AppColors.white),
      );
    }
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.divider, width: 1.6),
      ),
    );
  }
}
