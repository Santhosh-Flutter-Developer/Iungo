import 'package:get/get.dart';
import 'package:iungo/features/inventory_request/data/inventory_request_repository.dart';
import 'package:iungo/features/inventory_request/presentation/bindings/inventory_request_list_binding.dart';
import 'package:iungo/features/inventory_request/presentation/controllers/inventory_request_search_controller.dart';

/// Registers the [InventoryRequestSearchController] backing the
/// "Awaiting Client Approval" search screen. Mirrors
/// [WorkOrderClosureApprovalSearchBinding].
class InventoryRequestSearchBinding extends Bindings {
  @override
  void dependencies() {
    InventoryRequestListBinding.ensureRepositoryRegistered();
    Get.put(
      InventoryRequestSearchController(
        Get.find<InventoryRequestRepository>(),
      ),
    );
  }
}
