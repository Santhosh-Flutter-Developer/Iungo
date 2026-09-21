import 'package:get/get.dart';
import 'package:iungo/core/network/iungo_dio.dart';
import 'package:iungo/core/services/session_service.dart';
import 'package:iungo/features/purchase_request/data/datasources/pr_create_remote_data_source.dart';
import 'package:iungo/features/purchase_request/data/datasources/pr_remote_data_source.dart';
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
      () => PrDashboardController(
        Get.find<PurchaseRequestRepository>(),
        Get.find<SessionService>(),
        Get.find<PrRoleController>(),
      ),
      fenix: true,
    );
  }

  /// Registers the shared [PurchaseRequestRepository]/[PrRoleController]
  /// if they aren't already — shared by any entry point that needs them
  /// (dashboard, detail, search, create) regardless of which one runs
  /// first.
  ///
  /// The repository uses [IungoDio.instance] rather than GetX's ambient
  /// `Dio` type: these endpoints authenticate through `user_id` in the
  /// body (no Bearer interceptor wanted), and, crucially, need the
  /// Iungo host's certificate override — which the app's ambient `Dio`
  /// (registered for a different host) doesn't carry.
  static void ensureRepositoryRegistered() {
    if (!Get.isRegistered<PurchaseRequestRepository>()) {
      final dio = IungoDio.instance;
      Get.put(
        PurchaseRequestRepository(
          PrRemoteDataSourceImpl(dio),
          PrCreateRemoteDataSourceImpl(dio),
        ),
        permanent: true,
      );
    }
    if (!Get.isRegistered<PrRoleController>()) {
      Get.put(
        PrRoleController(Get.find<SessionService>()),
        permanent: true,
      );
    }
  }
}
