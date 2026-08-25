import 'package:iungo/features/service_request/domain/entities/service_request_priority.dart';
import 'package:iungo/features/work_order/domain/entities/work_order_status.dart';

/// Everything selected on the Work Orders Filter screen. Immutable — the
/// controller swaps in a new instance whenever a value changes. Unlike
/// [ServiceRequestFilter], there is no "type" field — the reference
/// Filter screen only offers Status / Priority / Due-Date.
class WorkOrderFilter {
  const WorkOrderFilter({
    this.status,
    this.priority,
    this.dueDateStart,
    this.dueDateEnd,
  });

  final WorkOrderStatus? status;
  final ServiceRequestPriority? priority;
  final DateTime? dueDateStart;
  final DateTime? dueDateEnd;

  bool get isEmpty =>
      status == null &&
      priority == null &&
      dueDateStart == null &&
      dueDateEnd == null;

  WorkOrderFilter copyWith({
    WorkOrderStatus? status,
    bool clearStatus = false,
    ServiceRequestPriority? priority,
    bool clearPriority = false,
    DateTime? dueDateStart,
    DateTime? dueDateEnd,
    bool clearDueDate = false,
  }) {
    return WorkOrderFilter(
      status: clearStatus ? null : (status ?? this.status),
      priority: clearPriority ? null : (priority ?? this.priority),
      dueDateStart: clearDueDate ? null : (dueDateStart ?? this.dueDateStart),
      dueDateEnd: clearDueDate ? null : (dueDateEnd ?? this.dueDateEnd),
    );
  }
}