import 'package:get/get.dart';
import 'package:iungo/features/inventory_request/data/datasources/inventory_request_exceptions.dart';
import 'package:iungo/features/inventory_request/data/inventory_request_repository.dart';
import 'package:iungo/features/inventory_request/domain/entities/inventory_request.dart';
import 'package:iungo/features/work_order/domain/entities/work_order_attachment.dart';
import 'package:iungo/features/work_order/domain/entities/work_order_comment.dart';

/// Holds the tab state for one Inventory Request Detail View screen.
///
/// [request] starts out as whatever summary card was tapped (from the
/// list/search screen), then a fresh fetch by id replaces it with the
/// richer Detail View record (Line Items, full description, etc. —
/// fields the list API doesn't return inline). Notes and Attachments are
/// each backed by their own API call with their own loading/error
/// state, fetched in parallel with the overview detail on [onInit] so a
/// slow overview fetch doesn't block the other two tabs. Mirrors
/// [WorkOrderDetailController] exactly (minus the due-date countdown/
/// Tasks tab, which Inventory Request has no equivalent of); reuses the
/// Work Order Comment/Attachment entities and tab widgets, since both
/// features share the same Detail View shape.
class InventoryRequestDetailController extends GetxController {
  InventoryRequestDetailController(this._repository, InventoryRequest initial)
      : request = initial.obs;

  final InventoryRequestRepository _repository;

  /// Convenience accessor — most callers only ever want the current
  /// request, not the fact that it's reactive.
  InventoryRequest get order => request.value;

  final Rx<InventoryRequest> request;
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;

  // ---- Notes -------------------------------------------------------

  final RxList<WorkOrderComment> comments = <WorkOrderComment>[].obs;
  final RxBool isLoadingComments = true.obs;
  final RxString commentsError = ''.obs;

  // ---- Attachments -------------------------------------------------

  final RxList<WorkOrderAttachment> attachments = <WorkOrderAttachment>[].obs;
  final RxBool isLoadingAttachments = true.obs;
  final RxString attachmentsError = ''.obs;

  // ---- Approve / Reject ---------------------------------------------

  /// True while an approve/reject submission is in flight — lets the
  /// Detail View disable the action buttons and show a spinner so a
  /// double-tap can't fire the request twice once the API is wired up.
  final RxBool isSubmittingApproval = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadDetail();
    _loadNotes();
    _loadAttachments();
  }

  Future<void> _loadDetail() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final fresh =
          await _repository.fetchInventoryRequestDetail(request.value.id);
      request.value = await _repository.resolveStatusLabelFor(fresh);
    } on InventoryRequestException catch (e) {
      errorMessage.value =
          e.message.trim().isNotEmpty ? e.message : 'something_went_wrong'.tr;
    } catch (_) {
      errorMessage.value = 'something_went_wrong'.tr;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> retry() => _loadDetail();

  // ---- Notes -------------------------------------------------------

  Future<void> _loadNotes() async {
    isLoadingComments.value = true;
    commentsError.value = '';
    try {
      final fetched = await _repository.fetchNotes(request.value.id);
      comments.assignAll(fetched);
    } on InventoryRequestException catch (e) {
      commentsError.value =
          e.message.trim().isNotEmpty ? e.message : 'something_went_wrong'.tr;
    } catch (_) {
      commentsError.value = 'something_went_wrong'.tr;
    } finally {
      isLoadingComments.value = false;
    }
  }

  Future<void> retryComments() => _loadNotes();

  // ---- Attachments -------------------------------------------------------

  Future<void> _loadAttachments() async {
    isLoadingAttachments.value = true;
    attachmentsError.value = '';
    try {
      final fetched = await _repository.fetchAttachments(request.value.id);
      attachments.assignAll(fetched);
    } on InventoryRequestException catch (e) {
      attachmentsError.value =
          e.message.trim().isNotEmpty ? e.message : 'something_went_wrong'.tr;
    } catch (_) {
      attachmentsError.value = 'something_went_wrong'.tr;
    } finally {
      isLoadingAttachments.value = false;
    }
  }

  Future<void> retryAttachments() => _loadAttachments();

  // ---- Approve / Reject -----------------------------------------------

  /// Approves the request.
  ///
  /// UI-only for now — [InventoryRequestApprovalActionBar] already
  /// guards this behind a confirmation dialog and disables itself while
  /// [isSubmittingApproval] is true, so wiring in the real endpoint here
  /// later (once the API details are shared) is just filling in the
  /// TODO below; no caller-side changes should be needed.
  Future<void> approveRequest() async {
    isSubmittingApproval.value = true;
    try {
      // TODO: call the Approve Inventory Request API for request.value.id
      // once the endpoint is available, then refresh the detail
      // (e.g. await _loadDetail()) so the Status/action bar update.
    } finally {
      isSubmittingApproval.value = false;
    }
  }

  /// Rejects the request with a mandatory [remarks] explanation.
  ///
  /// UI-only for now, same as [approveRequest] — the reject dialog
  /// already enforces non-empty remarks before this is called.
  Future<void> rejectRequest(String remarks) async {
    isSubmittingApproval.value = true;
    try {
      // TODO: call the Reject Inventory Request API for request.value.id
      // with `remarks` once the endpoint is available, then refresh the
      // detail (e.g. await _loadDetail()) so the Status/action bar
      // update.
    } finally {
      isSubmittingApproval.value = false;
    }
  }
}