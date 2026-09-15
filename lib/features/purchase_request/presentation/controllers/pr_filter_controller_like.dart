import 'package:get/get.dart';
import 'package:iungo/features/purchase_request/domain/entities/purchase_request_filter.dart';

/// The subset of [PrDashboardController] that [PrFilterPage] actually
/// needs — mirrors `InventoryRequestFilterControllerLike` so the same
/// two-tab ("Filter" / "Find Ticket") screen pattern can later drive a
/// live, API-backed controller too.
abstract class PrFilterControllerLike {
  Rx<PurchaseRequestFilter> get filter;
  Rxn<String> get findPrNumber;
  List<String> get contractOptions;

  void applyFilter(PurchaseRequestFilter newFilter);
  void clearFilter();
  void findTicket(String prNumber);
}