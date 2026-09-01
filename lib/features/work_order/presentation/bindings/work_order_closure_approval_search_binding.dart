import 'package:get/get.dart';
import 'package:iungo/features/work_order/data/work_order_closure_approval_repository.dart';
import 'package:iungo/features/work_order/presentation/bindings/work_order_closure_approval_list_binding.dart';
import 'package:iungo/features/work_order/presentation/controllers/work_order_closure_approval_search_controller.dart';

/// Mirrors [WorkOrderSearchBinding] ("All Work Orders" search binding).
class WorkOrderClosureApprovalSearchBinding extends Bindings {
  @override
  void dependencies() {
    WorkOrderClosureApprovalListBinding.ensureClosureApprovalRepositoryRegistered();
    Get.put(
      WorkOrderClosureApprovalSearchController(
        Get.find<WorkOrderClosureApprovalRepository>(),
      ),
    );
  }
}
