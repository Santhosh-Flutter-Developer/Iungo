import 'dart:typed_data';

/// A single file shown on the Detail View's "Attachments" tab.
/// [path]/[bytes] are only populated for attachments picked in this
/// session (mobile vs web) — seeded/mocked attachments leave both null.
class ServiceRequestAttachment {
  const ServiceRequestAttachment({
    required this.name,
    required this.extension,
    required this.sizeLabel,
    required this.dateLabel,
    this.path,
    this.bytes,
  });

  final String name;

  /// Upper-case file extension shown in the small badge, e.g. "JPG".
  final String extension;

  /// Already-formatted, e.g. "1.20 MB".
  final String sizeLabel;

  /// Already-formatted, e.g. "Jul 9, 2026".
  final String dateLabel;

  final String? path;
  final Uint8List? bytes;
}
