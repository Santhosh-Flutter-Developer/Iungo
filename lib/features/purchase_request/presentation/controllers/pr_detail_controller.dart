import 'package:get/get.dart';
import 'package:iungo/core/services/session_service.dart';
import 'package:iungo/core/widgets/app_snackbar.dart';
import 'package:iungo/features/purchase_request/data/purchase_request_repository.dart';
import 'package:iungo/features/purchase_request/domain/entities/pr_attachment.dart';
import 'package:iungo/features/purchase_request/domain/entities/purchase_request.dart';
import 'package:iungo/features/purchase_request/domain/validators/pr_decision_validator.dart';
import 'package:iungo/features/purchase_request/presentation/utils/pr_error_message.dart';
import 'package:iungo/features/purchase_request/presentation/utils/pr_session.dart';

/// Holds the state for one Purchase Request's Detail View (Summary /
/// Requested Supply Items tabs) plus the Approve/Reject actions.
///
/// The record tapped on the list already carries every field the Detail
/// View needs (items, attachments, pipeline, ...) — the API guide has no
/// separate "get one PR" call — so nothing is fetched to open it.
///
/// Approving needs EXACTLY ONE selected attachment ([selectedAttachmentNames]);
/// rejecting needs remarks. Both are validated here before any API call.
/// After a successful approve/reject the screen closes with a `true`
/// result so the list that opened it reloads from the server (counts,
/// status and pipeline all come back fresh).
class PrDetailController extends GetxController {
  PrDetailController(
    this._repository,
    this._session,
    PurchaseRequest initial, {
    this.canDecide = false,
  }) : request = initial.obs;

  final PurchaseRequestRepository _repository;
  final SessionService _session;

  /// Whether this record was opened from the approver's Action Required
  /// list (the only place Approve/Reject may show).
  final bool canDecide;

  PurchaseRequest get pr => request.value;
  final Rx<PurchaseRequest> request;

  /// True while an approve/reject submission is in flight — disables the
  /// action buttons and shows a spinner so a double-tap can't fire the
  /// request twice.
  final RxBool isSubmittingApproval = false.obs;

  /// The attachment file name(s) the approver ticked. The UI is
  /// single-select (picking one replaces the previous pick), and the
  /// approve action refuses to run unless exactly one is present.
  final RxList<String> selectedAttachmentNames = <String>[].obs;

  // ---- attachment selection --------------------------------------------

  void selectAttachment(PrAttachment attachment) {
    selectedAttachmentNames.assignAll([attachment.apiFileName]);
  }

  bool isAttachmentSelected(PrAttachment attachment) =>
      selectedAttachmentNames.contains(attachment.apiFileName);

  /// The validation message for the current selection, or null when
  /// exactly one attachment is selected.
  String? approvalSelectionError() {
    final key = PrDecisionValidator.approveSelectionErrorKey(
      selectedAttachmentNames.toList(),
    );
    return key?.tr;
  }

  // ---- approve / reject ------------------------------------------------

  Future<void> approveRequest() async {
    if (isSubmittingApproval.value) return;

    final validation = approvalSelectionError();
    if (validation != null) {
      AppSnackbar.showError(validation);
      return;
    }

    isSubmittingApproval.value = true;
    try {
      await _repository.approvePurchaseRequest(
        prId: pr.id,
        userId: requirePrUserId(_session),
        attachmentFileName: selectedAttachmentNames.first,
      );
      selectedAttachmentNames.clear();
      // Close first so the success message shows over the list.
      Get.back(result: true);
      AppSnackbar.showSuccess('approve_success'.tr);
    } catch (e) {
      AppSnackbar.showError(prErrorMessage(e, fallbackKey: 'pr_approve_failed'));
    } finally {
      isSubmittingApproval.value = false;
    }
  }

  Future<void> rejectRequest(String remarks) async {
    if (isSubmittingApproval.value) return;

    final errorKey = PrDecisionValidator.rejectRemarksErrorKey(remarks);
    if (errorKey != null) {
      AppSnackbar.showError(errorKey.tr);
      return;
    }

    isSubmittingApproval.value = true;
    try {
      await _repository.rejectPurchaseRequest(
        prId: pr.id,
        userId: requirePrUserId(_session),
        remarks: remarks.trim(),
      );
      selectedAttachmentNames.clear();
      Get.back(result: true);
      AppSnackbar.showSuccess('reject_success'.tr);
    } catch (e) {
      AppSnackbar.showError(prErrorMessage(e, fallbackKey: 'pr_reject_failed'));
    } finally {
      isSubmittingApproval.value = false;
    }
  }

  @override
  void onClose() {
    // The selection never outlives the screen.
    selectedAttachmentNames.clear();
    super.onClose();
  }
}
