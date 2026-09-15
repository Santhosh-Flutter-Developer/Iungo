import 'dart:async';

import 'package:get/get.dart';
import 'package:iungo/features/purchase_request/data/purchase_request_repository.dart';
import 'package:iungo/features/purchase_request/domain/entities/purchase_request.dart';

/// Search screen controller for the PR Dashboard. Matches by PR
/// Number or Contract against the same local data set the dashboard
/// uses — mirrors `InventoryRequestSearchController`'s debounce
/// handling, simplified since there's no server round trip yet.
class PrSearchController extends GetxController {
  PrSearchController(this._repository);

  final PurchaseRequestRepository _repository;

  static const _debounceDuration = Duration(milliseconds: 400);

  final RxString query = ''.obs;
  final RxBool isSearching = false.obs;
  final RxBool hasSearched = false.obs;
  final RxList<PurchaseRequest> results = <PurchaseRequest>[].obs;

  Timer? _debounce;
  List<PurchaseRequest>? _cache;

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
    results.assignAll(
      _cache!.where(
        (r) =>
            r.prNumber.toLowerCase().contains(lower) ||
            r.contract.toLowerCase().contains(lower),
      ),
    );
    isSearching.value = false;
    hasSearched.value = true;
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
}
