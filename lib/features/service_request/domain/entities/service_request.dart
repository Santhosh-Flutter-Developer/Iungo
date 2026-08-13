import 'package:iungo/features/service_request/domain/entities/service_request_option.dart';
import 'package:iungo/features/service_request/domain/entities/service_request_priority.dart';
import 'package:iungo/features/service_request/domain/entities/service_request_status.dart';

/// A single "My Service Requests" list-card entry. Static/UI-only model —
/// the whole list lives in memory (see ServiceRequestRepository).
class ServiceRequest {
  const ServiceRequest({
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
  });

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
}
