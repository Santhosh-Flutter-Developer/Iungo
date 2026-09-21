import 'package:get/get.dart';
import 'package:iungo/core/services/session_service.dart';
import 'package:iungo/features/purchase_request/data/purchase_request_repository.dart';
import 'package:iungo/features/purchase_request/presentation/bindings/pr_dashboard_binding.dart';
import 'package:iungo/features/purchase_request/presentation/controllers/pr_dashboard_controller.dart';
import 'package:iungo/features/purchase_request/presentation/controllers/pr_search_controller.dart';

/// Registers the [PrSearchController] backing the PR Dashboard search
/// screen. Mirrors `InventoryRequestSearchBinding`.
class PrSearchBinding extends Bindings {
  @override
  void dependencies() {
    PrDashboardBinding.ensureRepositoryRegistered();
    Get.put(
      PrSearchController(
        Get.find<PurchaseRequestRepository>(),
        Get.find<SessionService>(),
        Get.find<PrDashboardController>(),
      ),
    );
  }
}
