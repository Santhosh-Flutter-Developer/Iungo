import 'package:get/get.dart';
import 'package:iungo/core/routes/app_routes.dart';
import 'package:iungo/features/inventory_request/data/inventory_request_seed_data.dart';
import 'package:iungo/features/inventory_request/domain/entities/inventory_request.dart';
import 'package:iungo/features/inventory_request/domain/entities/inventory_request_filter.dart';
import 'package:iungo/features/inventory_request/domain/entities/inventory_reservation_status.dart';
import 'package:iungo/features/inventory_request/presentation/controllers/inventory_request_filter_controller_like.dart';

/// Drives the "Inventory Request → Awaiting Client Approval" screen —
/// same list UI, filters, and Detail View pattern as Work Order, but
/// backed by a small local seed list instead of an API call, since the
/// backing endpoint doesn't exist yet. Filtering (status / reservation
/// status / created date / find ticket) runs entirely in memory. Swap
/// this out for a real API-backed controller once the corresponding
/// endpoint exists.
class InventoryRequestListController extends GetxController
    implements InventoryRequestFilterControllerLike {
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;

  @override
  final Rx<InventoryRequestFilter> filter = const InventoryRequestFilter().obs;

  @override
  final Rxn<int> findTicketId = Rxn<int>();

  @override
  final RxList<String> statusFilterOptions = <String>[].obs;

  @override
  final RxList<InventoryReservationStatus> reservationStatusFilterOptions =
      <InventoryReservationStatus>[].obs;

  /// Canonical statuses shown in the Filter screen even if the current
  /// seed data doesn't happen to contain one of them yet.
  static const _knownStatuses = [
    'Awaiting Client Approval',
    'Fully Issued',
    'Partially Issued',
    'Rejected',
  ];

  late final List<InventoryRequest> _seed = buildInventoryRequestSeed();

  final RxList<InventoryRequest> _visible = <InventoryRequest>[].obs;

  @override
  void onInit() {
    super.onInit();
    final seedStatuses = _seed
        .map((r) => r.status)
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty);
    statusFilterOptions
        .assignAll({..._knownStatuses, ...seedStatuses}.toList());
    reservationStatusFilterOptions
        .assignAll(InventoryReservationStatusX.filterOptions);
    _visible.assignAll(_seed);
  }

  List<InventoryRequest> get filteredRequests => _visible;

  bool get hasActiveFilter => !filter.value.isEmpty || findTicketId.value != null;

  @override
  Future<void> ensureFilterOptionsLoaded() async {
    // Fixed enum list — nothing to fetch for the static options.
  }

  @override
  void applyFilter(InventoryRequestFilter newFilter) {
    filter.value = newFilter;
    _recompute();
  }

  @override
  void clearFilter() {
    findTicketId.value = null;
    filter.value = const InventoryRequestFilter();
    _recompute();
  }

  @override
  void findTicket(int serialNumber) {
    findTicketId.value = serialNumber;
    _recompute();
  }

  Future<void> retryFilter() async => _recompute();

  Future<void> reload() async {
    _visible.assignAll(_seed);
  }

  void _recompute() {
    var results = _seed.toList();

    final reservationStatus = filter.value.reservationStatus;
    if (reservationStatus != null) {
      results =
          results.where((r) => r.reservationStatus == reservationStatus).toList();
    }

    final status = filter.value.status;
    if (status != null && status.trim().isNotEmpty) {
      results = results.where((r) => r.status == status).toList();
    }

    final start = filter.value.createdDateStart;
    final end = filter.value.createdDateEnd;
    if (start != null && end != null) {
      final startOfDay = DateTime(start.year, start.month, start.day);
      final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);
      results = results
          .where((r) =>
              !r.createdTime.isBefore(startOfDay) &&
              !r.createdTime.isAfter(endOfDay))
          .toList();
    }

    final serialNumber = findTicketId.value;
    if (serialNumber != null) {
      results = results.where((r) => r.id == serialNumber).toList();
    }

    _visible.assignAll(results);
  }

  void onNotificationsTap() {
    Get.toNamed(AppRoutes.notifications);
  }
}
