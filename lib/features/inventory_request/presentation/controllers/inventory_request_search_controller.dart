import 'dart:async';

import 'package:get/get.dart';
import 'package:iungo/features/inventory_request/data/inventory_request_repository.dart';
import 'package:iungo/features/inventory_request/domain/entities/inventory_request.dart';
import 'package:iungo/features/service_request/domain/entities/search_scope.dart';

/// "Inventory Request → Awaiting Client Approval" search screen
/// controller. Mirrors [WorkOrderClosureApprovalSearchController]
/// exactly — same debounce, scope handling, and client-side narrowing —
/// backed by [InventoryRequestRepository] and its server-side
/// search/quickFilter API instead of a local seed list.
class InventoryRequestSearchController extends GetxController {
  InventoryRequestSearchController(this._repository);

  final InventoryRequestRepository _repository;

  /// How long to wait after the last keystroke before searching. Long
  /// enough that ordinary typing (including brief pauses between words)
  /// doesn't trigger a search until the person has actually stopped —
  /// short debounces read as "searching while typing".
  static const _debounceDuration = Duration(milliseconds: 800);

  /// Matches the rest of the app's own quickFilter/search requests,
  /// which ask for 50 results in one shot rather than paging.
  static const _searchPerPage = 50;

  final RxString query = ''.obs;
  final Rx<SearchScope> scope = SearchScope.allFields.obs;
  final RxBool isSearching = false.obs;
  final RxList<InventoryRequest> results = <InventoryRequest>[].obs;

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

  /// Fired when the person presses the keyboard's search/done action —
  /// searches immediately rather than waiting out [_debounceDuration],
  /// for anyone who finishes typing faster than the debounce window.
  void onQuerySubmitted(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    _debounce?.cancel();
    isSearching.value = true;
    _runSearch(trimmed);
  }

  /// Hits the server's "Awaiting Client Approval" list API with either a
  /// `quickFilter` (exact match — correct for "Ticket Id", an exact
  /// numeric `id` lookup) or the broad `search` query param (partial,
  /// case-insensitive — used for Subject/Description/"All Fields"); for
  /// Subject/Description the results are then narrowed client-side to
  /// only those whose specific field actually contains the query,
  /// matching the rest of the app's search screens exactly.
  Future<void> _runSearch(String trimmed) async {
    final token = ++_requestToken;

    Map<String, List<String>>? quickFilter;
    String? search;
    switch (scope.value) {
      case SearchScope.ticketId:
        quickFilter = {
          'id': [trimmed],
        };
        break;
      case SearchScope.subject:
      case SearchScope.description:
      case SearchScope.allFields:
        search = trimmed;
        break;
    }

    try {
      final result = await _repository.fetchFiltered(
        page: 1,
        perPage: _searchPerPage,
        quickFilter: quickFilter,
        search: search,
      );
      if (token != _requestToken) return; // a newer search superseded this one

      final lowerQuery = trimmed.toLowerCase();
      final requests = switch (scope.value) {
        SearchScope.subject => result.requests
            .where((r) => r.name.toLowerCase().contains(lowerQuery))
            .toList(),
        SearchScope.description => result.requests
            .where((r) => r.description.toLowerCase().contains(lowerQuery))
            .toList(),
        SearchScope.ticketId || SearchScope.allFields => result.requests,
      };

      results.assignAll(await _repository.resolveStatusLabels(requests));
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
