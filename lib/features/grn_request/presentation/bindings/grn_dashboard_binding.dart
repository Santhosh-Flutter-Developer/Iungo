import 'package:get/get.dart';
import 'package:iungo/features/grn_request/data/grn_request_repository.dart';
import 'package:iungo/features/grn_request/presentation/controllers/grn_dashboard_controller.dart';
import 'package:iungo/features/purchase_request/presentation/bindings/pr_dashboard_binding.dart';
import 'package:iungo/features/purchase_request/presentation/controllers/pr_role_controller.dart';

/// Registers the shared [GrnRequestRepository] and the
/// [GrnDashboardController] backing the GRN Dashboard screen. Mirrors
/// `PrDashboardBinding`. Reuses [PrRoleController] for the
/// Requestor/Approver preview switch so a single toggle (see
/// `PrRoleSwitch`) governs both the PR and GRN dashboards consistently.
class GrnDashboardBinding extends Bindings {
  @override
  void dependencies() {
    ensureRepositoryRegistered();

    Get.lazyPut<GrnDashboardController>(
      () => GrnDashboardController(Get.find<GrnRequestRepository>()),
      fenix: true,
    );
  }

  /// Registers the shared [GrnRequestRepository]/[PrRoleController] if
  /// they aren't already — shared by any entry point that needs them
  /// (dashboard, detail, search) regardless of which one runs first.
  static void ensureRepositoryRegistered() {
    if (!Get.isRegistered<GrnRequestRepository>()) {
      Get.put(GrnRequestRepository(), permanent: true);
    }
    PrDashboardBinding.ensureRepositoryRegistered();
  }
}
