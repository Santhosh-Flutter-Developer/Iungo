import 'package:get/get.dart';
import 'package:iungo/features/invoice_request/data/invoice_request_repository.dart';
import 'package:iungo/features/invoice_request/presentation/controllers/invoice_dashboard_controller.dart';
import 'package:iungo/features/purchase_request/presentation/bindings/pr_dashboard_binding.dart';

/// Registers the shared [InvoiceRequestRepository] and the
/// [InvoiceDashboardController] backing the Invoice Dashboard screen.
/// Mirrors `GrnDashboardBinding`. Reuses `PrRoleController` (via
/// [PrDashboardBinding.ensureRepositoryRegistered]) so the login-derived
/// Requestor/Approver role applies to the PR, GRN, and Invoice
/// dashboards consistently.
class InvoiceDashboardBinding extends Bindings {
  @override
  void dependencies() {
    ensureRepositoryRegistered();

    Get.lazyPut<InvoiceDashboardController>(
      () => InvoiceDashboardController(Get.find<InvoiceRequestRepository>()),
      fenix: true,
    );
  }

  /// Registers the shared [InvoiceRequestRepository]/`PrRoleController`
  /// if they aren't already — shared by any entry point that needs
  /// them (dashboard, detail, search) regardless of which one runs
  /// first.
  static void ensureRepositoryRegistered() {
    if (!Get.isRegistered<InvoiceRequestRepository>()) {
      Get.put(InvoiceRequestRepository(), permanent: true);
    }
    PrDashboardBinding.ensureRepositoryRegistered();
  }
}
