import 'dart:async';

import 'package:get/get.dart';
import 'package:iungo/features/service_request/domain/entities/search_scope.dart';
import 'package:iungo/features/work_order/data/pending_work_order_seed_data.dart';
import 'package:iungo/features/work_order/domain/entities/pending_approval_kind.dart';
import 'package:iungo/features/work_order/domain/entities/work_order.dart';

/// Drives the search screen for the "Awaiting for Pause Approval" /
/// "Awaiting Approval for Closure" lists. Mirrors [WorkOrderSearchController]
/// exactly (same debounce, same scope dropdown, same idle/spinner/no-results
/// states) but matches purely in memory against the local seed list instead
/// of calling the API, since there's no backing endpoint for these two views
/// yet.
class PendingWorkOrderSearchController extends GetxController {
  PendingWorkOrderSearchController(this.kind);

  final PendingApprovalKind kind;

  /// Kept short since there's no network round trip to actually wait on
  /// here — just long enough that results don't flicker on every keystroke.
  static const _debounceDuration = Duration(milliseconds: 400);

  final RxString query = ''.obs;
  final Rx<SearchScope> scope = SearchScope.allFields.obs;
  final RxBool isSearching = false.obs;
  final RxList<WorkOrder> results = <WorkOrder>[].obs;

  /// True once the person has typed something and the debounced search has
  /// finished running — distinguishes the initial "Search" prompt from a
  /// genuine "No Results Found" state.
  final RxBool hasSearched = false.obs;

  late final List<WorkOrder> _seed = buildPendingWorkOrderSeed(kind);

  Timer? _debounce;

  void onQueryChanged(String value) {
    query.value = value;
    _debounce?.cancel();

    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      isSearching.value = false;
      hasSearched.value = false;
      results.clear();
      return;
    }

    isSearching.value = true;
    _debounce = Timer(_debounceDuration, () => _runSearch(trimmed));
  }

  void onScopeChanged(SearchScope newScope) {
    scope.value = newScope;
    final trimmed = query.value.trim();
    if (trimmed.isEmpty) return;
    _debounce?.cancel();
    _runSearch(trimmed);
  }

  /// Fired when the person presses the keyboard's search/done action —
  /// searches immediately rather than waiting out [_debounceDuration].
  void onQuerySubmitted(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    _debounce?.cancel();
    _runSearch(trimmed);
  }

  void _runSearch(String trimmed) {
    final lowerQuery = trimmed.toLowerCase();

    final matches = _seed.where((workOrder) {
      final serial = workOrder.serialNumber.toString();
      switch (scope.value) {
        case SearchScope.ticketId:
          return serial == trimmed;
        case SearchScope.subject:
          return workOrder.title.toLowerCase().contains(lowerQuery);
        case SearchScope.description:
          return workOrder.description.toLowerCase().contains(lowerQuery);
        case SearchScope.allFields:
          return serial == trimmed ||
              workOrder.title.toLowerCase().contains(lowerQuery) ||
              workOrder.description.toLowerCase().contains(lowerQuery);
      }
    }).toList();

    results.assignAll(matches);
    isSearching.value = false;
    hasSearched.value = true;
  }

  void clear() {
    _debounce?.cancel();
    query.value = '';
    isSearching.value = false;
    hasSearched.value = false;
    results.clear();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
}
