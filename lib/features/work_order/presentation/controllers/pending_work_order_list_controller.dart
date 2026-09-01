import 'package:get/get.dart';
import 'package:iungo/core/routes/app_routes.dart';
import 'package:iungo/features/service_request/domain/entities/service_request_priority.dart';
import 'package:iungo/features/work_order/data/pending_work_order_seed_data.dart';
import 'package:iungo/features/work_order/domain/entities/pending_approval_kind.dart';
import 'package:iungo/features/work_order/domain/entities/work_order.dart';
import 'package:iungo/features/work_order/domain/entities/work_order_filter.dart';
import 'package:iungo/features/work_order/domain/entities/work_order_status.dart';
import 'package:iungo/features/work_order/presentation/controllers/work_order_filter_controller_like.dart';

/// Drives the "Awaiting for Pause Approval" / "Awaiting Approval for
/// Closure" screens — same list UI, filters, and Detail View as the real
/// "My Work Orders" screen, but backed by a small local seed list
/// instead of an API call. Filtering (status/priority/due date/find
/// ticket) runs entirely in memory. Swap this out for a real
/// API-backed controller once the corresponding endpoint exists.
class PendingWorkOrderListController extends GetxController
    implements WorkOrderFilterControllerLike {
  PendingWorkOrderListController(this.kind);

  final PendingApprovalKind kind;

  final RxBool isLoading = false.obs;
  final RxBool isFilterLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxBool filterHasError = false.obs;

  @override
  final Rx<WorkOrderFilter> filter = const WorkOrderFilter().obs;

  @override
  final Rxn<int> findTicketId = Rxn<int>();

  @override
  final RxList<WorkOrderStatus> statusFilterOptions =
      <WorkOrderStatus>[].obs;

  @override
  final RxList<ServiceRequestPriority> priorityFilterOptions =
      <ServiceRequestPriority>[].obs;

  late final List<WorkOrder> _seed = buildPendingWorkOrderSeed(kind);

  final RxList<WorkOrder> _visible = <WorkOrder>[].obs;

  @override
  void onInit() {
    super.onInit();
    statusFilterOptions.assignAll(WorkOrderStatusX.filterOptions);
    priorityFilterOptions.assignAll(ServiceRequestPriority.values);
    _visible.assignAll(_seed);
  }

  List<WorkOrder> get filteredWorkOrders => _visible;

  bool get hasActiveFilter => !filter.value.isEmpty || findTicketId.value != null;

  @override
  Future<void> ensureFilterOptionsLoaded() async {
    // Fixed enum lists — nothing to fetch for the static lists.
  }

  @override
  void applyFilter(WorkOrderFilter newFilter) {
    filter.value = newFilter;
    _recompute();
  }

  @override
  void clearFilter() {
    findTicketId.value = null;
    filter.value = const WorkOrderFilter();
    _recompute();
  }

  @override
  void findTicket(int serialNumber) {
    findTicketId.value = serialNumber;
    _recompute();
  }

  Future<void> retryFilter() async => _recompute();

  Future<void> reload() async {
    _visible.assignAll(_seed);
  }

  void _recompute() {
    var results = _seed.toList();

    final status = filter.value.status;
    if (status != null) {
      results = results.where((w) => w.status == status).toList();
    }

    final priority = filter.value.priority;
    if (priority != null) {
      results = results.where((w) => w.priority == priority).toList();
    }

    final start = filter.value.dueDateStart;
    final end = filter.value.dueDateEnd;
    if (start != null && end != null) {
      final startOfDay = DateTime(start.year, start.month, start.day);
      final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);
      results = results.where((w) {
        final due = w.dueDate;
        return due != null && !due.isBefore(startOfDay) && !due.isAfter(endOfDay);
      }).toList();
    }

    final serialNumber = findTicketId.value;
    if (serialNumber != null) {
      results = results.where((w) => w.serialNumber == serialNumber).toList();
    }

    _visible.assignAll(results);
  }

  void onNotificationsTap() {
    Get.toNamed(AppRoutes.notifications);
  }
}
