import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/core/utils/app_date_format.dart';
import 'package:iungo/features/notification/domain/entities/app_notification.dart';
import 'package:iungo/features/notification/presentation/controllers/notification_controller.dart';
import 'package:iungo/features/notification/presentation/widgets/notification_empty_state.dart';

/// Purple header (close icon + title) over an "Unread" / "All" tab strip,
/// each tab showing a list of notification rows or the empty state.
class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final NotificationController controller = Get.find<NotificationController>();
  final ScrollController _scrollController = ScrollController();

  /// How close to the bottom (in pixels) the user has to scroll before
  /// the next page is requested.
  static const double _loadMoreThreshold = 240;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    // Only the "All" tab is paginated server-side — "Unread" is a local
    // filter over whatever's already loaded.
    if (controller.selectedTab.value != 1) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      controller.loadMore();
    }
  }

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
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (controller.hasError.value && controller.notifications.isEmpty) {
            return _NotificationErrorState(onRetry: controller.reload);
          }

          final items = controller.selectedTab.value == 0
              ? controller.unreadNotifications
              : controller.notifications;

          if (items.isEmpty) return const NotificationEmptyState();

          final showLoadMoreSpinner =
              controller.isLoadingMore.value && controller.selectedTab.value == 1;
          final itemCount = items.length + (showLoadMoreSpinner ? 1 : 0);

          return RefreshIndicator(
            onRefresh: controller.reload,
            color: AppColors.primary,
            child: ListView.separated(
              controller: _scrollController,
              padding: EdgeInsets.zero,
              itemCount: itemCount,
              separatorBuilder: (_, _) => const Divider(
                height: 1,
                thickness: 1,
                color: AppColors.divider,
              ),
              itemBuilder: (context, index) {
                if (index >= items.length) {
                  return const _LoadMoreSpinner();
                }
                return _NotificationTile(notification: items[index]);
              },
            ),
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

/// Small centered spinner appended below the last row while the next
/// page is being fetched (Notification "All" tab only).
class _LoadMoreSpinner extends StatelessWidget {
  const _LoadMoreSpinner();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

/// Full-screen state shown when the first page fails to load — matches
/// the empty-state layout with a retry action, same as the Service
/// Request list's own error state.
class _NotificationErrorState extends StatelessWidget {
  const _NotificationErrorState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 96,
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 20),
            Text(
              'something_went_wrong'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('retry'.tr),
            ),
          ],
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
    final controller = Get.find<NotificationController>();

    return Obx(() {
      final isMarking = controller.markingReadIds.contains(notification.id);

      return InkWell(
        onTap: () => _onTap(controller),
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
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: isMarking
                      ? const SizedBox(
                          width: 8,
                          height: 8,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: AppColors.attachmentDeleteText,
                          ),
                        )
                      : const CircleAvatar(
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
    });
  }

  /// Tapping a row only marks it read — it does not navigate anywhere.
  /// Once [AppNotification.isRead] flips to true, this row naturally
  /// drops out of the "Unread" tab (which is just `notifications.where
  /// ((n) => !n.isRead)` in the controller) without any extra removal
  /// step needed here.
  void _onTap(NotificationController controller) {
    controller.markAsRead(notification);
  }
}
