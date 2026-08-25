import 'dart:typed_data';

/// A single file shown on the Detail View's "Attachments" tab.
///
/// [path]/[bytes] are only populated for an attachment that hasn't been
/// confirmed by the server yet (mobile vs web, respectively) — used to
/// render an "uploading…" placeholder tile. Once the upload succeeds the
/// tile is replaced with the server's copy, which carries [id]/[fileId]/
/// [previewUrl]/[downloadUrl] instead.
class ServiceRequestAttachment {
  const ServiceRequestAttachment({
    this.id,
    this.fileId,
    required this.name,
    required this.extension,
    required this.sizeLabel,
    required this.dateLabel,
    this.contentType,
    this.previewUrl,
    this.downloadUrl,
    this.path,
    this.bytes,
    this.isUploading = false,
  });

  /// The `servicerequestsattachments` record id (Portal API Guide §4.1) —
  /// required to delete this attachment. Null while [isUploading].
  final int? id;

  /// The underlying file id (`fileId`), distinct from [id].
  final int? fileId;

  final String name;

  /// Upper-case file extension shown in the small badge, e.g. "JPG".
  final String extension;

  /// Already-formatted, e.g. "1.20 MB".
  final String sizeLabel;

  /// Already-formatted, e.g. "Jul 9, 2026".
  final String dateLabel;

  /// MIME type from the server, e.g. "image/jpeg" — used to decide
  /// whether "View" can render an inline image preview.
  final String? contentType;

  /// Host-relative URL from the server, e.g.
  /// "/api/v2/files/preview/99881?version=revive" (Portal API Guide
  /// §4.3) — resolve against the portal host before use.
  final String? previewUrl;

  /// Host-relative URL from the server for downloading the original file.
  final String? downloadUrl;

  final String? path;
  final Uint8List? bytes;

  /// True for a locally-picked file whose upload request hasn't resolved
  /// yet — renders a disabled/placeholder tile instead of View/Delete.
  final bool isUploading;
}
