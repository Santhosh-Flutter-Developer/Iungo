import 'package:get/get.dart';
import 'package:iungo/features/purchase_request/domain/entities/contract_option.dart';
import 'package:iungo/features/purchase_request/domain/entities/purchase_request_filter.dart';

/// The subset of [PrDashboardController] that [PrFilterPage] actually
/// needs — mirrors `InventoryRequestFilterControllerLike` so the same
/// two-tab ("Filter" / "Find Ticket") screen pattern drives the live,
/// API-backed controller.
abstract class PrFilterControllerLike {
  Rx<PurchaseRequestFilter> get filter;
  Rxn<String> get findPrNumber;

  /// Contracts for the "Select Contract" dropdown, loaded from the
  /// `fetch_contract_code` API.
  RxList<ContractOption> get contractOptions;
  RxBool get isLoadingContracts;

  /// A user-facing message when the contract list failed to load.
  Rxn<String> get contractsError;

  /// Loads [contractOptions] if they haven't been loaded yet (safe to
  /// call every time the Filter screen opens).
  Future<void> ensureContractsLoaded();

  /// Forces a fresh load of [contractOptions] (the Retry action).
  Future<void> reloadContracts();

  void applyFilter(PurchaseRequestFilter newFilter);
  void clearFilter();
  void findTicket(String prNumber);
}
