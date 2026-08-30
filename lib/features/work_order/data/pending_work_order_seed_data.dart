import 'package:iungo/features/service_request/domain/entities/service_request_priority.dart';
import 'package:iungo/features/work_order/domain/entities/pending_approval_kind.dart';
import 'package:iungo/features/work_order/domain/entities/work_order.dart';
import 'package:iungo/features/work_order/domain/entities/work_order_maintenance_type.dart';

/// Local placeholder data for the "Awaiting for Pause Approval" /
/// "Awaiting Approval for Closure" lists — used only until the real
/// backend endpoints for these two views are wired up. IDs are kept in a
/// range that never collides with the real "My Work Orders" API data.
List<WorkOrder> buildPendingWorkOrderSeed(PendingApprovalKind kind) {
  final now = DateTime.now();
  final status = kind.status;
  final isClosure = kind == PendingApprovalKind.closureApproval;

  final titles = isClosure
      ? [
          'AHU Filter Replacement - Block C',
          'Elevator Annual Maintenance',
          'Water Tank Cleaning - Roof',
          'Fire Alarm Panel Servicing',
          'Landscape Irrigation Repair',
        ]
      : [
          'Chiller Plant Inspection',
          'Emergency Generator Test',
          'Sewage Pump Replacement',
          'Lobby Lighting Fault',
          'CCTV Camera Recalibration',
        ];

  final sites = [
    'Tower A - Ground Floor',
    'Tower B - 4th Floor',
    'Parking Basement 1',
    'Main Building - Roof',
    'Community Center',
  ];

  final requesters = [
    'Ahmed Al Farsi',
    'Sara Al Nuaimi',
    'Omar Hassan',
    'Fatima Al Zaabi',
    'Yousef Al Marri',
  ];

  final disciplines = [
    'Mechanical',
    'Electrical',
    'Plumbing',
    'HVAC',
    'Civil',
  ];

  final priorities = ServiceRequestPriority.values;
  final maintenanceTypes = WorkOrderMaintenanceType.values;

  return List.generate(titles.length, (index) {
    final baseId = isClosure ? 9200000 : 9100000;
    return WorkOrder(
      id: baseId + index,
      serialNumber: baseId + index,
      title: titles[index],
      description:
          'Placeholder work order awaiting client ${isClosure ? 'closure' : 'pause'} approval. '
          'Details will populate automatically once the API is connected.',
      requester: requesters[index % requesters.length],
      site: sites[index % sites.length],
      priority: priorities[index % priorities.length],
      status: status,
      discipline: disciplines[index % disciplines.length],
      maintenanceType: maintenanceTypes[index % maintenanceTypes.length],
      dueDate: now.add(Duration(days: index - 1, hours: 3)),
      assignedTechnician: index.isEven ? requesters[(index + 2) % requesters.length] : null,
      raisedAt: now.subtract(Duration(days: index + 1)),
    );
  });
}
