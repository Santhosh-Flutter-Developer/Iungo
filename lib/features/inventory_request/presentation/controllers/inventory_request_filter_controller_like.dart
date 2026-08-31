import 'package:get/get.dart';
import 'package:iungo/features/inventory_request/domain/entities/inventory_request_filter.dart';
import 'package:iungo/features/inventory_request/domain/entities/inventory_reservation_status.dart';

/// The subset of [InventoryRequestListController] that
/// [InventoryRequestFilterPage] actually needs — mirrors
/// [WorkOrderFilterControllerLike] so the same Filter screen pattern can
/// later drive a live, API-backed controller too.
abstract class InventoryRequestFilterControllerLike {
  Rx<InventoryRequestFilter> get filter;
  Rxn<int> get findTicketId;
  RxList<InventoryReservationStatus> get reservationStatusFilterOptions;

  Future<void> ensureFilterOptionsLoaded();
  void applyFilter(InventoryRequestFilter newFilter);
  void clearFilter();
  void findTicket(int serialNumber);
}
