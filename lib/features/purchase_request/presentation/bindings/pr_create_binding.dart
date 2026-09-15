import 'package:get/get.dart';
import 'package:iungo/features/purchase_request/data/purchase_request_repository.dart';
import 'package:iungo/features/purchase_request/presentation/bindings/pr_dashboard_binding.dart';
import 'package:iungo/features/purchase_request/presentation/controllers/pr_create_controller.dart';

/// Registers the [PrCreateController] backing the "Add Purchase
/// Request" form (requestor view only).
class PrCreateBinding extends Bindings {
  @override
  void dependencies() {
    PrDashboardBinding.ensureRepositoryRegistered();
    Get.put(PrCreateController(Get.find<PurchaseRequestRepository>()));
  }
}
