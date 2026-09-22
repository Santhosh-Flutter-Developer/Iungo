import 'package:get/get.dart';
import 'package:iungo/core/network/iungo_dio.dart';
import 'package:iungo/core/services/session_service.dart';
import 'package:iungo/features/grn_request/data/datasources/grn_remote_data_source.dart';
import 'package:iungo/features/grn_request/data/grn_request_repository.dart';
import 'package:iungo/features/grn_request/presentation/controllers/grn_dashboard_controller.dart';
import 'package:iungo/features/purchase_request/data/datasources/pr_create_remote_data_source.dart';
import 'package:iungo/features/purchase_request/presentation/bindings/pr_dashboard_binding.dart';
import 'package:iungo/features/purchase_request/presentation/controllers/pr_role_controller.dart';

/// Registers the shared [GrnRequestRepository] and the
/// [GrnDashboardController] backing the GRN Dashboard screen. Mirrors
/// `PrDashboardBinding`. Reuses [PrRoleController] (via
/// `PrDashboardBinding.ensureRepositoryRegistered`), so the login-derived
/// Requestor/Approver role applies to the PR, GRN and Invoice
/// dashboards consistently.
class GrnDashboardBinding extends Bindings {
  @override
  void dependencies() {
    ensureRepositoryRegistered();

    Get.lazyPut<GrnDashboardController>(
      () => GrnDashboardController(
        Get.find<GrnRequestRepository>(),
        Get.find<SessionService>(),
        Get.find<PrRoleController>(),
      ),
      fenix: true,
    );
  }

  /// Registers the shared [GrnRequestRepository]/[PrRoleController] if
  /// they aren't already — shared by any entry point that needs them
  /// (dashboard, detail, search) regardless of which one runs first.
  /// Uses [IungoDio.instance], the same host-scoped `Dio` the PR feature
  /// shares, and reuses [PrCreateRemoteDataSourceImpl] for the contract
  /// picklist and delivery-note upload.
  static void ensureRepositoryRegistered() {
    if (!Get.isRegistered<GrnRequestRepository>()) {
      final dio = IungoDio.instance;
      Get.put(
        GrnRequestRepository(
          GrnRemoteDataSourceImpl(dio),
          PrCreateRemoteDataSourceImpl(dio),
        ),
        permanent: true,
      );
    }
    PrDashboardBinding.ensureRepositoryRegistered();
  }
}
