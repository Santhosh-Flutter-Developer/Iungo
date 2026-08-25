import 'package:iungo/core/utils/app_date_format.dart';
import 'package:iungo/features/service_request/domain/entities/service_request_attachment.dart';
import 'package:iungo/features/service_request/domain/entities/service_request_comment.dart';

/// Parses the "list comments" response (Portal API Guide §3.1) — a plain
/// JSON array, not the `{code, data, meta}` v3 envelope the rest of the
/// module uses:
///
/// ```
/// [ { "id": 34012, "body": "Hi", "createdBy": {"name": "Dinesh"},
///     "createdTime": 1756512345000, ... } ]
/// ```
class ServiceRequestCommentMapper {
  ServiceRequestCommentMapper._();

  static List<ServiceRequestComment> listFromJson(dynamic raw) {
    if (raw is! List) return const [];
    final comments = raw
        .whereType<Map<String, dynamic>>()
        .map(fromJson)
        .toList();
    // The guide doesn't state an ordering guarantee for this endpoint;
    // sort oldest-first so the tab reads top-to-bottom like a thread.
    comments.sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));
    return comments;
  }

  static ServiceRequestComment fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    final createdBy = json['createdBy'];
    final author = (createdBy is Map<String, dynamic>)
        ? (createdBy['name'] as String?)?.trim()
        : null;

    final createdTimeMs = _asInt(json['createdTime']);
    final dateLabel = createdTimeMs != null && createdTimeMs > 0
        ? AppDateFormat.relativeDay(
            DateTime.fromMillisecondsSinceEpoch(createdTimeMs),
          )
        : '';

    final body = (json['body'] as String?)?.trim() ?? '';

    return ServiceRequestComment(
      id: id,
      author: (author == null || author.isEmpty) ? '--' : author,
      dateLabel: dateLabel,
      message: body,
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

/// Parses the "list attachments" / "upload attachment" response (Portal
/// API Guide §4.1/§4.2) — both share the same shape:
///
/// ```
/// { "attachments": [ { "id": 55021, "fileId": 99881,
///     "fileName": "photo.jpg", "fileSize": 1258291,
///     "contentType": "image/jpeg", "uploadedTime": 1752019200000,
///     "previewUrl": "...", "downloadUrl": "..." } ],
///   "supplements": { "uploadedBy": { "771": { "name": "Dinesh" } } } }
/// ```
class ServiceRequestAttachmentMapper {
  ServiceRequestAttachmentMapper._();

  static List<ServiceRequestAttachment> responseFromJson(
    Map<String, dynamic> body,
  ) {
    final raw = body['attachments'];
    if (raw is! List) return const [];
    return raw.whereType<Map<String, dynamic>>().map(fromJson).toList();
  }

  static ServiceRequestAttachment fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    final fileId = _asInt(json['fileId']);
    final fileName = (json['fileName'] as String?)?.trim() ?? '';

    final uploadedTimeMs = _asInt(json['uploadedTime']);
    final dateLabel = uploadedTimeMs != null && uploadedTimeMs > 0
        ? AppDateFormat.mediumDate(
            DateTime.fromMillisecondsSinceEpoch(uploadedTimeMs),
          )
        : '';

    return ServiceRequestAttachment(
      id: id,
      fileId: fileId,
      name: fileName,
      extension: _extensionOf(fileName),
      sizeLabel: _sizeLabelFor(_asInt(json['fileSize'])),
      dateLabel: dateLabel,
      contentType: (json['contentType'] as String?)?.trim(),
      previewUrl: (json['previewUrl'] as String?)?.trim(),
      downloadUrl: (json['downloadUrl'] as String?)?.trim(),
    );
  }

  static String _extensionOf(String name) {
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == name.length - 1) return '';
    return name.substring(dotIndex + 1).toUpperCase();
  }

  static String _sizeLabelFor(int? bytes) {
    if (bytes == null) return '--';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
