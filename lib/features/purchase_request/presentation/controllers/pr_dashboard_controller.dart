import 'package:get/get.dart';
import 'package:iungo/core/routes/app_routes.dart';
import 'package:iungo/features/purchase_request/data/purchase_request_repository.dart';
import 'package:iungo/features/purchase_request/domain/entities/purchase_request.dart';
import 'package:iungo/features/purchase_request/domain/entities/purchase_request_filter.dart';
import 'package:iungo/features/purchase_request/domain/entities/purchase_request_status.dart';
import 'package:iungo/features/purchase_request/presentation/controllers/pr_filter_controller_like.dart';

/// Drives the PR Dashboard list screen — the three status tiles
/// (Action required/Submitted, Completed, Rejected) that double as tab
/// selectors, the Contract/Created-date filter, and the underlying
/// [PurchaseRequestRepository] fetch. Mirrors
/// `InventoryRequestListController`'s loading/refresh/filter shape,
/// simplified since the repository is currently a local, single-shot
/// data set rather than a paginated API.
class PrDashboardController extends GetxController
    implements PrFilterControllerLike {
  PrDashboardController(this._repository);

  final PurchaseRequestRepository _repository;

  final RxBool isLoading = true.obs;
  final RxBool hasError = false.obs;

  final RxList<PurchaseRequest> _allRequests = <PurchaseRequest>[].obs;

  /// 0 = Pending ("Action required" / "Submitted" depending on role),
  /// 1 = Completed (Approved), 2 = Rejected.
  final RxInt selectedTab = 0.obs;

  @override
  final Rx<PurchaseRequestFilter> filter = const PurchaseRequestFilter().obs;

  @override
  List<String> get contractOptions => PurchaseRequestRepository.contracts;

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  Future<void> reload() async {
    isLoading.value = true;
    hasError.value = false;
    try {
      final requests = await _repository.fetchAll();
      _allRequests.assignAll(requests);
    } catch (_) {
      hasError.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  void selectTab(int index) => selectedTab.value = index;

  List<PurchaseRequest> get _dateAndContractFiltered {
    var results = _allRequests.toList();

    final contract = filter.value.contract;
    if (contract != null) {
      results = results.where((r) => r.contract == contract).toList();
    }

    final start = filter.value.createdDateStart;
    final end = filter.value.createdDateEnd;
    if (start != null && end != null) {
      final startOfDay = DateTime(start.year, start.month, start.day);
      final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);
      results = results
          .where((r) =>
              !r.requestDate.isBefore(startOfDay) &&
              !r.requestDate.isAfter(endOfDay))
          .toList();
    }

    return results;
  }

  /// The list the currently-selected tab should show, after the
  /// Contract/Created-date filter is applied.
  List<PurchaseRequest> get visibleRequests {
    final status = switch (selectedTab.value) {
      1 => PurchaseRequestStatus.approved,
      2 => PurchaseRequestStatus.rejected,
      _ => PurchaseRequestStatus.pending,
    };
    return _dateAndContractFiltered.where((r) => r.status == status).toList()
      ..sort((a, b) => b.requestDate.compareTo(a.requestDate));
  }

  int get pendingCount => _dateAndContractFiltered
      .where((r) => r.status == PurchaseRequestStatus.pending)
      .length;

  int get completedCount => _dateAndContractFiltered
      .where((r) => r.status == PurchaseRequestStatus.approved)
      .length;

  int get rejectedCount => _dateAndContractFiltered
      .where((r) => r.status == PurchaseRequestStatus.rejected)
      .length;

  bool get hasActiveFilter => !filter.value.isEmpty;

  @override
  void applyFilter(PurchaseRequestFilter newFilter) {
    filter.value = newFilter;
  }

  @override
  void clearFilter() {
    filter.value = const PurchaseRequestFilter();
  }

  void onNotificationsTap() {
    Get.toNamed(AppRoutes.notifications);
  }
}
