import 'package:get/get.dart';
import 'package:iungo/features/service_request/domain/entities/pick_list_option.dart';
import 'package:iungo/features/work_order/data/datasources/work_order_picklist_remote_data_source.dart';
import 'package:iungo/features/work_order/data/datasources/work_order_remote_data_source.dart';
import 'package:iungo/features/work_order/data/models/work_order_mapper.dart';
import 'package:iungo/features/work_order/domain/entities/work_order.dart';

/// Single in-memory source of truth for "My Work Orders".
///
/// Registered as a permanent GetxService (not tied to a page's lifecycle)
/// so the list page and search screen share the same [workOrders] list.
///
/// Backed by the real Facilio list API. Pages are fetched by
/// [WorkOrderListController] (which owns the current page/loading state
/// for infinite scroll) and pushed in here via [replaceWithPage] /
/// [appendPage].
class WorkOrderRepository extends GetxService {
  WorkOrderRepository(this._remoteDataSource, this._pickListDataSource);

  final WorkOrderRemoteDataSource _remoteDataSource;
  final WorkOrderPickListRemoteDataSource _pickListDataSource;

  final RxList<WorkOrder> workOrders = <WorkOrder>[].obs;

  // Cached so the Filter screen's dropdowns don't re-hit the pickList
  // APIs every time it's opened during a session.
  List<PickListOption>? _cachedStatusOptions;
  List<PickListOption>? _cachedPriorityOptions;

  /// Fetches one page of the base (unfiltered) "My Work Orders" list.
  Future<WorkOrderListPageResult> fetchPage({
    required int page,
    required int perPage,
  }) {
    return _remoteDataSource.fetchWorkOrders(page: page, perPage: perPage);
  }

  /// Hits the server's `quickFilter`/`search` "My Work Orders" endpoint —
  /// used once a Status/Priority/Due-Date filter or a Find-Ticket lookup
  /// (by `serialNumber`) is active.
  Future<WorkOrderListPageResult> fetchFiltered({
    required int page,
    required int perPage,
    Map<String, List<String>>? quickFilter,
    String? search,
  }) {
    return _remoteDataSource.fetchFilteredWorkOrders(
      page: page,
      perPage: perPage,
      quickFilter: quickFilter,
      search: search,
    );
  }

  Future<List<PickListOption>> fetchStatusOptions({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedStatusOptions != null) {
      return _cachedStatusOptions!;
    }
    final options = await _pickListDataSource.fetchStatusOptions();
    _cachedStatusOptions = options;
    return options;
  }

  Future<List<PickListOption>> fetchPriorityOptions({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedPriorityOptions != null) {
      return _cachedPriorityOptions!;
    }
    final options = await _pickListDataSource.fetchPriorityOptions();
    _cachedPriorityOptions = options;
    return options;
  }

  /// Replaces the whole list with a freshly-fetched first page (initial
  /// load / pull-to-refresh).
  void replaceWithPage(List<WorkOrder> page) {
    workOrders.assignAll(page);
  }

  /// Appends a subsequent page, skipping any ids already present (guards
  /// against duplicate cards if a ticket shifts pages between requests).
  void appendPage(List<WorkOrder> page) {
    final existingIds = workOrders.map((w) => w.id).toSet();
    final newOnes = page.where((w) => !existingIds.contains(w.id));
    workOrders.addAll(newOnes);
  }
}
