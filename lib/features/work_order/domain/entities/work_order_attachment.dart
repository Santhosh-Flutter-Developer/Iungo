/// A single file shown on the Detail View's "Attachments" tab.
class WorkOrderAttachment {
  const WorkOrderAttachment({
    required this.name,
    required this.extension,
    required this.sizeLabel,
    required this.dateLabel,
    this.assetPath,
  });

  final String name;

  /// Upper-case file extension shown in the small badge, e.g. "PNG".
  final String extension;

  /// Already-formatted, e.g. "489 KB".
  final String sizeLabel;

  /// Already-formatted, e.g. "Yesterday".
  final String dateLabel;

  /// Bundled asset shown by the full-screen viewer when "View" is
  /// tapped. Null falls back to a plain filename placeholder.
  final String? assetPath;
}