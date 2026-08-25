/// A single comment shown on the Detail View's "Comments" tab —
/// author name on the left, a date label on the right, message below.
class ServiceRequestComment {
  const ServiceRequestComment({
    this.id,
    required this.author,
    required this.dateLabel,
    required this.message,
  });

  /// The `servicerequestsnotes` record id (Portal API Guide §3.1). Null
  /// only for a comment built purely on the client before the server has
  /// echoed one back (which shouldn't normally be observable — see
  /// [ServiceRequestDetailController.addComment]).
  final int? id;

  final String author;

  /// Already-formatted, e.g. "Today" or "Jul 9, 2026".
  final String dateLabel;
  final String message;
}
