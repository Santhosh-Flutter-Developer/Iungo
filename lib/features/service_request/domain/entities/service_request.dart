import 'package:iungo/features/service_request/domain/entities/request_classification.dart';
import 'package:iungo/features/service_request/domain/entities/service_request_attachment.dart';
import 'package:iungo/features/service_request/domain/entities/service_request_comment.dart';
import 'package:iungo/features/service_request/domain/entities/service_request_option.dart';
import 'package:iungo/features/service_request/domain/entities/service_request_priority.dart';
import 'package:iungo/features/service_request/domain/entities/service_request_status.dart';

/// A single "My Service Requests" list-card entry. Static/UI-only model —
/// the whole list lives in memory (see ServiceRequestRepository). Also
/// backs the Detail View screen shown when a card is tapped.
class ServiceRequest {
  ServiceRequest({
    required this.id,
    required this.title,
    required this.description,
    required this.requester,
    required this.site,
    required this.priority,
    required this.status,
    required this.type,
    required this.dueDate,
    this.isArabicTitle = false,
    DateTime? raisedAt,
    this.phone,
    this.assignedTechnician,
    this.building,
    this.classification = RequestClassification.problem,
    this.spaceAsset,
    this.comments = const [],
    this.attachments = const [],
  }) : raisedAt = raisedAt ?? dueDate;

  final int id;
  final String title;
  final String description;
  final String requester;
  final String site;
  final ServiceRequestPriority priority;
  final ServiceRequestStatus status;
  final ServiceRequestOption type;
  final DateTime dueDate;

  /// The one seeded ticket in the reference video has an Arabic
  /// title/description — kept as-is (no RTL layout flip needed for a
  /// single value inside an LTR card).
  final bool isArabicTitle;

  // --- Detail View only (below) ---------------------------------------

  /// Date + time shown at the top of the Detail View's Overview tab.
  /// Falls back to [dueDate] (midnight) when not supplied.
  final DateTime raisedAt;

  final String? phone;

  /// Null renders as "Not Assigned".
  final String? assignedTechnician;

  final String? building;
  final RequestClassification classification;

  /// Null renders as "--".
  final String? spaceAsset;

  final List<ServiceRequestComment> comments;
  final List<ServiceRequestAttachment> attachments;
}
