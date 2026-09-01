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
  }) : raisedAt = raisedAt ?? dueDate ?? DateTime.now();

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

  /// Null when the server didn't return a priority reference for this
  /// ticket at all — genuinely no data, distinct from an actual
  /// "No Priority" value the server can return. Renders as "--".
  final ServiceRequestPriority? priority;
  final WorkOrderStatus status;

  /// Discipline/category label as returned by the server (e.g.
  /// "Mechanical", "Landscape", "Cleaning") — org-defined and open-ended,
  /// so it's kept as the raw display string rather than a fixed enum.
  /// Empty when the server didn't return one; renders as "--".
  final String discipline;

  /// Null when the server didn't return a type reference for this
  /// ticket at all. Renders as "--".
  final WorkOrderMaintenanceType? maintenanceType;

  /// Null when the server didn't return a due date for this ticket at
  /// all. The "Due: ..." pill is omitted entirely rather than showing a
  /// fabricated date.
  final DateTime? dueDate;

  /// Null renders as "Not Assigned".
  final String? assignedTechnician;

  /// Date + time shown at the top of the Detail View's Overview tab.
  /// Falls back to [dueDate], then to now, when not supplied.
  final DateTime raisedAt;
}
