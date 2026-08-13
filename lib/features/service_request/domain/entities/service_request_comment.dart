/// A single comment shown on the Detail View's "Comments" tab —
/// author name on the left, a date label on the right, message below.
class ServiceRequestComment {
  const ServiceRequestComment({
    required this.author,
    required this.dateLabel,
    required this.message,
  });

  final String author;

  /// Already-formatted, e.g. "Today" or "Jul 9, 2026".
  final String dateLabel;
  final String message;
}
