import 'package:get/get.dart';
import 'package:iungo/features/work_order/domain/entities/pending_approval_kind.dart';
import 'package:iungo/features/work_order/presentation/controllers/pending_work_order_list_controller.dart';

/// Registers a [PendingWorkOrderListController] tagged by [kind] so the
/// "Awaiting for Pause Approval" and "Awaiting Approval for Closure"
/// screens each keep their own independent state.
class PendingWorkOrderListBinding extends Bindings {
  PendingWorkOrderListBinding(this.kind);

  final PendingApprovalKind kind;

  @override
  void dependencies() {
    Get.put(
      PendingWorkOrderListController(kind),
      tag: kind.tag,
    );
  }
}
