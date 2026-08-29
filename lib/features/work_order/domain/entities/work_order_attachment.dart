/// A single file shown on the Detail View's "Attachments" tab. Backed by
/// the Attachments API (GET .../attachment/ticketattachments/workorder/
/// list/{id}).
class WorkOrderAttachment {
  const WorkOrderAttachment({
    this.id,
    this.fileId,
    required this.name,
    required this.extension,
    required this.sizeLabel,
    required this.dateLabel,
    this.contentType,
    this.previewUrl,
    this.downloadUrl,
  });

  /// The `ticketattachments` record id.
  final int? id;

  /// The underlying file id (`fileId`), distinct from [id].
  final int? fileId;

  final String name;

  /// Upper-case file extension shown in the small badge, e.g. "PNG".
  final String extension;

  /// Already-formatted, e.g. "489 KB".
  final String sizeLabel;

  /// Already-formatted, e.g. "Aug 9, 2026".
  final String dateLabel;

  /// MIME type from the server, e.g. "image/jpeg" — used to decide
  /// whether "View" can render an inline image preview.
  final String? contentType;

  /// Host-relative URL from the server, e.g.
  /// "/api/v2/files/preview/294619?version=revive" — resolve against
  /// the portal host before use.
  final String? previewUrl;

  /// Host-relative URL from the server for downloading/opening the
  /// original file.
  final String? downloadUrl;
}
