import 'package:iungo/features/service_request/domain/entities/service_request_priority.dart';
import 'package:iungo/features/work_order/domain/entities/work_order_maintenance_type.dart';
import 'package:iungo/features/work_order/domain/entities/work_order_status.dart';

/// A single "My Work Orders" list-card entry. Backed by the live
/// "My Work Orders" API (see WorkOrderRepository). Also backs the
/// Detail View's Overview tab shown when a card is tapped — the other
/// three tabs (Tasks/Comments/Attachments) are each backed by their own
/// API call and live on [WorkOrderDetailController] instead, since they
/// aren't part of this record.
class WorkOrder {
  WorkOrder({
    required this.id,
    required this.serialNumber,
    required this.title,
    required this.description,
    required this.requester,
    required this.site,
    required this.priority,
    required this.status,
    required this.discipline,
    required this.maintenanceType,
    required this.dueDate,
    this.assignedTechnician,
    DateTime? raisedAt,
  }) : raisedAt = raisedAt ?? dueDate;

  /// Internal Facilio primary key — used only for API calls, never
  /// shown to the user (that's [serialNumber]).
  final int id;

  /// The ticket number shown on every card/detail screen (e.g. "#
  /// 1415033") and used to look a ticket up on the Find Ticket tab.
  /// Deliberately distinct from [id]/`localId` — the server's own
  /// `quickFilter` lookups key on this field.
  final int serialNumber;
  final String title;
  final String description;
  final String requester;
  final String site;
  final ServiceRequestPriority priority;
  final WorkOrderStatus status;

  /// Discipline/category label as returned by the server (e.g.
  /// "Mechanical", "Landscape", "Cleaning") — org-defined and open-ended,
  /// so it's kept as the raw display string rather than a fixed enum.
  final String discipline;
  final WorkOrderMaintenanceType maintenanceType;
  final DateTime dueDate;

  /// Null renders as "Not Assigned".
  final String? assignedTechnician;

  /// Date + time shown at the top of the Detail View's Overview tab.
  /// Falls back to [dueDate] (midnight) when not supplied.
  final DateTime raisedAt;
}
