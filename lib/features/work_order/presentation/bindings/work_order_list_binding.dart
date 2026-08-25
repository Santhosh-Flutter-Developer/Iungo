import 'package:get/get.dart';
import 'package:iungo/features/work_order/data/work_order_repository.dart';
import 'package:iungo/features/work_order/presentation/controllers/work_order_list_controller.dart';

class WorkOrderListBinding extends Bindings {
  @override
  void dependencies() {
    ensureRepositoryRegistered();

    Get.lazyPut<WorkOrderListController>(
      () => WorkOrderListController(Get.find<WorkOrderRepository>()),
      fenix: true,
    );
  }

  /// Registers the shared [WorkOrderRepository] if it isn't already —
  /// shared by any entry point that needs it (list page, search).
  static void ensureRepositoryRegistered() {
    if (!Get.isRegistered<WorkOrderRepository>()) {
      Get.put(WorkOrderRepository(), permanent: true);
    }
  }
}