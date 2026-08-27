import 'dart:async';

import 'package:get/get.dart';
import 'package:iungo/core/widgets/app_snackbar.dart';
import 'package:iungo/features/notification/data/datasources/notification_exceptions.dart';
import 'package:iungo/features/notification/data/notification_repository.dart';
import 'package:iungo/features/notification/domain/entities/app_notification.dart';

/// Backs the Notification page's "Unread" / "All" tabs.
///
/// Fetches real data from the usernotification list API (Portal API
/// Guide §5.1), paginated for infinite scroll. The "Unread" tab is
/// driven off each row's own `notificationStatus` field rather than the
/// server's "unseen since last open" semantics (§5.2) — per the guide's
/// own recommendation, this is what keeps the tab accurate even after
/// the screen has been opened and closed.
class NotificationController extends GetxController {
  NotificationController(this._repository);

  final NotificationRepository _repository;

  static const int _perPage = 20;

  /// 0 = Unread, 1 = All — matches the reference screenshots, which open
  /// on the Unread tab by default.
  final RxInt selectedTab = 0.obs;

  /// True only while the very first page is loading.
  final RxBool isLoading = true.obs;

  /// True while a subsequent page is being fetched (infinite scroll).
  final RxBool isLoadingMore = false.obs;

  /// True when the first-page load failed outright (drives the
  /// full-screen error/retry state).
  final RxBool hasError = false.obs;

  /// False once a page comes back with fewer than [_perPage] items —
  /// i.e. there's nothing further to fetch.
  final RxBool hasMore = true.obs;

  /// Ids currently mid "mark as read" call — lets a row show a small
  /// spinner and ignore a second tap instead of double-firing the PATCH.
  final RxSet<int> markingReadIds = <int>{}.obs;

  int _page = 1;

  List<AppNotification> get notifications => _repository.notifications;

  List<AppNotification> get unreadNotifications =>
      notifications.where((n) => !n.isRead).toList();

  @override
  void onInit() {
    super.onInit();
    _loadFirstPage();
  }

  Future<void> _loadFirstPage() async {
    isLoading.value = true;
    hasError.value = false;
    _page = 1;
    try {
      final result = await _repository.fetchPage(
        page: _page,
        perPage: _perPage,
      );
      _repository.replaceWithPage(result.notifications);
      hasMore.value = result.rawCount >= _perPage;
    } catch (_) {
      hasError.value = true;
      hasMore.value = false;
    } finally {
      isLoading.value = false;
    }

    // Best-effort — clears the bell badge elsewhere in the app. A
    // failure here shouldn't surface as an error on a screen that just
    // loaded successfully, so it's swallowed rather than awaited.
    unawaited(_repository.markAllSeen().catchError((_) {}));
  }

  /// Called when the list is scrolled near its end. Fetches the next
  /// page of [_perPage] and appends it — a no-op while already loading
  /// or once a page has come back short.
  Future<void> loadMore() async {
    if (isLoading.value || isLoadingMore.value || !hasMore.value) return;

    isLoadingMore.value = true;
    try {
      final nextPage = _page + 1;
      final result = await _repository.fetchPage(
        page: nextPage,
        perPage: _perPage,
      );
      _repository.appendPage(result.notifications);
      _page = nextPage;
      hasMore.value = result.rawCount >= _perPage;
    } catch (_) {
      // Silently keep [hasMore] as-is so the user can retry by scrolling
      // again; a persistent bottom spinner would be misleading here.
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> reload() => _loadFirstPage();

  void selectTab(int index) => selectedTab.value = index;

  /// Marks [notification] read on the server (§5.3) and reflects that
  /// locally on success. Shows a snackbar and leaves the row untouched
  /// on failure, matching the rest of the app's error-handling pattern.
  Future<void> markAsRead(AppNotification notification) async {
    if (notification.isRead || markingReadIds.contains(notification.id)) {
      return;
    }

    markingReadIds.add(notification.id);
    try {
      await _repository.markAsRead(notification);
    } on NotificationException catch (e) {
      AppSnackbar.showError(
        e.message.trim().isNotEmpty ? e.message : 'something_went_wrong'.tr,
      );
    } catch (_) {
      AppSnackbar.showError('something_went_wrong'.tr);
    } finally {
      markingReadIds.remove(notification.id);
    }
  }
}
