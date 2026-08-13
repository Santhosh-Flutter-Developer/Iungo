import 'package:iungo/features/service_request/domain/entities/service_request_option.dart';
import 'package:iungo/features/service_request/domain/entities/service_request_priority.dart';
import 'package:iungo/features/service_request/domain/entities/service_request_status.dart';

/// Everything selected on the Filter sheet. Immutable — the controller
/// swaps in a new instance whenever a value changes.
class ServiceRequestFilter {
  const ServiceRequestFilter({
    this.type,
    this.status,
    this.priority,
    this.dueDateStart,
    this.dueDateEnd,
  });

  final ServiceRequestOption? type;
  final ServiceRequestStatus? status;
  final ServiceRequestPriority? priority;
  final DateTime? dueDateStart;
  final DateTime? dueDateEnd;

  bool get isEmpty =>
      type == null &&
      status == null &&
      priority == null &&
      dueDateStart == null &&
      dueDateEnd == null;

  ServiceRequestFilter copyWith({
    ServiceRequestOption? type,
    bool clearType = false,
    ServiceRequestStatus? status,
    bool clearStatus = false,
    ServiceRequestPriority? priority,
    bool clearPriority = false,
    DateTime? dueDateStart,
    DateTime? dueDateEnd,
    bool clearDueDate = false,
  }) {
    return ServiceRequestFilter(
      type: clearType ? null : (type ?? this.type),
      status: clearStatus ? null : (status ?? this.status),
      priority: clearPriority ? null : (priority ?? this.priority),
      dueDateStart: clearDueDate ? null : (dueDateStart ?? this.dueDateStart),
      dueDateEnd: clearDueDate ? null : (dueDateEnd ?? this.dueDateEnd),
    );
  }
}
