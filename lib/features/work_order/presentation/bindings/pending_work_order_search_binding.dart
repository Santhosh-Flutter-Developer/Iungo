import 'package:get/get.dart';
import 'package:iungo/features/work_order/domain/entities/pending_approval_kind.dart';
import 'package:iungo/features/work_order/presentation/controllers/pending_work_order_search_controller.dart';

/// Registers a [PendingWorkOrderSearchController] tagged by [kind] so the
/// "Awaiting for Pause Approval" and "Awaiting Approval for Closure" search
/// screens each keep their own independent state.
class PendingWorkOrderSearchBinding extends Bindings {
  PendingWorkOrderSearchBinding(this.kind);

  final PendingApprovalKind kind;

  @override
  void dependencies() {
    Get.put(
      PendingWorkOrderSearchController(kind),
      tag: kind.tag,
    );
  }
}
