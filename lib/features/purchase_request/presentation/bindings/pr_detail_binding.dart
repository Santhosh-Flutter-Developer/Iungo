import 'package:get/get.dart';
import 'package:iungo/features/purchase_request/data/purchase_request_repository.dart';
import 'package:iungo/features/purchase_request/domain/entities/purchase_request.dart';
import 'package:iungo/features/purchase_request/presentation/bindings/pr_dashboard_binding.dart';
import 'package:iungo/features/purchase_request/presentation/controllers/pr_detail_controller.dart';

/// Registers the [PrDetailController] for one Purchase Request's Detail
/// View. Mirrors `InventoryRequestDetailBinding`.
class PrDetailBinding extends Bindings {
  PrDetailBinding(this.request);

  final PurchaseRequest request;

  @override
  void dependencies() {
    PrDashboardBinding.ensureRepositoryRegistered();
    Get.put(
      PrDetailController(Get.find<PurchaseRequestRepository>(), request),
    );
  }
}
