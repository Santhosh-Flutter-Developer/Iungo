import 'package:get/get.dart';
import 'package:iungo/core/routes/app_routes.dart';
import 'package:iungo/core/widgets/app_snackbar.dart';
import 'package:iungo/features/service_request/domain/entities/pick_list_option.dart';
import 'package:iungo/features/service_request/domain/entities/service_request_priority.dart';
import 'package:iungo/features/work_order/data/datasources/work_order_exceptions.dart';
import 'package:iungo/features/work_order/data/work_order_closure_approval_repository.dart';
import 'package:iungo/features/work_order/domain/entities/work_order.dart';
import 'package:iungo/features/work_order/domain/entities/work_order_filter.dart';
import 'package:iungo/features/work_order/domain/entities/work_order_status.dart';
import 'package:iungo/features/work_order/presentation/controllers/work_order_filter_controller_like.dart';

/// Drives the "Awaiting Approval for Closure" screen. Mirrors
/// [WorkOrderListController] ("All Work Orders") exactly — same
/// pagination, search, filter, refresh, and error-handling behavior —
/// backed by [WorkOrderClosureApprovalRepository] instead of the shared
/// "All Work Orders" repository.
class WorkOrderClosureApprovalListController extends GetxController
    implements WorkOrderFilterControllerLike {
  WorkOrderClosureApprovalListController(this._repository);

  final WorkOrderClosureApprovalRepository _repository;

  static const int _perPage = 10;

  /// perPage used for a filtered/find-ticket fetch — matches the real
  /// app's own quickFilter requests, which ask for 50 in one shot rather
  /// than paging by 10.
  static const int _filteredPerPage = 50;

  /// True only while the very first page is loading (drives the shimmer).
  final RxBool isLoading = true.obs;

  /// True while a subsequent page is being fetched (drives the small
  /// spinner at the bottom of the list during infinite scroll).
  final RxBool isLoadingMore = false.obs;

  /// True when the first-page load failed outright (drives the
  /// full-screen error/retry state).
  final RxBool hasError = false.obs;

  /// False once a page comes back with fewer than [_perPage] items —
  /// i.e. there's nothing further to fetch.
  final RxBool hasMore = true.obs;

  @override
  final Rx<WorkOrderFilter> filter = const WorkOrderFilter().obs;

  /// Ticket number (the `serialNumber` shown on every card — never
  /// `id`/`localId`) typed on the "Find Ticket" tab, once "Find Ticket"
  /// is pressed. Combines with [filter] rather than replacing it — the
  /// real app's own `quickFilter` requests can carry `priority` /
  /// `moduleState` / `dueDate` / `serialNumber` all at once.
  @override
  final Rxn<int> findTicketId = Rxn<int>();

  /// Results of the last server-side `quickFilter` fetch — what the UI
  /// shows whenever [hasActiveFilter] is true.
  final RxList<WorkOrder> filteredResults = <WorkOrder>[].obs;

  /// True while a filtered/find-ticket fetch is in flight.
  final RxBool isFilterLoading = false.obs;

  /// True when the last filtered fetch failed outright.
  final RxBool filterHasError = false.obs;

  /// Status/Priority options for the Filter screen's dropdowns, fetched
  /// live from the `pickList` APIs. Falls back to the fixed enum lists
  /// if the fetch fails, so the filter stays usable offline.
  @override
  final RxList<WorkOrderStatus> statusFilterOptions = <WorkOrderStatus>[].obs;
  @override
  final RxList<ServiceRequestPriority> priorityFilterOptions =
      <ServiceRequestPriority>[].obs;
  final RxBool isLoadingFilterOptions = false.obs;

  // Raw {label, value} pairs behind statusFilterOptions/priorityFilterOptions
  // — kept around so a selected enum can be translated back to the exact
  // numeric id(s) the server's `quickFilter` expects.
  List<PickListOption> _statusOptionsRaw = const [];
  List<PickListOption> _priorityOptionsRaw = const [];

  bool _filterOptionsLoaded = false;

  int _page = 1;

  @override
  void onInit() {
    super.onInit();
    _loadFirstPage();
  }

  Future<void> _loadFirstPage() async {
    isLoading.value = true;
    hasError.value = false;
    _page = 1;
    try {
      final result = await _repository.fetchPage(page: _page, perPage: _perPage);
      _repository.replaceWithPage(result.workOrders);
      hasMore.value = result.rawCount >= _perPage;
    } catch (_) {
      hasError.value = true;
      hasMore.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Called when the list is scrolled near its end. Fetches the next
  /// page of 10 and appends it — a no-op while already loading, once a
  /// page comes back short, or while a ticket-number/filter narrows the
  /// view (pagination only drives the base, unfiltered list).
  Future<void> loadMore() async {
    if (isLoading.value || isLoadingMore.value || !hasMore.value) return;
    if (hasActiveFilter) return;

    isLoadingMore.value = true;
    try {
      final nextPage = _page + 1;
      final result = await _repository.fetchPage(page: nextPage, perPage: _perPage);
      _repository.appendPage(result.workOrders);
      _page = nextPage;
      hasMore.value = result.rawCount >= _perPage;
    } catch (_) {
      // Silently keep [hasMore] as-is so the user can retry by scrolling
      // again; a persistent bottom spinner would be misleading here.
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> reload() => _loadFirstPage();

  /// Fetches the Status/Priority pick lists for the Filter screen's
  /// dropdowns, once per session (cached in the repository too, so
  /// re-opening the Filter screen is instant). Safe to call every time
  /// the Filter screen opens — a no-op once it has succeeded before.
  @override
  Future<void> ensureFilterOptionsLoaded() async {
    if (_filterOptionsLoaded || isLoadingFilterOptions.value) return;

    isLoadingFilterOptions.value = true;
    try {
      final results = await Future.wait([
        _repository.fetchStatusOptions(),
        _repository.fetchPriorityOptions(),
      ]);

      _statusOptionsRaw = results[0];
      _priorityOptionsRaw = results[1];

      final statuses = _statusOptionsRaw
          .map((o) => WorkOrderStatusX.fromApiLabel(o.label))
          .toSet()
          .toList();
      final priorities = _priorityOptionsRaw
          .map((o) => ServiceRequestPriorityX.fromApiLabel(o.label))
          .toSet()
          .toList();

      statusFilterOptions.assignAll(
        statuses.isNotEmpty ? statuses : WorkOrderStatusX.filterOptions,
      );
      priorityFilterOptions.assignAll(
        priorities.isNotEmpty ? priorities : ServiceRequestPriority.values,
      );
      _filterOptionsLoaded = true;
    } catch (_) {
      // Server list unavailable — fall back to the fixed enum lists so
      // the Filter screen still works.
      statusFilterOptions.assignAll(WorkOrderStatusX.filterOptions);
      priorityFilterOptions.assignAll(ServiceRequestPriority.values);
      _filterOptionsLoaded = true;
    } finally {
      isLoadingFilterOptions.value = false;
    }
  }

  /// The list the UI should render — the server-filtered results while a
  /// filter/find-ticket is active, otherwise the normal paginated list.
  List<WorkOrder> get filteredWorkOrders {
    if (!hasActiveFilter) return _repository.workOrders;
    return filteredResults;
  }

  @override
  void applyFilter(WorkOrderFilter newFilter) {
    filter.value = newFilter;
    _fetchFiltered();
  }

  @override
  void clearFilter() {
    findTicketId.value = null;
    filter.value = const WorkOrderFilter();
    filteredResults.clear();
    filterHasError.value = false;
  }

  @override
  void findTicket(int serialNumber) {
    findTicketId.value = serialNumber;
    _fetchFiltered();
  }

  bool get hasActiveFilter => !filter.value.isEmpty || findTicketId.value != null;

  /// Re-runs the last filter/find-ticket fetch — used by the retry
  /// button if it failed.
  Future<void> retryFilter() => _fetchFiltered();

  /// Hits the server's `quickFilter` API with whatever combination of
  /// priority/status/due-date/ticket-number is currently selected —
  /// mirrors the exact requests captured from the real app via Postman,
  /// e.g.:
  ///
  ///   quickFilter={"priority":{"value":["43"]},
  ///                "moduleState":{"value":["147855"]},
  ///                "dueDate":{"value":["1787778000000","1787950799000"]},
  ///                "serialNumber":{"value":["1415033"]}}
  Future<void> _fetchFiltered() async {
    if (!hasActiveFilter) {
      filteredResults.clear();
      filterHasError.value = false;
      return;
    }

    final quickFilter = <String, List<String>>{};

    final priority = filter.value.priority;
    if (priority != null) {
      final ids = _priorityIdsFor(priority);
      if (ids.isNotEmpty) quickFilter['priority'] = ids;
    }

    final status = filter.value.status;
    if (status != null) {
      final ids = _statusIdsFor(status);
      if (ids.isNotEmpty) quickFilter['moduleState'] = ids;
    }

    final dueDateStart = filter.value.dueDateStart;
    final dueDateEnd = filter.value.dueDateEnd;
    if (dueDateStart != null && dueDateEnd != null) {
      final startOfDay =
          DateTime(dueDateStart.year, dueDateStart.month, dueDateStart.day);
      final endOfDay = DateTime(
        dueDateEnd.year,
        dueDateEnd.month,
        dueDateEnd.day,
        23,
        59,
        59,
      );
      quickFilter['dueDate'] = [
        startOfDay.millisecondsSinceEpoch.toString(),
        endOfDay.millisecondsSinceEpoch.toString(),
      ];
    }

    final serialNumber = findTicketId.value;
    if (serialNumber != null) {
      quickFilter['serialNumber'] = [serialNumber.toString()];
    }

    isFilterLoading.value = true;
    filterHasError.value = false;
    try {
      final result = await _repository.fetchFiltered(
        page: 1,
        perPage: _filteredPerPage,
        quickFilter: quickFilter,
      );
      filteredResults.assignAll(result.workOrders);
    } catch (e) {
      filteredResults.clear();
      filterHasError.value = true;
      final message =
          e is WorkOrderException ? e.message : 'something_went_wrong'.tr;
      AppSnackbar.showError(message);
    } finally {
      isFilterLoading.value = false;
    }
  }

  List<String> _statusIdsFor(WorkOrderStatus status) {
    return _statusOptionsRaw
        .where((o) => WorkOrderStatusX.fromApiLabel(o.label) == status)
        .map((o) => o.value.toString())
        .toList();
  }

  List<String> _priorityIdsFor(ServiceRequestPriority priority) {
    return _priorityOptionsRaw
        .where((o) => ServiceRequestPriorityX.fromApiLabel(o.label) == priority)
        .map((o) => o.value.toString())
        .toList();
  }

  void onNotificationsTap() {
    Get.toNamed(AppRoutes.notifications);
  }
}
