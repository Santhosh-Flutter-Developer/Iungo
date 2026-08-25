import 'package:get/get.dart';
import 'package:iungo/core/routes/app_routes.dart';
import 'package:iungo/features/service_request/domain/entities/service_request_priority.dart';
import 'package:iungo/features/work_order/data/work_order_repository.dart';
import 'package:iungo/features/work_order/domain/entities/work_order.dart';
import 'package:iungo/features/work_order/domain/entities/work_order_filter.dart';
import 'package:iungo/features/work_order/domain/entities/work_order_status.dart';

class WorkOrderListController extends GetxController {
  WorkOrderListController(this._repository);

  final WorkOrderRepository _repository;

  /// True only while the first load is running (drives the shimmer).
  final RxBool isLoading = true.obs;
  final RxBool hasError = false.obs;

  final Rx<WorkOrderFilter> filter = const WorkOrderFilter().obs;

  /// Ticket id typed on the "Find Ticket" tab, once "Find Ticket" is
  /// pressed. Combines with [filter] rather than replacing it.
  final Rxn<int> findTicketId = Rxn<int>();

  /// Results of the last filter/find-ticket lookup — shown whenever
  /// [hasActiveFilter] is true.
  final RxList<WorkOrder> filteredResults = <WorkOrder>[].obs;
  final RxBool isFilterLoading = false.obs;
  final RxBool filterHasError = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadFirstPage();
  }

  Future<void> _loadFirstPage() async {
    isLoading.value = true;
    hasError.value = false;
    try {
      await _repository.fetchPage();
    } catch (_) {
      hasError.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> reload() => _loadFirstPage();

  List<WorkOrder> get baseList => _repository.workOrders;

  /// The list the UI should render — the filtered results while a
  /// filter/find-ticket is active, otherwise the full base list.
  List<WorkOrder> get filteredWorkOrders {
    if (!hasActiveFilter) return baseList;
    return filteredResults;
  }

  void applyFilter(WorkOrderFilter newFilter) {
    filter.value = newFilter;
    _fetchFiltered();
  }

  void clearFilter() {
    findTicketId.value = null;
    filter.value = const WorkOrderFilter();
    filteredResults.clear();
    filterHasError.value = false;
  }

  void findTicket(int id) {
    findTicketId.value = id;
    _fetchFiltered();
  }

  bool get hasActiveFilter =>
      !filter.value.isEmpty || findTicketId.value != null;

  Future<void> retryFilter() => _fetchFiltered();

  Future<void> _fetchFiltered() async {
    if (!hasActiveFilter) {
      filteredResults.clear();
      filterHasError.value = false;
      return;
    }

    isFilterLoading.value = true;
    filterHasError.value = false;
    try {
      final WorkOrderStatus? status = filter.value.status;
      final ServiceRequestPriority? priority = filter.value.priority;
      final result = await _repository.fetchFiltered(
        status: status,
        priority: priority,
        dueDateStart: filter.value.dueDateStart,
        dueDateEnd: filter.value.dueDateEnd,
        ticketId: findTicketId.value,
      );
      filteredResults.assignAll(result);
    } catch (_) {
      filteredResults.clear();
      filterHasError.value = true;
    } finally {
      isFilterLoading.value = false;
    }
  }

  void onNotificationsTap() {
    Get.toNamed(AppRoutes.notifications);
  }
}