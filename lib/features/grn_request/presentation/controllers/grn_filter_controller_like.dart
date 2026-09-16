import 'package:get/get.dart';
import 'package:iungo/features/grn_request/domain/entities/grn_request_filter.dart';

/// The subset of [GrnDashboardController] that [GrnFilterPage] actually
/// needs — mirrors `PrFilterControllerLike` so the same two-tab
/// ("Filter" / "Find Ticket") screen pattern can later drive a live,
/// API-backed controller too.
abstract class GrnFilterControllerLike {
  Rx<GrnRequestFilter> get filter;
  Rxn<String> get findNumber;
  List<String> get contractOptions;

  void applyFilter(GrnRequestFilter newFilter);
  void clearFilter();
  void findTicket(String number);
}
