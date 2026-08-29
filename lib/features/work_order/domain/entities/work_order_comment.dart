/// A single comment shown on the Detail View's "Comments" tab — author
/// name on the left, a date label on the right, message below.
class WorkOrderComment {
  const WorkOrderComment({
    this.id,
    required this.author,
    required this.dateLabel,
    required this.message,
  });

  /// The `ticketnotes` record id returned by the Comments API. Null only
  /// for a comment that hasn't come from the server yet.
  final int? id;

  final String author;

  /// Already-formatted, e.g. "Today" or "Aug 9, 2026".
  final String dateLabel;
  final String message;
}
