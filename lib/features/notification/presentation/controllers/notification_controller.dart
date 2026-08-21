import 'package:get/get.dart';
import 'package:iungo/features/notification/domain/entities/app_notification.dart';

/// Backs the Notification page's "Unread" / "All" tabs. No live API for
/// this yet — seeded with data matching the reference screenshots so the
/// UI (empty state, unread styling, tab counts) is fully wired and ready
/// to swap for a real fetch later.
class NotificationController extends GetxController {
  /// 0 = Unread, 1 = All — matches the reference screenshots, which open
  /// on the Unread tab by default.
  final RxInt selectedTab = 0.obs;

  final RxList<AppNotification> notifications = <AppNotification>[].obs;

  @override
  void onInit() {
    super.onInit();
    notifications.assignAll(_seedData());
  }

  List<AppNotification> get unreadNotifications =>
      notifications.where((n) => !n.isRead).toList();

  void selectTab(int index) => selectedTab.value = index;

  void markAsRead(AppNotification notification) {
    final index = notifications.indexWhere((n) => n.id == notification.id);
    if (index == -1 || notifications[index].isRead) return;
    notifications[index] = notifications[index].copyWith(isRead: true);
  }

  List<AppNotification> _seedData() {
    final now = DateTime.now();
    DateTime daysAgo(int days) => now.subtract(Duration(days: days));

    return [
      AppNotification(
        id: 1235,
        title: 'New SR: 1235 has been created',
        description: 'New Service Request has been created',
        raisedAt: now,
      ),
      AppNotification(
        id: 1234,
        title: 'New SR: 1234 has been created',
        description: 'New Service Request has been created',
        raisedAt: now,
      ),
      AppNotification(
        id: 1233,
        title: 'New SR: 1233 has been created',
        description: 'New Service Request has been created',
        raisedAt: now,
      ),
      AppNotification(
        id: 1232,
        title: 'New SR: 1232 has been created',
        description: 'New Service Request has been created',
        raisedAt: now,
      ),
      AppNotification(
        id: 1231,
        title: 'New SR: 1231 has been created',
        description: 'New Service Request has been created',
        raisedAt: now,
      ),
      AppNotification(
        id: 1230,
        title: 'New SR: 1230 has been created',
        description: 'New Service Request has been created',
        raisedAt: daysAgo(1),
      ),
      AppNotification(
        id: 1229,
        title: 'New SR: 1229 has been created',
        description: 'New Service Request has been created',
        raisedAt: daysAgo(1),
      ),
      AppNotification(
        id: 1088,
        title: 'New SR: 1088 has been created',
        description: 'New Service Request has been created',
        raisedAt: DateTime(2026, 6, 30),
      ),
      AppNotification(
        id: 1085,
        title: 'New SR: 1085 has been created',
        description: 'New Service Request has been created',
        raisedAt: DateTime(2026, 6, 30),
      ),
      AppNotification(
        id: 10231,
        title: 'SR: 1023 Status has been Changed',
        description:
            'Service Request status has been Changed to convertedasworkorder',
        raisedAt: DateTime(2026, 6, 18),
        isRead: true,
      ),
      AppNotification(
        id: 1023,
        title: 'New SR: 1023 has been created',
        description: 'New Service Request has been created',
        raisedAt: DateTime(2026, 6, 18),
        isRead: true,
      ),
    ];
  }
}