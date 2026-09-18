import 'dart:async';

import 'package:get/get.dart';
import 'package:iungo/features/invoice_request/data/invoice_request_repository.dart';
import 'package:iungo/features/invoice_request/domain/entities/invoice_request.dart';
import 'package:iungo/features/invoice_request/domain/entities/invoice_search_scope.dart';

/// Search screen controller for the Invoice Dashboard. Matches Number
/// and/or Contract against the same local data set the dashboard uses,
/// narrowed by a field-scope dropdown ("All Fields" / "Number" /
/// "Contract") — mirrors `GrnSearchController` shape for shape.
class InvoiceSearchController extends GetxController {
  InvoiceSearchController(this._repository);

  final InvoiceRequestRepository _repository;

  static const _debounceDuration = Duration(milliseconds: 400);

  final RxString query = ''.obs;
  final Rx<InvoiceSearchScope> scope = InvoiceSearchScope.allFields.obs;
  final RxBool isSearching = false.obs;
  final RxBool hasSearched = false.obs;
  final RxList<InvoiceRequest> results = <InvoiceRequest>[].obs;

  Timer? _debounce;
  List<InvoiceRequest>? _cache;

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

  void onScopeChanged(InvoiceSearchScope newScope) {
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
      InvoiceSearchScope.number => (InvoiceRequest r) =>
          r.number.toLowerCase().contains(lower),
      InvoiceSearchScope.contract => (InvoiceRequest r) =>
          r.contract.toLowerCase().contains(lower),
      InvoiceSearchScope.allFields => (InvoiceRequest r) =>
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
