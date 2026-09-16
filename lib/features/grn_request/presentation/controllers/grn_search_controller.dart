import 'dart:async';

import 'package:get/get.dart';
import 'package:iungo/features/grn_request/data/grn_request_repository.dart';
import 'package:iungo/features/grn_request/domain/entities/grn_request.dart';
import 'package:iungo/features/grn_request/domain/entities/grn_search_scope.dart';

/// Search screen controller for the GRN Dashboard. Matches Number
/// and/or Contract against the same local data set the dashboard uses,
/// narrowed by a field-scope dropdown ("All Fields" / "Number" /
/// "Contract") — mirrors `PrSearchController` shape for shape.
class GrnSearchController extends GetxController {
  GrnSearchController(this._repository);

  final GrnRequestRepository _repository;

  static const _debounceDuration = Duration(milliseconds: 400);

  final RxString query = ''.obs;
  final Rx<GrnSearchScope> scope = GrnSearchScope.allFields.obs;
  final RxBool isSearching = false.obs;
  final RxBool hasSearched = false.obs;
  final RxList<GrnRequest> results = <GrnRequest>[].obs;

  Timer? _debounce;
  List<GrnRequest>? _cache;

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

  void onScopeChanged(GrnSearchScope newScope) {
    scope.value = newScope;
    final trimmed = query.value.trim();
    if (trimmed.isEmpty) return;
    _debounce?.cancel();
    isSearching.value = true;
    _runSearch(trimmed);
  }

  void onQuerySubmitted(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    _debounce?.cancel();
    isSearching.value = true;
    _runSearch(trimmed);
  }

  Future<void> _runSearch(String trimmed) async {
    _cache ??= await _repository.fetchAll();
    final lower = trimmed.toLowerCase();
    final matches = switch (scope.value) {
      GrnSearchScope.number => (GrnRequest r) =>
          r.number.toLowerCase().contains(lower),
      GrnSearchScope.contract => (GrnRequest r) =>
          r.contract.toLowerCase().contains(lower),
      GrnSearchScope.allFields => (GrnRequest r) =>
          r.number.toLowerCase().contains(lower) ||
          r.contract.toLowerCase().contains(lower),
    };
    results.assignAll(_cache!.where(matches));
    isSearching.value = false;
    hasSearched.value = true;
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
}
