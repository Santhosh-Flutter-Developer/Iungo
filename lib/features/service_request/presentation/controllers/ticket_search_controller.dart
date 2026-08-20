import 'dart:async';

import 'package:get/get.dart';
import 'package:iungo/features/service_request/data/service_request_repository.dart';
import 'package:iungo/features/service_request/domain/entities/search_scope.dart';
import 'package:iungo/features/service_request/domain/entities/service_request.dart';

class TicketSearchController extends GetxController {
  TicketSearchController(this._repository);

  final ServiceRequestRepository _repository;

  static const _debounceDuration = Duration(milliseconds: 400);

  /// Matches the real app's own quickFilter/search requests (confirmed
  /// via Postman capture), which ask for 50 results in one shot rather
  /// than paging by 10.
  static const _searchPerPage = 50;

  final RxString query = ''.obs;
  final Rx<SearchScope> scope = SearchScope.allFields.obs;
  final RxBool isSearching = false.obs;
  final RxList<ServiceRequest> results = <ServiceRequest>[].obs;

  Timer? _debounce;

  /// Guards against out-of-order responses: only the reply to the most
  /// recently issued search is applied to [results].
  int _requestToken = 0;

  /// True once the person has typed something and the debounced search
  /// has finished running — distinguishes the initial "Search" prompt
  /// from a genuine "No Results Found" state.
  final RxBool hasSearched = false.obs;

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

  /// Hits the server's list API with a scope-appropriate query:
  /// ticket id/subject/description go through `quickFilter` (an exact
  /// field lookup, e.g. `{"subject":{"value":["Service Request Test 1"]}}`
  /// — matching the real app's own requests captured via Postman), while
  /// "All Fields" uses the plain `search` query param for a broader,
  /// non-field-specific match.
  Future<void> _runSearch(String trimmed) async {
    final token = ++_requestToken;

    Map<String, List<String>>? quickFilter;
    String? search;
    switch (scope.value) {
      case SearchScope.ticketId:
        quickFilter = {'id': [trimmed]};
        break;
      case SearchScope.subject:
        quickFilter = {'subject': [trimmed]};
        break;
      case SearchScope.description:
        quickFilter = {'description': [trimmed]};
        break;
      case SearchScope.allFields:
        search = trimmed;
        break;
    }

    try {
      final result = await _repository.fetchPage(
        page: 1,
        perPage: _searchPerPage,
        quickFilter: quickFilter,
        search: search,
      );
      if (token != _requestToken) return; // a newer search superseded this one
      results.assignAll(result.tickets);
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