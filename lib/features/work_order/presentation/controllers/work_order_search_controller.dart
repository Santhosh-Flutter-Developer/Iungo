import 'dart:async';

import 'package:get/get.dart';
import 'package:iungo/features/service_request/domain/entities/search_scope.dart';
import 'package:iungo/features/work_order/data/work_order_repository.dart';
import 'package:iungo/features/work_order/domain/entities/work_order.dart';

class WorkOrderSearchController extends GetxController {
  WorkOrderSearchController(this._repository);

  final WorkOrderRepository _repository;

  static const _debounceDuration = Duration(milliseconds: 400);

  final RxString query = ''.obs;
  final Rx<SearchScope> scope = SearchScope.allFields.obs;
  final RxBool isSearching = false.obs;
  final RxList<WorkOrder> results = <WorkOrder>[].obs;
  final RxBool hasSearched = false.obs;

  Timer? _debounce;
  int _requestToken = 0;

  void onQueryChanged(String value) {
    query.value = value;
    _debounce?.cancel();

    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      _requestToken++;
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
    isSearching.value = true;
    _runSearch(trimmed);
  }

  Future<void> _runSearch(String trimmed) async {
    final token = ++_requestToken;
    try {
      final result = await _repository.search(
        query: trimmed,
        byId: scope.value == SearchScope.ticketId,
        bySubject: scope.value == SearchScope.subject,
        byDescription: scope.value == SearchScope.description,
      );
      if (token != _requestToken) return;
      results.assignAll(result);
    } catch (_) {
      if (token != _requestToken) return;
      results.clear();
    } finally {
      if (token == _requestToken) {
        isSearching.value = false;
        hasSearched.value = true;
      }
    }
  }

  void clear() {
    _debounce?.cancel();
    _requestToken++;
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