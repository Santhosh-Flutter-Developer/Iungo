import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/core/routes/app_routes.dart';
import 'package:iungo/core/services/session_service.dart';

enum DrawerMenuItem {
  dashboard,
  myServiceRequests,
  myWorkOrders,
  feedback,
  profile,
  about,
}

extension _DrawerMenuItemX on DrawerMenuItem {
  IconData get icon {
    switch (this) {
      case DrawerMenuItem.dashboard:
        return Icons.home_outlined;
      case DrawerMenuItem.myServiceRequests:
        return Icons.assignment_turned_in_outlined;
      case DrawerMenuItem.myWorkOrders:
        return Icons.playlist_add_check_outlined;
      case DrawerMenuItem.feedback:
        return Icons.edit_outlined;
      case DrawerMenuItem.profile:
        return Icons.person_outline;
      case DrawerMenuItem.about:
        return Icons.info_outline;
    }
  }

  String get labelKey {
    switch (this) {
      case DrawerMenuItem.dashboard:
        return 'dashboard';
      case DrawerMenuItem.myServiceRequests:
        return 'my_service_requests';
      case DrawerMenuItem.myWorkOrders:
        return 'my_work_orders';
      case DrawerMenuItem.feedback:
        return 'feedback';
      case DrawerMenuItem.profile:
        return 'profile';
      case DrawerMenuItem.about:
        return 'about';
    }
  }
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.selected});

  final DrawerMenuItem selected;

  static const _items = [
    DrawerMenuItem.dashboard,
    DrawerMenuItem.myServiceRequests,
    // DrawerMenuItem.myWorkOrders,
    // DrawerMenuItem.feedback,
    DrawerMenuItem.profile,
    // DrawerMenuItem.about,
  ];

  void _handleTap(BuildContext context, DrawerMenuItem item) {
    Navigator.of(context).pop();
    if (item == selected) return;

    if (item == DrawerMenuItem.dashboard) {
      Get.offAllNamed(AppRoutes.dashboard);
    } else if (item == DrawerMenuItem.myServiceRequests) {
      Get.offAllNamed(AppRoutes.serviceRequestList);
    } else if (item == DrawerMenuItem.profile) {
      Get.toNamed(AppRoutes.profile);
    } else {}
  }

  void _signOut(BuildContext context) {
    Navigator.of(context).pop();
    Get.find<SessionService>().clear();
    Get.offAllNamed(AppRoutes.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionService>();

    // Responsive width: matches the reference proportion (~84% of the
    // screen) on phones, but caps out on tablets/large screens instead
    // of growing unbounded.
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = (screenWidth * 0.84).clamp(280.0, 360.0);

    return Drawer(
      width: drawerWidth,
      backgroundColor: AppColors.scaffoldWhite,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/png/ic_logo.png',
                    width: 84,
                    height: 84 * 0.75,
                    fit: BoxFit.cover,
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: AppColors.drawerCollapseButtonBackground,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Directionality.of(context) == TextDirection.rtl
                            ? Icons.chevron_right
                            : Icons.chevron_left,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 42,
              backgroundColor: AppColors.primary,
              child: Obx(() {
                final name = session.userName.value ?? '';
                final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
                return Text(
                  initial,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Obx(
                () => Text(
                  session.userName.value ?? '',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Obx(
                () => Text(
                  session.userEmail.value ?? '',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Divider(color: AppColors.divider, height: 1, thickness: 1),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  for (final item in _items)
                    _DrawerRow(
                      icon: item.icon,
                      label: item.labelKey.tr,
                      isSelected: item == selected,
                      onTap: () => _handleTap(context, item),
                    ),
                ],
              ),
            ),
            _DrawerRow(
              icon: Icons.logout,
              label: 'sign_out'.tr,
              isSelected: false,
              onTap: () => _signOut(context),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _DrawerRow extends StatelessWidget {
  const _DrawerRow({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primary : AppColors.headingBlueGrey;

    return Material(
      color: isSelected
          ? AppColors.drawerSelectedBackground
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Row(
            children: [
              Icon(icon, size: 26, color: color),
              const SizedBox(width: 22),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: color,
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
