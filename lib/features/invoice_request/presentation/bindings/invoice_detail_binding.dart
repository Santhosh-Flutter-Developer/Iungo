import 'package:get/get.dart';
import 'package:iungo/core/services/session_service.dart';
import 'package:iungo/features/invoice_request/data/invoice_request_repository.dart';
import 'package:iungo/features/invoice_request/domain/entities/invoice_request.dart';
import 'package:iungo/features/invoice_request/presentation/bindings/invoice_dashboard_binding.dart';
import 'package:iungo/features/invoice_request/presentation/controllers/invoice_detail_controller.dart';

/// Registers the [InvoiceDetailController] for one Invoice Request's
/// Detail View. Mirrors `GrnDetailBinding`.
///
/// [canDecide] says whether the request was opened from the approver's
/// Action Required list — the only place Approve/Reject may show.
class InvoiceDetailBinding extends Bindings {
  InvoiceDetailBinding(this.request, {this.canDecide = false});

  final InvoiceRequest request;
  final bool canDecide;

  @override
  void dependencies() {
    InvoiceDashboardBinding.ensureRepositoryRegistered();
    Get.put(
      InvoiceDetailController(
        Get.find<InvoiceRequestRepository>(),
        Get.find<SessionService>(),
        request,
        canDecide: canDecide,
      ),
    );
  }
}
