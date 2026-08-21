import 'package:get/get.dart';
import 'package:iungo/core/routes/app_routes.dart';
import 'package:iungo/features/service_request/data/service_request_repository.dart';
import 'package:iungo/features/service_request/domain/entities/pick_list_option.dart';
import 'package:iungo/features/service_request/domain/entities/service_request.dart';
import 'package:iungo/features/service_request/domain/entities/service_request_filter.dart';
import 'package:iungo/features/service_request/domain/entities/service_request_priority.dart';
import 'package:iungo/features/service_request/domain/entities/service_request_status.dart';

class ServiceRequestListController extends GetxController {
  ServiceRequestListController(this._repository);

  final ServiceRequestRepository _repository;

  static const int _perPage = 10;

  /// perPage used for a filtered/find-ticket fetch — matches the real
  /// app's own quickFilter requests (confirmed via Postman capture),
  /// which always ask for 50 in one shot rather than paging by 10.
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

  final Rx<ServiceRequestFilter> filter = const ServiceRequestFilter().obs;

  /// Ticket id typed on the "Find Ticket" tab, once "Find Ticket" is
  /// pressed. Combines with [filter] rather than replacing it — the real
  /// app's own `quickFilter` requests can carry `moduleState` /
  /// `priority_serviceRequest` / `id` all at once.
  final Rxn<int> findTicketId = Rxn<int>();

  /// Results of the last server-side `quickFilter` fetch — what the UI
  /// shows whenever [hasActiveFilter] is true.
  final RxList<ServiceRequest> filteredResults = <ServiceRequest>[].obs;

  /// True while a filtered/find-ticket fetch is in flight.
  final RxBool isFilterLoading = false.obs;

  /// True when the last filtered fetch failed outright.
  final RxBool filterHasError = false.obs;

  /// Status/Priority options for the Filter screen's dropdowns, fetched
  /// live from the `pickList` APIs. Falls back to the fixed enum lists
  /// (see [ServiceRequestStatusX.filterOptions] / [ServiceRequestPriority.values])
  /// if the fetch fails, so the filter stays usable offline.
  final RxList<ServiceRequestStatus> statusFilterOptions =
      <ServiceRequestStatus>[].obs;
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
      final result = await _repository.fetchPage(
        page: _page,
        perPage: _perPage,
      );
      _repository.replaceWithPage(result.tickets);
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
  /// page comes back short, or while a ticket-id/filter narrows the view
  /// (pagination only drives the base, unfiltered list).
  Future<void> loadMore() async {
    if (isLoading.value || isLoadingMore.value || !hasMore.value) return;
    if (hasActiveFilter) return;

    isLoadingMore.value = true;
    try {
      final nextPage = _page + 1;
      final result = await _repository.fetchPage(
        page: nextPage,
        perPage: _perPage,
      );
      _repository.appendPage(result.tickets);
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
          .map((o) => ServiceRequestStatusX.fromApiLabel(o.label))
          .toSet()
          .toList();
      final priorities = _priorityOptionsRaw
          .map((o) => ServiceRequestPriorityX.fromApiLabel(o.label))
          .toSet()
          .toList();

      statusFilterOptions.assignAll(
        statuses.isNotEmpty ? statuses : ServiceRequestStatusX.filterOptions,
      );
      priorityFilterOptions.assignAll(
        priorities.isNotEmpty ? priorities : ServiceRequestPriority.values,
      );
      _filterOptionsLoaded = true;
    } catch (_) {
      // Server list unavailable — fall back to the fixed enum lists so
      // the Filter screen still works.
      statusFilterOptions.assignAll(ServiceRequestStatusX.filterOptions);
      priorityFilterOptions.assignAll(ServiceRequestPriority.values);
      _filterOptionsLoaded = true;
    } finally {
      isLoadingFilterOptions.value = false;
    }
  }

  /// The list the UI should render — the server-filtered results while a
  /// filter/find-ticket is active, otherwise the normal paginated list.
  List<ServiceRequest> get filteredTickets {
    if (!hasActiveFilter) return _repository.tickets;

    final f = filter.value;
    if (f.dueDateStart == null && f.dueDateEnd == null) {
      return filteredResults;
    }

    // Due-date range isn't part of the server's `quickFilter` schema (not
    // present in any captured request), so it's narrowed locally on top
    // of the server-filtered results.
    return filteredResults.where((t) {
      if (f.dueDateStart != null && t.dueDate.isBefore(f.dueDateStart!)) {
        return false;
      }
      if (f.dueDateEnd != null &&
          t.dueDate.isAfter(f.dueDateEnd!.add(const Duration(days: 1)))) {
        return false;
      }
      return true;
    }).toList();
  }

  void applyFilter(ServiceRequestFilter newFilter) {
    filter.value = newFilter;
    _fetchFiltered();
  }

  void clearFilter() {
    findTicketId.value = null;
    filter.value = const ServiceRequestFilter();
    filteredResults.clear();
    filterHasError.value = false;
  }

  void findTicket(int id) {
    findTicketId.value = id;
    _fetchFiltered();
  }

  bool get hasActiveFilter => !filter.value.isEmpty || findTicketId.value != null;

  /// Re-runs the last filter/find-ticket fetch — used by the retry
  /// button if it failed.
  Future<void> retryFilter() => _fetchFiltered();

  /// Hits the server's `quickFilter` API with whatever combination of
  /// status/priority/ticket-id is currently selected — mirrors the exact
  /// requests captured from the real app via Postman, e.g.:
  ///
  ///   quickFilter={"moduleState":{"value":["2355"]},
  ///                "priority_serviceRequest":{"value":["43"]},
  ///                "id":{"value":["292"]}}
  Future<void> _fetchFiltered() async {
    if (!hasActiveFilter) {
      filteredResults.clear();
      filterHasError.value = false;
      return;
    }

    final quickFilter = <String, List<String>>{};

    final status = filter.value.status;
    if (status != null) {
      final ids = _statusIdsFor(status);
      if (ids.isNotEmpty) quickFilter['moduleState'] = ids;
    }

    final priority = filter.value.priority;
    if (priority != null) {
      final ids = _priorityIdsFor(priority);
      if (ids.isNotEmpty) quickFilter['priority_serviceRequest'] = ids;
    }

    final ticketId = findTicketId.value;
    if (ticketId != null) {
      quickFilter['id'] = [ticketId.toString()];
    }

    isFilterLoading.value = true;
    filterHasError.value = false;
    try {
      final result = await _repository.fetchPage(
        page: 1,
        perPage: _filteredPerPage,
        quickFilter: quickFilter,
      );
      filteredResults.assignAll(result.tickets);
    } catch (_) {
      filteredResults.clear();
      filterHasError.value = true;
    } finally {
      isFilterLoading.value = false;
    }
  }

  List<String> _statusIdsFor(ServiceRequestStatus status) {
    return _statusOptionsRaw
        .where((o) => ServiceRequestStatusX.fromApiLabel(o.label) == status)
        .map((o) => o.value.toString())
        .toList();
  }

  List<String> _priorityIdsFor(ServiceRequestPriority priority) {
    return _priorityOptionsRaw
        .where(
          (o) => ServiceRequestPriorityX.fromApiLabel(o.label) == priority,
        )
        .map((o) => o.value.toString())
        .toList();
  }

  void onNotificationsTap() {
    Get.toNamed(AppRoutes.notifications);
  }
}