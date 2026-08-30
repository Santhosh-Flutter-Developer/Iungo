import 'package:get/get.dart';
import 'package:iungo/features/work_order/data/work_order_repository.dart';
import 'package:iungo/features/work_order/domain/entities/work_order.dart';
import 'package:iungo/features/work_order/presentation/bindings/work_order_list_binding.dart';
import 'package:iungo/features/work_order/presentation/controllers/work_order_detail_controller.dart';

class WorkOrderDetailBinding extends Bindings {
  WorkOrderDetailBinding(this.workOrder, {this.staticMode = false});

  final WorkOrder workOrder;

  /// Forwarded to [WorkOrderDetailController] — true for the static
  /// "Awaiting for Pause/Closure Approval" placeholder lists, which have
  /// no backing API yet.
  final bool staticMode;

  @override
  void dependencies() {
    WorkOrderListBinding.ensureRepositoryRegistered();
    Get.put(
      WorkOrderDetailController(
        Get.find<WorkOrderRepository>(),
        workOrder,
        staticMode: staticMode,
      ),
    );
  }
}
