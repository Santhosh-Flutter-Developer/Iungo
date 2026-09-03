import 'package:get/get.dart';
import 'package:iungo/core/widgets/app_snackbar.dart';
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

  /// `stateTransitionId` the Portal API expects for the "Approve"
  /// action on an Inventory Request sitting in "Awaiting Client
  /// Approval", confirmed via Postman against the live Portal API.
  static const int _approveTransitionId = 14145;

  /// `stateTransitionId` the Portal API expects for the "Reject"
  /// action — same status, confirmed via Postman.
  static const int _rejectTransitionId = 41229;

  /// Approves the request's current "Awaiting Client Approval" state
  /// via the Portal API's transition endpoint (see
  /// [InventoryRequestRepository.submitTransition]). No remarks field
  /// is offered for Approve, so a default "Approved" comment is sent —
  /// the portal API rejects an empty comment. Mirrors
  /// [WorkOrderDetailController.approveRequest] exactly.
  Future<void> approveRequest() async {
    isSubmittingApproval.value = true;
    try {
      await _repository.submitTransition(
        inventoryRequestId: order.id,
        stateTransitionId: _approveTransitionId,
        comment: 'approved_default_comment'.tr,
      );
      AppSnackbar.showSuccess('approve_success'.tr);
      await _loadDetail();
    } on InventoryRequestException catch (e) {
      AppSnackbar.showError(
        e.message.trim().isNotEmpty ? e.message : 'something_went_wrong'.tr,
      );
    } catch (_) {
      AppSnackbar.showError('something_went_wrong'.tr);
    } finally {
      isSubmittingApproval.value = false;
    }
  }

  /// Rejects the request's current "Awaiting Client Approval" state
  /// with a mandatory [remarks] explanation — the Reject dialog already
  /// enforces non-empty remarks before this is called. Mirrors
  /// [WorkOrderDetailController.rejectRequest] exactly.
  Future<void> rejectRequest(String remarks) async {
    isSubmittingApproval.value = true;
    try {
      await _repository.submitTransition(
        inventoryRequestId: order.id,
        stateTransitionId: _rejectTransitionId,
        comment: remarks,
      );
      AppSnackbar.showSuccess('reject_success'.tr);
      await _loadDetail();
    } on InventoryRequestException catch (e) {
      AppSnackbar.showError(
        e.message.trim().isNotEmpty ? e.message : 'something_went_wrong'.tr,
      );
    } catch (_) {
      AppSnackbar.showError('something_went_wrong'.tr);
    } finally {
      isSubmittingApproval.value = false;
    }
  }
}