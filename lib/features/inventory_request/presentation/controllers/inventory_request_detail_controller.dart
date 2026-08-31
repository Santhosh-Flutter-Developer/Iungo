import 'package:get/get.dart';
import 'package:iungo/features/inventory_request/domain/entities/inventory_request.dart';
import 'package:iungo/features/work_order/domain/entities/work_order_attachment.dart';
import 'package:iungo/features/work_order/domain/entities/work_order_comment.dart';

/// Holds the tab state for one Inventory Request Detail View screen —
/// mirrors [WorkOrderDetailController]'s shape (loading/error state per
/// tab), but there is no backing API for this feature yet, so the
/// Overview tab simply shows [request] as-is and Comments/Attachments
/// render their existing empty states. Reuses the Work Order Comment/
/// Attachment entities and widgets, since both features share the same
/// Detail View shape.
class InventoryRequestDetailController extends GetxController {
  InventoryRequestDetailController(InventoryRequest initial)
      : request = initial.obs;

  /// Convenience accessor — most callers only ever want the current
  /// request, not the fact that it's reactive.
  InventoryRequest get order => request.value;

  final Rx<InventoryRequest> request;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  final RxList<WorkOrderComment> comments = <WorkOrderComment>[].obs;
  final RxBool isLoadingComments = false.obs;
  final RxString commentsError = ''.obs;

  final RxList<WorkOrderAttachment> attachments = <WorkOrderAttachment>[].obs;
  final RxBool isLoadingAttachments = false.obs;
  final RxString attachmentsError = ''.obs;

  Future<void> retry() async {}

  Future<void> retryComments() async {}

  Future<void> retryAttachments() async {}
}
