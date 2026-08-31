import 'package:get/get.dart';
import 'package:iungo/features/inventory_request/presentation/controllers/inventory_request_search_controller.dart';

/// Registers the [InventoryRequestSearchController] backing the
/// "Awaiting Client Approval" search screen.
class InventoryRequestSearchBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(InventoryRequestSearchController());
  }
}
