import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/core/utils/app_date_format.dart';
import 'package:iungo/features/notification/domain/entities/app_notification.dart';
import 'package:iungo/features/notification/presentation/controllers/notification_controller.dart';
import 'package:iungo/features/notification/presentation/widgets/notification_empty_state.dart';

/// Purple header (close icon + title) over an "Unread" / "All" tab strip,
/// each tab showing a list of notification rows or the empty state.
class NotificationPage extends GetView<NotificationController> {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'notification'.tr,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: const _NotificationTabBar(),
        ),
      ),
      body: SafeArea(
        child: Obx(() {
          final items = controller.selectedTab.value == 0
              ? controller.unreadNotifications
              : controller.notifications;

          if (items.isEmpty) return const NotificationEmptyState();

          return ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(
              height: 1,
              thickness: 1,
              color: AppColors.divider,
            ),
            itemBuilder: (context, index) =>
                _NotificationTile(notification: items[index]),
          );
        }),
      ),
    );
  }
}

class _NotificationTabBar extends GetView<NotificationController>
    implements PreferredSizeWidget {
  const _NotificationTabBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(
            () => Row(
              children: [
                _TabButton(
                  label: 'unread'.tr,

                  isSelected: controller.selectedTab.value == 0,
                  onTap: () => controller.selectTab(0),
                ),
                _TabButton(
                  label: 'all'.tr,
                  isSelected: controller.selectedTab.value == 1,
                  onTap: () => controller.selectTab(1),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Colors.white24),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.white : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: isSelected ? AppColors.white : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    return InkWell(
      onTap: () => Get.find<NotificationController>().markAsRead(notification),
      child: Container(
        width: double.infinity,
        color: isUnread
            ? AppColors.drawerSelectedBackground
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isUnread) ...[
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: CircleAvatar(
                  radius: 4,
                  backgroundColor: AppColors.attachmentDeleteText,
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isUnread
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppDateFormat.relativeDay(notification.raisedAt),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
