import 'package:get/get.dart';
import 'package:iungo/features/notification/data/datasources/notification_remote_data_source.dart';
import 'package:iungo/features/notification/data/models/notification_mapper.dart';
import 'package:iungo/features/notification/domain/entities/app_notification.dart';

/// Single in-memory source of truth for the Notification screen.
///
/// Registered as a permanent GetxService (not tied to a page's lifecycle)
/// so a row marked read here stays read if the screen is re-opened
/// within the same session. Pages are fetched by [NotificationController]
/// (which owns the current page/loading state for infinite scroll) and
/// pushed in here via [replaceWithPage] / [appendPage].
class NotificationRepository extends GetxService {
  NotificationRepository(this._remoteDataSource);

  final NotificationRemoteDataSource _remoteDataSource;

  final RxList<AppNotification> notifications = <AppNotification>[].obs;

  Future<NotificationListPageResult> fetchPage({
    required int page,
    required int perPage,
  }) {
    return _remoteDataSource.fetchNotifications(page: page, perPage: perPage);
  }

  /// Replaces the whole list with a freshly-fetched first page (initial
  /// load / pull-to-refresh).
  void replaceWithPage(List<AppNotification> page) {
    notifications.assignAll(page);
  }

  /// Appends a subsequent page, skipping any ids already present (guards
  /// against duplicate rows if a notification shifts pages between
  /// requests).
  void appendPage(List<AppNotification> page) {
    final existingIds = notifications.map((n) => n.id).toSet();
    final newOnes = page.where((n) => !existingIds.contains(n.id));
    notifications.addAll(newOnes);
  }

  /// Clears the server's "unseen since last open" badge (§5.3). Failures
  /// are intentionally swallowed by the caller if desired — this is
  /// best-effort housekeeping, not something that should block the
  /// screen from showing what's already loaded.
  Future<void> markAllSeen() => _remoteDataSource.markAllSeen();

  /// Marks [notification] read on the server, then reflects that in the
  /// local list — only on success, so a failed call leaves the row (and
  /// its unread styling) exactly as it was rather than drifting from
  /// what the server actually has.
  Future<void> markAsRead(AppNotification notification) async {
    if (notification.isRead) return;

    await _remoteDataSource.markAsRead(notification.id);

    final index = notifications.indexWhere((n) => n.id == notification.id);
    if (index != -1) {
      notifications[index] = notifications[index].copyWith(isRead: true);
    }
  }
}
