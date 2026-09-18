import 'package:get/get.dart';
import 'package:iungo/features/invoice_request/data/invoice_request_repository.dart';
import 'package:iungo/features/invoice_request/domain/entities/invoice_request.dart';
import 'package:iungo/features/invoice_request/presentation/bindings/invoice_dashboard_binding.dart';
import 'package:iungo/features/invoice_request/presentation/controllers/invoice_detail_controller.dart';

/// Registers the [InvoiceDetailController] for one Invoice Request's
/// Detail View. Mirrors `GrnDetailBinding`.
class InvoiceDetailBinding extends Bindings {
  InvoiceDetailBinding(this.request);

  final InvoiceRequest request;

  @override
  void dependencies() {
    InvoiceDashboardBinding.ensureRepositoryRegistered();
    Get.put(
      InvoiceDetailController(Get.find<InvoiceRequestRepository>(), request),
    );
  }
}
