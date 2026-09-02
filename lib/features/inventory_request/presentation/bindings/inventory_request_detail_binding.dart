import 'package:get/get.dart';
import 'package:iungo/features/inventory_request/data/inventory_request_repository.dart';
import 'package:iungo/features/inventory_request/domain/entities/inventory_request.dart';
import 'package:iungo/features/inventory_request/presentation/bindings/inventory_request_list_binding.dart';
import 'package:iungo/features/inventory_request/presentation/controllers/inventory_request_detail_controller.dart';

/// Registers the [InventoryRequestDetailController] for one Inventory
/// Request's Detail View. Mirrors [WorkOrderDetailBinding].
class InventoryRequestDetailBinding extends Bindings {
  InventoryRequestDetailBinding(this.request);

  final InventoryRequest request;

  @override
  void dependencies() {
    InventoryRequestListBinding.ensureRepositoryRegistered();
    Get.put(
      InventoryRequestDetailController(
        Get.find<InventoryRequestRepository>(),
        request,
      ),
    );
  }
}
