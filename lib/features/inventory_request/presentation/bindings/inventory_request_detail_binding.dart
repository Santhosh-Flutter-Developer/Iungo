import 'package:get/get.dart';
import 'package:iungo/features/inventory_request/domain/entities/inventory_request.dart';
import 'package:iungo/features/inventory_request/presentation/controllers/inventory_request_detail_controller.dart';

class InventoryRequestDetailBinding extends Bindings {
  InventoryRequestDetailBinding(this.request);

  final InventoryRequest request;

  @override
  void dependencies() {
    Get.put(InventoryRequestDetailController(request));
  }
}
