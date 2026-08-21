import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';

/// "No Notifications Available" placeholder — same title/subtitle sizing
/// and colors as [ServiceRequestEmptyState] for visual consistency across
/// the app's empty states.
class NotificationEmptyState extends StatelessWidget {
  const NotificationEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Positioned(
                //   bottom: 4,
                //   child: Container(
                //     width: 130,
                //     height: 20,
                //     decoration: BoxDecoration(
                //       color: AppColors.divider.withValues(alpha: 0.4),
                //       borderRadius: BorderRadius.circular(40),
                //     ),
                //   ),
                // ),
                Icon(
                  Icons.notifications_none_outlined,
                  size: 96,
                  color: AppColors.textMuted.withValues(alpha: 0.5),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'no_notifications_available'.tr,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'no_new_notifications'.tr,
              style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
