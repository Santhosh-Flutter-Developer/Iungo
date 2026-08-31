import 'package:get/get.dart';
import 'package:iungo/features/inventory_request/presentation/controllers/inventory_request_list_controller.dart';

/// Registers the [InventoryRequestListController] backing the "Awaiting
/// Client Approval" screen.
class InventoryRequestListBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(InventoryRequestListController());
  }
}
