import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:iungo/core/services/session_service.dart';
import 'package:iungo/core/widgets/app_snackbar.dart';
import 'package:iungo/features/grn_request/data/grn_request_repository.dart';
import 'package:iungo/features/grn_request/domain/entities/grn_request.dart';
import 'package:iungo/features/grn_request/domain/validators/grn_decision_validator.dart';
import 'package:iungo/features/purchase_request/presentation/utils/pr_error_message.dart';
import 'package:iungo/features/purchase_request/presentation/utils/pr_session.dart';
import 'package:iungo/features/service_request/domain/entities/attachment_file.dart';

/// Holds the state for one GRN's Detail View (Summary / Requested
/// Supply Items / GRN tabs) plus the Approve/Reject actions and the
/// GRN tab's delivery-note upload. Mirrors `PrDetailController` shape
/// for shape.
///
/// The record tapped on the list already carries everything the Detail
/// View needs (items, attachments, pipeline, ...) — same as PR, there
/// is no separate "get one GRN" endpoint.
///
/// A GRN can only be approved once at least one delivery note is
/// attached ([GrnDecisionValidator.approveRequiresDeliveryNote]) — the
/// approver adds one or more from here; [deliveryNotes] tracks both
/// whatever the record already carried and whatever's been uploaded in
/// this session, and that combined list is what's sent to the approve
/// API.
class GrnDetailController extends GetxController {
  GrnDetailController(
    this._repository,
    this._session,
    GrnRequest initial, {
    this.canDecide = false,
  })  : request = initial.obs,
        deliveryNotes = <String>[
          for (final a in initial.deliveryNotes) a.name,
        ].obs;

  final GrnRequestRepository _repository;
  final SessionService _session;

  /// Whether this record was opened from the approver's Action Required
  /// list (the only place Approve/Reject may show).
  final bool canDecide;

  GrnRequest get grn => request.value;
  final Rx<GrnRequest> request;

  /// Delivery note file names — pre-existing plus uploaded this session
  /// — shown on the GRN tab and sent as-is to the approve API.
  final RxList<String> deliveryNotes;

  final RxBool isSubmittingApproval = false.obs;
  final RxBool isUploadingDeliveryNote = false.obs;

  /// The validation message for the current delivery-note state, or
  /// null when at least one is attached.
  String? deliveryNoteValidationError() {
    final key =
        GrnDecisionValidator.approveRequiresDeliveryNote(deliveryNotes);
    return key?.tr;
  }

  /// Picks one or more files and uploads each as a delivery note,
  /// appending its stored filename to [deliveryNotes] as soon as it
  /// succeeds (each file fails/succeeds independently).
  Future<void> addDeliveryNote() async {
    if (isUploadingDeliveryNote.value) return;
    isUploadingDeliveryNote.value = true;
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true);
      final files = result?.files ?? const [];
      if (files.isEmpty) return;

      for (final file in files) {
        try {
          final saved = await _repository.uploadDeliveryNote(
            AttachmentFile(
              name: file.name,
              path: file.path,
              bytes: file.bytes,
              sizeBytes: file.size,
            ),
          );
          deliveryNotes.add(saved);
        } catch (e) {
          AppSnackbar.showError(
            prErrorMessage(e, fallbackKey: 'attachment_pick_failed'),
          );
        }
      }
    } catch (_) {
      AppSnackbar.showError('attachment_pick_failed'.tr);
    } finally {
      isUploadingDeliveryNote.value = false;
    }
  }

  /// Removes an uploaded delivery note before approving (the
  /// "[Delete]" action next to each uploaded file).
  void removeDeliveryNote(String fileName) {
    deliveryNotes.remove(fileName);
  }

  Future<void> approveRequest() async {
    if (isSubmittingApproval.value) return;

    final validation = deliveryNoteValidationError();
    if (validation != null) {
      AppSnackbar.showError(validation);
      return;
    }

    isSubmittingApproval.value = true;
    try {
      await _repository.approveGrnRequest(
        grnId: grn.id,
        userId: requirePrUserId(_session),
        deliveryNoteFileNames: deliveryNotes.toList(),
      );
      Get.back(result: true);
      AppSnackbar.showSuccess('approve_success'.tr);
    } catch (e) {
      AppSnackbar.showError(
        prErrorMessage(e, fallbackKey: 'grn_approve_failed'),
      );
    } finally {
      isSubmittingApproval.value = false;
    }
  }

  Future<void> rejectRequest(String remarks) async {
    if (isSubmittingApproval.value) return;

    final errorKey = GrnDecisionValidator.rejectRemarksErrorKey(remarks);
    if (errorKey != null) {
      AppSnackbar.showError(errorKey.tr);
      return;
    }

    isSubmittingApproval.value = true;
    try {
      await _repository.rejectGrnRequest(
        grnId: grn.id,
        userId: requirePrUserId(_session),
        remarks: remarks.trim(),
      );
      Get.back(result: true);
      AppSnackbar.showSuccess('reject_success'.tr);
    } catch (e) {
      AppSnackbar.showError(
        prErrorMessage(e, fallbackKey: 'grn_reject_failed'),
      );
    } finally {
      isSubmittingApproval.value = false;
    }
  }
}
