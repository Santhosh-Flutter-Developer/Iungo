import 'package:iungo/core/utils/app_date_format.dart';
import 'package:iungo/features/service_request/domain/entities/service_request_priority.dart';
import 'package:iungo/features/work_order/domain/entities/work_order.dart';
import 'package:iungo/features/work_order/domain/entities/work_order_attachment.dart';
import 'package:iungo/features/work_order/domain/entities/work_order_comment.dart';
import 'package:iungo/features/work_order/domain/entities/work_order_maintenance_type.dart';
import 'package:iungo/features/work_order/domain/entities/work_order_status.dart';
import 'package:iungo/features/work_order/domain/entities/work_order_task.dart';

/// Maps the raw `data.workorder` object returned by the Detail View's
/// Overview API (GET .../v3/modules/workorder/view/all?...&id=<id>) into
/// a [WorkOrder].
///
/// Unlike the list API, related fields (`moduleState`, `priority`,
/// `category`, `type`, `site`, `assignedTo`, `createdBy`) arrive fully
/// inline here — not as an id + a separate `meta.supplements` lookup —
/// confirmed via a captured single-record response. The "requester"
/// shown with the person icon on the Overview tab is the ticket's
/// `createdBy` — same field the list mapper reads (via its supplements
/// lookup) for that person icon — not `assignedBy`, which can be a
/// different person (or absent) and doesn't match what the list shows
/// for the same ticket.
WorkOrder mapWorkOrderDetail(Map<String, dynamic> json) {
  final id = _asInt(json['id']) ?? 0;
  // The ticket number shown on the Detail View (e.g. "# 1415071") and
  // used for Find Ticket — prefer `localId`/`serialNumber` over the
  // internal `id`, matching the list mapper's convention.
  final serialNumber =
      _asInt(json['localId']) ?? _asInt(json['serialNumber']) ?? id;

  final subject = (json['subject'] as String?)?.trim() ?? '';
  final description = (json['description'] as String?)?.trim() ?? '';

  final createdTimeMs = _asInt(json['createdTime']);
  final raisedAt = createdTimeMs != null && createdTimeMs > 0
      ? DateTime.fromMillisecondsSinceEpoch(createdTimeMs)
      : DateTime.now();

  final dueDateMs = _asInt(json['dueDate']);
  final dueDate = dueDateMs != null && dueDateMs > 0
      ? DateTime.fromMillisecondsSinceEpoch(dueDateMs)
      : raisedAt;

  final status = WorkOrderStatusX.fromApiLabel(_primaryValue(json['moduleState']));
  final priority =
      ServiceRequestPriorityX.fromApiLabel(_primaryValue(json['priority']));
  final discipline = _primaryValue(json['category']) ?? '';
  final maintenanceType =
      WorkOrderMaintenanceTypeX.fromApiLabel(_primaryValue(json['type']));

  final site = json['site'];
  final siteName = (site is Map<String, dynamic>)
      ? (site['name'] as String?)?.trim()
      : null;

  final assignedTo = json['assignedTo'];
  final assignedTechnician = (assignedTo is Map<String, dynamic>)
      ? (assignedTo['name'] as String?)?.trim()
      : null;

  // The person (or company/client contact) shown with the person icon
  // on the Overview tab — `createdBy`, matching the list mapper's
  // `requester` field exactly (both read the same underlying data;
  // the list just gets it via a supplements lookup instead of inline).
  final createdBy = json['createdBy'];
  final requester = (createdBy is Map<String, dynamic>)
      ? (createdBy['name'] as String?)?.trim()
      : null;

  return WorkOrder(
    id: id,
    serialNumber: serialNumber,
    title: subject,
    description: description,
    requester: (requester == null || requester.isEmpty) ? '--' : requester,
    site: (siteName == null || siteName.isEmpty) ? '--' : siteName,
    priority: priority,
    status: status,
    discipline: discipline,
    maintenanceType: maintenanceType,
    dueDate: dueDate,
    raisedAt: raisedAt,
    assignedTechnician:
        (assignedTechnician == null || assignedTechnician.isEmpty)
            ? null
            : assignedTechnician,
  );
}

/// Reads the `primaryValue` off an expanded picklist/relation field
/// (e.g. `{"id": 43, "primaryValue": "Routine", ...}`). Returns null if
/// [value] isn't a map or has no `primaryValue`.
String? _primaryValue(dynamic value) {
  if (value is! Map<String, dynamic>) return null;
  return (value['primaryValue'] as String?)?.trim();
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

/// Parses the Comments API's response (GET .../note/workorder/get/{id})
/// — a plain JSON array, same shape as the Service Request Comments API:
///
/// ```
/// [ { "id": 27672, "body": "testing", "createdBy": {"name": "Dinesh"},
///     "createdTime": 1787900123914, ... } ]
/// ```
class WorkOrderCommentMapper {
  WorkOrderCommentMapper._();

  static List<WorkOrderComment> listFromJson(dynamic raw) {
    if (raw is! List) return const [];
    final comments =
        raw.whereType<Map<String, dynamic>>().map(fromJson).toList();
    // No documented ordering guarantee — sort oldest-first so the tab
    // reads top-to-bottom like a thread.
    comments.sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));
    return comments;
  }

  static WorkOrderComment fromJson(Map<String, dynamic> json) {
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

    return WorkOrderComment(
      id: id,
      author: (author == null || author.isEmpty) ? '--' : author,
      dateLabel: dateLabel,
      message: body,
    );
  }
}

/// Parses the Attachments API's response (GET .../attachment/
/// ticketattachments/workorder/list/{id}):
///
/// ```
/// { "attachments": [ { "id": 75804, "fileId": 294619,
///     "fileName": "photo.jpg", "fileSize": 331887,
///     "contentType": "image/jpeg", "uploadedTime": 1787891800594,
///     "previewUrl": "...", "downloadUrl": "..." } ] }
/// ```
class WorkOrderAttachmentMapper {
  WorkOrderAttachmentMapper._();

  static List<WorkOrderAttachment> responseFromJson(Map<String, dynamic> body) {
    final raw = body['attachments'];
    if (raw is! List) return const [];
    return raw.whereType<Map<String, dynamic>>().map(fromJson).toList();
  }

  static WorkOrderAttachment fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    final fileId = _asInt(json['fileId']);
    final fileName = (json['fileName'] as String?)?.trim() ?? '';

    final uploadedTimeMs = _asInt(json['uploadedTime']) ?? _asInt(json['createdTime']);
    final dateLabel = uploadedTimeMs != null && uploadedTimeMs > 0
        ? AppDateFormat.mediumDate(
            DateTime.fromMillisecondsSinceEpoch(uploadedTimeMs),
          )
        : '';

    return WorkOrderAttachment(
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
}

/// Parses the Tasks API's response (GET .../v2/tasks/parent/{id}):
///
/// ```
/// { "responseCode": 0, "result": { "tasks": null, "sections": {} } }
/// ```
///
/// No confirmed capture yet includes a work order with actual tasks (the
/// sample ticket used to build this mapper had none — `tasks: null` and
/// an empty `sections: {}`), so both plausible shapes are read
/// defensively: a top-level `tasks` array, and/or a `sections` map whose
/// values are either task arrays directly or `{"tasks": [...]}` blocks —
/// whichever the server actually sends, this flattens into one list.
class WorkOrderTaskResult {
  const WorkOrderTaskResult({
    required this.tasks,
    required this.completed,
    required this.total,
  });

  final List<WorkOrderTask> tasks;
  final int completed;
  final int total;

  factory WorkOrderTaskResult.fromJson(Map<String, dynamic> json) {
    final result = json['result'];
    final resultMap = (result is Map<String, dynamic>) ? result : json;

    final tasks = <WorkOrderTask>[];

    final topLevelTasks = resultMap['tasks'];
    if (topLevelTasks is List) {
      tasks.addAll(topLevelTasks.whereType<Map<String, dynamic>>().map(_fromJson));
    }

    final sections = resultMap['sections'];
    if (sections is Map<String, dynamic>) {
      for (final section in sections.values) {
        if (section is List) {
          tasks.addAll(section.whereType<Map<String, dynamic>>().map(_fromJson));
        } else if (section is Map<String, dynamic>) {
          final sectionTasks = section['tasks'];
          if (sectionTasks is List) {
            tasks.addAll(
              sectionTasks.whereType<Map<String, dynamic>>().map(_fromJson),
            );
          }
        }
      }
    }

    final completed = tasks.where((t) => t.completed).length;
    return WorkOrderTaskResult(
      tasks: tasks,
      completed: completed,
      total: tasks.length,
    );
  }

  static WorkOrderTask _fromJson(Map<String, dynamic> json) {
    final title = (json['taskName'] ?? json['name'] ?? json['title'] ?? json['subject'])
            as String? ??
        '';

    final completedFlag = json['completed'] ?? json['isCompleted'];
    final status = (json['status'] ?? json['taskStatus'] ?? json['state'])
        ?.toString()
        .toLowerCase();
    final completed = completedFlag == true ||
        status == 'completed' ||
        status == 'done' ||
        status == 'true';

    return WorkOrderTask(
      id: _asInt(json['id']),
      title: title.trim(),
      completed: completed,
    );
  }
}