import 'package:get/get.dart';
import 'package:iungo/features/work_order/data/work_order_repository.dart';
import 'package:iungo/features/work_order/presentation/bindings/work_order_list_binding.dart';
import 'package:iungo/features/work_order/presentation/controllers/work_order_search_controller.dart';

class WorkOrderSearchBinding extends Bindings {
  @override
  void dependencies() {
    WorkOrderListBinding.ensureRepositoryRegistered();
    Get.put(WorkOrderSearchController(Get.find<WorkOrderRepository>()));
  }
}