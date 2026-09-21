import 'package:get/get.dart';
import 'package:iungo/core/services/session_service.dart';
import 'package:iungo/features/purchase_request/data/purchase_request_repository.dart';
import 'package:iungo/features/purchase_request/presentation/controllers/pr_dashboard_controller.dart';
import 'package:iungo/features/purchase_request/presentation/controllers/pr_role_controller.dart';

/// Registers the shared [PurchaseRequestRepository], the session-driven
/// [PrRoleController], and the [PrDashboardController] backing the PR
/// Dashboard screen. Mirrors `InventoryRequestListBinding`.
class PrDashboardBinding extends Bindings {
  @override
  void dependencies() {
    ensureRepositoryRegistered();

    Get.lazyPut<PrDashboardController>(
      () => PrDashboardController(Get.find<PurchaseRequestRepository>()),
      fenix: true,
    );
  }

  /// Registers the shared [PurchaseRequestRepository]/[PrRoleController]
  /// if they aren't already — shared by any entry point that needs them
  /// (dashboard, detail, search, create) regardless of which one runs
  /// first.
  static void ensureRepositoryRegistered() {
    if (!Get.isRegistered<PurchaseRequestRepository>()) {
      Get.put(PurchaseRequestRepository(), permanent: true);
    }
    if (!Get.isRegistered<PrRoleController>()) {
      Get.put(
        PrRoleController(Get.find<SessionService>()),
        permanent: true,
      );
    }
  }
}
