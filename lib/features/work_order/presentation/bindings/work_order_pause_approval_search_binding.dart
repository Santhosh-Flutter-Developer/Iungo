import 'package:get/get.dart';
import 'package:iungo/features/work_order/data/work_order_pause_approval_repository.dart';
import 'package:iungo/features/work_order/presentation/bindings/work_order_pause_approval_list_binding.dart';
import 'package:iungo/features/work_order/presentation/controllers/work_order_pause_approval_search_controller.dart';

/// Mirrors [WorkOrderClosureApprovalSearchBinding].
class WorkOrderPauseApprovalSearchBinding extends Bindings {
  @override
  void dependencies() {
    WorkOrderPauseApprovalListBinding.ensurePauseApprovalRepositoryRegistered();
    Get.put(
      WorkOrderPauseApprovalSearchController(
        Get.find<WorkOrderPauseApprovalRepository>(),
      ),
    );
  }
}
