import 'package:iungo/features/notification/domain/entities/app_notification.dart';

/// Parses one page of the Notification list API
/// (`GET /client/api/v3/modules/usernotification`, Portal API Guide §5.1)
/// into [AppNotification] entities.
class NotificationListPageResult {
  const NotificationListPageResult({
    required this.notifications,
    required this.rawCount,
    this.totalCount,
  });

  final List<AppNotification> notifications;

  /// Number of raw items returned by the server for this page — used by
  /// the caller to decide whether another page likely exists (a full
  /// page suggests more; a short page means the end was reached).
  final int rawCount;

  /// `meta.pagination.totalCount`, when the server sent `withCount=true`.
  final int? totalCount;

  factory NotificationListPageResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final rawList = (data is Map<String, dynamic>)
        ? data['usernotification']
        : null;
    final items = (rawList is List) ? rawList : const [];

    final meta = json['meta'];
    final pagination = (meta is Map<String, dynamic>)
        ? meta['pagination']
        : null;
    final totalCount = (pagination is Map<String, dynamic>)
        ? _asInt(pagination['totalCount'])
        : null;

    final notifications = items
        .whereType<Map<String, dynamic>>()
        .map(NotificationMapper.fromJson)
        .toList();

    return NotificationListPageResult(
      notifications: notifications,
      rawCount: items.length,
      totalCount: totalCount,
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

/// Maps a single raw `usernotification` row (Portal API Guide §5.4) into
/// an [AppNotification].
class NotificationMapper {
  NotificationMapper._();

  static AppNotification fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']) ?? 0;
    final title = (json['title'] as String?)?.trim() ?? '';
    final subject = (json['subject'] as String?)?.trim() ?? '';

    final sysCreatedTimeMs = _asInt(json['sysCreatedTime']);
    final raisedAt = sysCreatedTimeMs != null && sysCreatedTimeMs > 0
        ? DateTime.fromMillisecondsSinceEpoch(sysCreatedTimeMs)
        : DateTime.now();

    // notificationStatus: 1 = Unseen, 2 = Unread, 3 = Seen (§5.3) — the
    // row is considered "read" only once the server has it as Seen.
    final notificationStatus = _asInt(json['notificationStatus']);
    final isRead = notificationStatus == 3;

    final action = json['action'];
    final actionData = (action is Map<String, dynamic>)
        ? action['actionData']
        : null;
    String? actionModule;
    int? actionRecordId;
    if (actionData is Map<String, dynamic>) {
      final module = actionData['module'];
      if (module is Map<String, dynamic>) {
        actionModule = (module['name'] as String?)?.trim();
      }
      actionRecordId = _asInt(actionData['recordId']);
    }
    // §5.4: treat a missing recordId, or a value of -1, as "not tappable".
    if (actionRecordId != null && actionRecordId <= 0) {
      actionRecordId = null;
    }

    return AppNotification(
      id: id,
      title: title,
      description: subject,
      raisedAt: raisedAt,
      isRead: isRead,
      actionModule: actionModule,
      actionRecordId: actionRecordId,
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
