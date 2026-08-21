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
  });

  final int id;
  final String title;
  final String description;
  final DateTime raisedAt;
  final bool isRead;

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      description: description,
      raisedAt: raisedAt,
      isRead: isRead ?? this.isRead,
    );
  }
}