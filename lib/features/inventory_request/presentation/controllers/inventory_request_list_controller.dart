import 'package:get/get.dart';
import 'package:iungo/core/routes/app_routes.dart';
import 'package:iungo/core/widgets/app_snackbar.dart';
import 'package:iungo/features/inventory_request/data/datasources/inventory_request_exceptions.dart';
import 'package:iungo/features/inventory_request/data/inventory_request_repository.dart';
import 'package:iungo/features/inventory_request/domain/entities/inventory_request.dart';
import 'package:iungo/features/inventory_request/domain/entities/inventory_request_filter.dart';
import 'package:iungo/features/inventory_request/domain/entities/inventory_reservation_status.dart';
import 'package:iungo/features/inventory_request/presentation/controllers/inventory_request_filter_controller_like.dart';
import 'package:iungo/features/service_request/domain/entities/pick_list_option.dart';

/// Drives the "Inventory Request → Awaiting Client Approval" screen —
/// pagination, search, filtering, refresh, and error handling — all
/// backed by the live [InventoryRequestRepository]. Mirrors
/// [WorkOrderClosureApprovalListController] exactly, adapted to
/// Inventory Request's own filter shape (Status + the static Reservation
/// Status, rather than Priority/Due Date).
class InventoryRequestListController extends GetxController
    implements InventoryRequestFilterControllerLike {
  InventoryRequestListController(this._repository);

  final InventoryRequestRepository _repository;

  static const int _perPage = 50;

  /// perPage used for a filtered/find-ticket fetch — one shot rather
  /// than paging, matching the rest of the app's own quickFilter
  /// convention.
  static const int _filteredPerPage = 50;

  /// True only while the very first page is loading (drives the
  /// shimmer/full-screen loading state).
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
  final Rx<InventoryRequestFilter> filter = const InventoryRequestFilter().obs;

  /// Ticket id typed on the "Find Ticket" tab, once "Find Ticket" is
  /// pressed. Combines with [filter] rather than replacing it, matching
  /// the server's own `quickFilter` convention of carrying several field
  /// filters at once.
  @override
  final Rxn<int> findTicketId = Rxn<int>();

  /// Results of the last server-side filtered/search fetch — what the UI
  /// shows whenever [hasActiveFilter] is true.
  final RxList<InventoryRequest> filteredResults = <InventoryRequest>[].obs;

  /// True while a filtered/find-ticket fetch is in flight.
  final RxBool isFilterLoading = false.obs;

  /// True when the last filtered fetch failed outright.
  final RxBool filterHasError = false.obs;

  /// Status options for the Filter screen's dropdown, loaded live from
  /// the `pickList` API — never hardcoded.
  @override
  final RxList<String> statusFilterOptions = <String>[].obs;

  /// Reservation Status options — STATIC by requirement, never fetched.
  @override
  final RxList<InventoryReservationStatus> reservationStatusFilterOptions =
      <InventoryReservationStatus>[].obs;

  final RxBool isLoadingFilterOptions = false.obs;

  // Raw {label, value} pairs behind statusFilterOptions — kept around so
  // a selected label can be translated back to the exact numeric id the
  // server's `quickFilter` expects.
  List<PickListOption> _statusOptionsRaw = const [];

  bool _filterOptionsLoaded = false;

  int _page = 1;

  /// Free-text search term applied on top of the current filter/find
  /// ticket selection — set by the Search screen (or an in-page search
  /// field, if the host page has one) via [applySearch].
  String _search = '';

  @override
  void onInit() {
    super.onInit();
    reservationStatusFilterOptions.assignAll(
      InventoryReservationStatusX.filterOptions,
    );
    // Fire-and-forget: warms the repository's status-label cache early
    // so cards don't sit on the raw slug value any longer than
    // necessary, and the Filter screen's Status dropdown is ready by
    // the time it's opened.
    ensureFilterOptionsLoaded();
    _loadFirstPage();
  }

  Future<void> _loadFirstPage() async {
    isLoading.value = true;
    hasError.value = false;
    _page = 1;
    try {
      final result =
          await _repository.fetchPage(page: _page, perPage: _perPage);
      final resolved = await _repository.resolveStatusLabels(result.requests);
      _repository.replaceWithPage(resolved);
      hasMore.value = result.rawCount >= _perPage;
    } catch (_) {
      hasError.value = true;
      hasMore.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Called when the list is scrolled near its end. Fetches the next
  /// page and appends it — a no-op while already loading, once a page
  /// comes back short, or while a filter/search narrows the view
  /// (pagination only drives the base, unfiltered list).
  Future<void> loadMore() async {
    if (isLoading.value || isLoadingMore.value || !hasMore.value) return;
    if (hasActiveFilter) return;

    isLoadingMore.value = true;
    try {
      final nextPage = _page + 1;
      final result =
          await _repository.fetchPage(page: nextPage, perPage: _perPage);
      final resolved = await _repository.resolveStatusLabels(result.requests);
      _repository.appendPage(resolved);
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

  /// Fetches the Status pick list for the Filter screen's dropdown, once
  /// per session (cached in the repository too, so re-opening the
  /// Filter screen is instant). Safe to call every time the Filter
  /// screen opens — a no-op once it has succeeded before.
  @override
  Future<void> ensureFilterOptionsLoaded() async {
    if (_filterOptionsLoaded || isLoadingFilterOptions.value) return;

    isLoadingFilterOptions.value = true;
    try {
      _statusOptionsRaw = await _repository.fetchStatusOptions();
      final statuses =
          _statusOptionsRaw.map((o) => o.label).toSet().toList();
      statusFilterOptions.assignAll(statuses);
      _filterOptionsLoaded = true;
    } catch (_) {
      // Server list unavailable — leave it empty; the Filter screen's
      // Status dropdown will simply show no options until it can be
      // retried (there's no sensible client-side fallback for a value
      // that's explicitly required to come from the server).
    } finally {
      isLoadingFilterOptions.value = false;
    }
  }

  /// The list the UI should render — the server-filtered results while a
  /// filter/find-ticket/search is active, otherwise the normal paginated
  /// list.
  List<InventoryRequest> get filteredInventoryRequests {
    if (!hasActiveFilter) return _repository.inventoryRequests;
    return filteredResults;
  }

  @override
  void applyFilter(InventoryRequestFilter newFilter) {
    filter.value = newFilter;
    _fetchFiltered();
  }

  @override
  void clearFilter() {
    findTicketId.value = null;
    filter.value = const InventoryRequestFilter();
    _search = '';
    filteredResults.clear();
    filterHasError.value = false;
  }

  @override
  void findTicket(int id) {
    findTicketId.value = id;
    _fetchFiltered();
  }

  /// Applies (or clears, when [term] is empty) a free-text search term
  /// on top of the current filter — used by an in-page search field.
  void applySearch(String term) {
    _search = term.trim();
    if (_search.isEmpty && !hasActiveFilter) {
      filteredResults.clear();
      filterHasError.value = false;
      return;
    }
    _fetchFiltered();
  }

  bool get hasActiveFilter =>
      !filter.value.isEmpty || findTicketId.value != null || _search.isNotEmpty;

  /// Re-runs the last filter/find-ticket/search fetch — used by the
  /// retry button if it failed.
  Future<void> retryFilter() => _fetchFiltered();

  /// Hits the server's `quickFilter`/`search` API with whatever
  /// combination of Status/Reservation Status/id/free-text search is
  /// currently selected — reuses the same `quickFilter` JSON convention
  /// as every other list in this app (see
  /// [InventoryRequestRemoteDataSource]).
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

    final reservationStatus = filter.value.reservationStatus;
    if (reservationStatus != null) {
      quickFilter['reservationStatus'] = [reservationStatus.id];
    }

    final createdDateStart = filter.value.createdDateStart;
    final createdDateEnd = filter.value.createdDateEnd;
    if (createdDateStart != null && createdDateEnd != null) {
      final startOfDay = DateTime(
        createdDateStart.year,
        createdDateStart.month,
        createdDateStart.day,
      );
      final endOfDay = DateTime(
        createdDateEnd.year,
        createdDateEnd.month,
        createdDateEnd.day,
        23,
        59,
        59,
      );
      quickFilter['createdTime'] = [
        startOfDay.millisecondsSinceEpoch.toString(),
        endOfDay.millisecondsSinceEpoch.toString(),
      ];
    }

    final ticketId = findTicketId.value;
    if (ticketId != null) {
      quickFilter['id'] = [ticketId.toString()];
    }

    isFilterLoading.value = true;
    filterHasError.value = false;
    try {
      final result = await _repository.fetchFiltered(
        page: 1,
        perPage: _filteredPerPage,
        quickFilter: quickFilter,
        search: _search.isEmpty ? null : _search,
      );
      final resolved = await _repository.resolveStatusLabels(result.requests);
      filteredResults.assignAll(_applyClientSideSafetyNet(resolved));
    } catch (e) {
      filteredResults.clear();
      filterHasError.value = true;
      final message =
          e is InventoryRequestException ? e.message : 'something_went_wrong'.tr;
      AppSnackbar.showError(message);
    } finally {
      isFilterLoading.value = false;
    }
  }

  List<String> _statusIdsFor(String status) {
    return _statusOptionsRaw
        .where((o) => o.label == status)
        .map((o) => o.value.toString())
        .toList();
  }

  /// Narrows [requests] down to what the currently-selected Reservation
  /// Status / Created Date filter actually asks for.
  ///
  /// This is a safety net on top of the server's own `quickFilter`: the
  /// exact backend field names for these two filters couldn't be
  /// confirmed against a live session (see
  /// `InventoryRequestRemoteDataSource`'s `reservationStatus`/
  /// `createdTime` quickFilter keys), so if the server silently ignores
  /// either one and returns an unfiltered page, this still guarantees
  /// what's shown on screen matches the selection. It can only narrow
  /// the page already returned, never restore rows a wrong server-side
  /// key excluded — the underlying key names should still be verified
  /// against the real API before this net can be safely removed.
  List<InventoryRequest> _applyClientSideSafetyNet(
    List<InventoryRequest> requests,
  ) {
    var result = requests;

    final reservationStatus = filter.value.reservationStatus;
    if (reservationStatus != null) {
      result =
          result.where((r) => r.reservationStatus == reservationStatus).toList();
    }

    final start = filter.value.createdDateStart;
    final end = filter.value.createdDateEnd;
    if (start != null && end != null) {
      final startOfDay = DateTime(start.year, start.month, start.day);
      final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);
      result = result
          .where((r) =>
              !r.createdTime.isBefore(startOfDay) &&
              !r.createdTime.isAfter(endOfDay))
          .toList();
    }

    return result;
  }

  void onNotificationsTap() {
    Get.toNamed(AppRoutes.notifications);
  }
}
