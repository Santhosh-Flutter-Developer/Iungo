/// A single row on the Notification page — e.g. "New SR: 1235 has been
/// created". [isRead] drives the bold-title + unread-tint styling and
/// whether it shows up on the "Unread" tab.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.description,
    required this.raisedAt,
    this.isRead = false,
    this.actionModule,
    this.actionRecordId,
  });

  final int id;
  final String title;
  final String description;
  final DateTime raisedAt;
  final bool isRead;

  /// From the notification's `action.actionData.module.name` (Portal API
  /// Guide §5.4) — which screen a tap should open, e.g. `serviceRequest`.
  final String? actionModule;

  /// From `action.actionData.recordId`. Null means "not tappable" — a
  /// missing recordId, or a raw value of -1, is normalized to null by
  /// the mapper.
  final int? actionRecordId;

  /// True when this row has enough info to deep-link somewhere on tap.
  bool get isTappable => actionModule != null && actionRecordId != null;

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      description: description,
      raisedAt: raisedAt,
      isRead: isRead ?? this.isRead,
      actionModule: actionModule,
      actionRecordId: actionRecordId,
    );
  }
}
