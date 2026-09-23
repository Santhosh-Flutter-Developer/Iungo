import 'package:get/get.dart';
import 'package:iungo/core/network/iungo_dio.dart';
import 'package:iungo/core/services/session_service.dart';
import 'package:iungo/features/invoice_request/data/datasources/invoice_remote_data_source.dart';
import 'package:iungo/features/invoice_request/data/invoice_request_repository.dart';
import 'package:iungo/features/invoice_request/presentation/controllers/invoice_dashboard_controller.dart';
import 'package:iungo/features/purchase_request/data/datasources/pr_create_remote_data_source.dart';
import 'package:iungo/features/purchase_request/presentation/bindings/pr_dashboard_binding.dart';
import 'package:iungo/features/purchase_request/presentation/controllers/pr_role_controller.dart';

/// Registers the shared [InvoiceRequestRepository] and the
/// [InvoiceDashboardController] backing the Invoice Dashboard screen.
/// Mirrors `GrnDashboardBinding`. Reuses [PrRoleController] (via
/// `PrDashboardBinding.ensureRepositoryRegistered`), so the login-derived
/// Requestor/Approver role applies to the PR, GRN and Invoice
/// dashboards consistently.
class InvoiceDashboardBinding extends Bindings {
  @override
  void dependencies() {
    ensureRepositoryRegistered();

    Get.lazyPut<InvoiceDashboardController>(
      () => InvoiceDashboardController(
        Get.find<InvoiceRequestRepository>(),
        Get.find<SessionService>(),
        Get.find<PrRoleController>(),
      ),
      fenix: true,
    );
  }

  /// Registers the shared [InvoiceRequestRepository]/[PrRoleController]
  /// if they aren't already — shared by any entry point that needs
  /// them (dashboard, detail, search) regardless of which one runs
  /// first. Uses [IungoDio.instance], the same host-scoped `Dio` the
  /// PR/GRN features share, and reuses [PrCreateRemoteDataSourceImpl]
  /// for the contract picklist and invoice-attachment upload.
  static void ensureRepositoryRegistered() {
    if (!Get.isRegistered<InvoiceRequestRepository>()) {
      final dio = IungoDio.instance;
      Get.put(
        InvoiceRequestRepository(
          InvoiceRemoteDataSourceImpl(dio),
          PrCreateRemoteDataSourceImpl(dio),
        ),
        permanent: true,
      );
    }
    PrDashboardBinding.ensureRepositoryRegistered();
  }
}
