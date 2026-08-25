import 'package:get/get.dart';
import 'package:iungo/features/service_request/domain/entities/service_request_priority.dart';
import 'package:iungo/features/work_order/domain/entities/work_order.dart';
import 'package:iungo/features/work_order/domain/entities/work_order_attachment.dart';
import 'package:iungo/features/work_order/domain/entities/work_order_discipline.dart';
import 'package:iungo/features/work_order/domain/entities/work_order_maintenance_type.dart';
import 'package:iungo/features/work_order/domain/entities/work_order_status.dart';

/// Single in-memory source of truth for "My Work Orders".
///
/// No confirmed live API for this module yet (unlike Service Requests),
/// so — matching how this app's Service Request feature itself started —
/// this holds a fixed seed list and does status/priority/due-date
/// filtering and text search locally. [fetchPage]/[fetchFiltered] keep
/// the same async shape the real API would have, so swapping in a real
/// `WorkOrderRemoteDataSource` later is a drop-in change that doesn't
/// touch the controllers.
class WorkOrderRepository extends GetxService {
  final RxList<WorkOrder> workOrders = <WorkOrder>[].obs;

  bool _seeded = false;

  /// Simulates the initial list fetch (drives the shimmer briefly, like
  /// the reference video).
  Future<List<WorkOrder>> fetchPage() async {
    await Future.delayed(const Duration(milliseconds: 700));
    if (!_seeded) {
      workOrders.assignAll(_seedData());
      _seeded = true;
    }
    return workOrders;
  }

  /// Applies status/priority server-side-style filtering plus a local
  /// due-date range narrow — same two-step shape
  /// [ServiceRequestListController] uses for its own quickFilter, kept
  /// here so a real API can later replace just the status/priority step.
  Future<List<WorkOrder>> fetchFiltered({
    WorkOrderStatus? status,
    ServiceRequestPriority? priority,
    DateTime? dueDateStart,
    DateTime? dueDateEnd,
    int? ticketId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return workOrders.where((wo) {
      if (status != null && wo.status != status) return false;
      if (priority != null && wo.priority != priority) return false;
      if (ticketId != null && wo.id != ticketId) return false;
      if (dueDateStart != null && wo.dueDate.isBefore(dueDateStart)) {
        return false;
      }
      if (dueDateEnd != null &&
          wo.dueDate.isAfter(dueDateEnd.add(const Duration(days: 1)))) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Local text search across id / subject / description — mirrors the
  /// scopes offered on the Search screen.
  Future<List<WorkOrder>> search({
    required String query,
    required bool byId,
    required bool bySubject,
    required bool byDescription,
  }) async {
    await Future.delayed(const Duration(milliseconds: 350));
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return const [];

    return workOrders.where((wo) {
      if (byId) return wo.id.toString().contains(trimmed);
      if (bySubject) return wo.title.toLowerCase().contains(trimmed);
      if (byDescription) {
        return wo.description.toLowerCase().contains(trimmed);
      }
      // All Fields
      return wo.id.toString().contains(trimmed) ||
          wo.title.toLowerCase().contains(trimmed) ||
          wo.description.toLowerCase().contains(trimmed);
    }).toList();
  }

  List<WorkOrder> _seedData() {
    final today = DateTime.now();
    DateTime onDay(int daysFromToday, [int hour = 18, int minute = 0]) {
      final d = today.add(Duration(days: daysFromToday));
      return DateTime(d.year, d.month, d.day, hour, minute);
    }

    return [
      WorkOrder(
        id: 1411775,
        title: 'Fix loose toilet seat cover',
        description: 'Fix loose toilet seat cover',
        requester: 'Syed Abdul Sattar',
        site: 'Diriyah At Turaif',
        priority: ServiceRequestPriority.routine,
        status: WorkOrderStatus.assigned,
        discipline: WorkOrderDiscipline.mechanical,
        maintenanceType: WorkOrderMaintenanceType.proactive,
        dueDate: onDay(0),
        assignedTechnician: 'Sarwar',
      ),
      WorkOrder(
        id: 1411774,
        title: 'Clean shoe rack',
        description: 'Clean shoe rack',
        requester: 'Syed Abdul Sattar',
        site: 'Diriyah At Turaif',
        priority: ServiceRequestPriority.routine,
        status: WorkOrderStatus.assigned,
        discipline: WorkOrderDiscipline.cleaning,
        maintenanceType: WorkOrderMaintenanceType.corrective,
        dueDate: onDay(0),
        assignedTechnician: 'Umesh Vithal',
      ),
      WorkOrder(
        id: 1411772,
        title: 'Install snake traps',
        description: 'Install snake traps',
        requester: 'Syed Abdul Sattar',
        site: 'Diriyah At Turaif',
        priority: ServiceRequestPriority.routine,
        status: WorkOrderStatus.workInProgress,
        discipline: WorkOrderDiscipline.pestControl,
        maintenanceType: WorkOrderMaintenanceType.proactive,
        dueDate: onDay(0),
        assignedTechnician: 'Neil Silva',
        tasksCompleted: 1,
        tasksTotal: 3,
      ),
      WorkOrder(
        id: 1411771,
        title: 'Cleaning',
        description: 'Cleaning',
        requester: 'Mohammad Shamsul Alam',
        site: 'Diriyah At Turaif',
        priority: ServiceRequestPriority.routine,
        status: WorkOrderStatus.awaitingClosureApprovalFromClient,
        discipline: WorkOrderDiscipline.cleaning,
        maintenanceType: WorkOrderMaintenanceType.proactive,
        dueDate: onDay(0),
        assignedTechnician: 'Mohammad Shamsul Alam',
      ),
      WorkOrder(
        id: 1411769,
        title: 'Wall Repaint',
        description: 'Wall Repaint at VRC',
        requester: 'Gladson Aby',
        site: 'Diriyah At Turaif',
        priority: ServiceRequestPriority.routine,
        status: WorkOrderStatus.assigned,
        discipline: WorkOrderDiscipline.civil,
        maintenanceType: WorkOrderMaintenanceType.corrective,
        dueDate: onDay(0),
        assignedTechnician: 'Jubeer Hussain',
      ),
      WorkOrder(
        id: 1400270,
        title: 'Scrubber 50P Cleaning Robot',
        description: '',
        requester: 'CIT Group',
        site: 'Diriyah At Turaif',
        priority: ServiceRequestPriority.routine,
        status: WorkOrderStatus.workInProgress,
        discipline: WorkOrderDiscipline.cleaning,
        maintenanceType: WorkOrderMaintenanceType.preventive,
        dueDate: onDay(0),
        raisedAt: DateTime(today.year, 8, 9, 2, 40),
        attachments: const [
          WorkOrderAttachment(
            name: '1886232_robot_task_report.png',
            extension: 'PNG',
            sizeLabel: '489 KB',
            dateLabel: 'Yesterday',
            assetPath: 'assets/images/png/sample_robot_task_report.png',
          ),
        ],
      ),
      WorkOrder(
        id: 1411785,
        title: 'Pest control activity',
        description: 'Pest control activity',
        requester: 'Syed Abdul Sattar',
        site: 'Diriyah At Turaif',
        priority: ServiceRequestPriority.routine,
        status: WorkOrderStatus.awaitingClosureApprovalFromClient,
        discipline: WorkOrderDiscipline.pestControl,
        maintenanceType: WorkOrderMaintenanceType.proactive,
        dueDate: onDay(0),
        assignedTechnician: 'Neil Silva',
      ),
      WorkOrder(
        id: 1412530,
        title: 'Remove Dead Pigeon Feather',
        description: 'Remove Dead Pigeon Feather',
        requester: 'Gladson Aby',
        site: 'Diriyah At Turaif',
        priority: ServiceRequestPriority.routine,
        status: WorkOrderStatus.assigned,
        discipline: WorkOrderDiscipline.cleaning,
        maintenanceType: WorkOrderMaintenanceType.proactive,
        dueDate: onDay(1),
        raisedAt: DateTime(today.year, today.month, today.day, 17, 1),
        assignedTechnician: 'Mohammad Shamsul Alam',
        attachments: const [
          WorkOrderAttachment(
            name: '3.jpg',
            extension: 'JPG',
            sizeLabel: '110 KB',
            dateLabel: 'Today',
          ),
        ],
      ),
      WorkOrder(
        id: 1412529,
        title: 'Wall Repaint',
        description: 'Wall Repaint',
        requester: 'Gladson Aby',
        site: 'Diriyah At Turaif',
        priority: ServiceRequestPriority.routine,
        status: WorkOrderStatus.assigned,
        discipline: WorkOrderDiscipline.civil,
        maintenanceType: WorkOrderMaintenanceType.corrective,
        dueDate: onDay(1),
        assignedTechnician: 'MD Saiful Islam',
      ),
      WorkOrder(
        id: 1401362,
        title: 'Scrubber 50P Cleaning Robot',
        description: '',
        requester: 'CIT Group',
        site: 'Diriyah At Turaif',
        priority: ServiceRequestPriority.routine,
        status: WorkOrderStatus.workInProgress,
        discipline: WorkOrderDiscipline.cleaning,
        maintenanceType: WorkOrderMaintenanceType.preventive,
        dueDate: onDay(1),
      ),
    ];
  }
}