import 'dart:async';

import 'package:get/get.dart';
import 'package:iungo/features/service_request/data/service_request_repository.dart';
import 'package:iungo/features/service_request/domain/entities/search_scope.dart';
import 'package:iungo/features/service_request/domain/entities/service_request.dart';

class TicketSearchController extends GetxController {
  TicketSearchController(this._repository);

  final ServiceRequestRepository _repository;

  static const _debounceDuration = Duration(milliseconds: 400);

  final RxString query = ''.obs;
  final Rx<SearchScope> scope = SearchScope.allFields.obs;
  final RxBool isSearching = false.obs;
  final RxList<ServiceRequest> results = <ServiceRequest>[].obs;

  Timer? _debounce;

  /// True once the person has typed something and the debounced search
  /// has finished running — distinguishes the initial "Search" prompt
  /// from a genuine "No Results Found" state.
  final RxBool hasSearched = false.obs;

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
    isSearching.value = true;
    _runSearch(trimmed);
  }

  void _runSearch(String trimmed) {
    final lower = trimmed.toLowerCase();
    final tickets = _repository.tickets;

    final matches = tickets.where((t) {
      if (scope.value == SearchScope.ticketId) {
        return t.id.toString().contains(trimmed);
      }
      return t.id.toString().contains(trimmed) ||
          t.title.toLowerCase().contains(lower) ||
          t.description.toLowerCase().contains(lower) ||
          t.requester.toLowerCase().contains(lower) ||
          t.site.toLowerCase().contains(lower);
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
