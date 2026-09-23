import 'package:get/get.dart';
import 'package:iungo/core/services/session_service.dart';
import 'package:iungo/features/invoice_request/data/invoice_request_repository.dart';
import 'package:iungo/features/invoice_request/presentation/bindings/invoice_dashboard_binding.dart';
import 'package:iungo/features/invoice_request/presentation/controllers/invoice_dashboard_controller.dart';
import 'package:iungo/features/invoice_request/presentation/controllers/invoice_search_controller.dart';

/// Registers the [InvoiceSearchController] backing the Invoice Dashboard
/// search screen. Mirrors `GrnSearchBinding`.
class InvoiceSearchBinding extends Bindings {
  @override
  void dependencies() {
    InvoiceDashboardBinding.ensureRepositoryRegistered();
    Get.put(
      InvoiceSearchController(
        Get.find<InvoiceRequestRepository>(),
        Get.find<SessionService>(),
        Get.find<InvoiceDashboardController>(),
      ),
    );
  }
}
