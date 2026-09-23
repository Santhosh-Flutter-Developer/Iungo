import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:iungo/core/services/session_service.dart';
import 'package:iungo/core/widgets/app_snackbar.dart';
import 'package:iungo/features/invoice_request/data/invoice_request_repository.dart';
import 'package:iungo/features/invoice_request/domain/entities/invoice_request.dart';
import 'package:iungo/features/invoice_request/domain/validators/invoice_decision_validator.dart';
import 'package:iungo/features/purchase_request/presentation/utils/pr_error_message.dart';
import 'package:iungo/features/purchase_request/presentation/utils/pr_session.dart';
import 'package:iungo/features/service_request/domain/entities/attachment_file.dart';

/// Holds the state for one Invoice Request's Detail View (Summary /
/// Requested Supply Items / GRN / Invoice tabs) plus the Approve/Reject
/// actions and the Invoice tab's attachment upload. Mirrors
/// `GrnDetailController` shape for shape.
///
/// The record tapped on the list already carries everything the Detail
/// View needs (items, attachments, pipeline, ...) — same as PR/GRN,
/// there is no separate "get one Invoice" endpoint.
///
/// An Invoice can only be approved once at least one attachment is
/// present ([InvoiceDecisionValidator.approveRequiresAttachment]) — the
/// approver adds one or more from here; [invoiceAttachments] tracks
/// both whatever the record already carried and whatever's been
/// uploaded in this session, and that combined list is what's sent to
/// the approve API.
class InvoiceDetailController extends GetxController {
  InvoiceDetailController(
    this._repository,
    this._session,
    InvoiceRequest initial, {
    this.canDecide = false,
  })  : request = initial.obs,
        invoiceAttachments = <String>[
          for (final a in initial.invoices) a.name,
        ].obs;

  final InvoiceRequestRepository _repository;
  final SessionService _session;

  /// Whether this record was opened from the approver's Action Required
  /// list (the only place Approve/Reject may show).
  final bool canDecide;

  InvoiceRequest get invoice => request.value;
  final Rx<InvoiceRequest> request;

  /// Invoice attachment file names — pre-existing plus uploaded this
  /// session — shown on the Invoice tab and sent as-is to the approve
  /// API.
  final RxList<String> invoiceAttachments;

  /// True while an approve/reject submission is in flight — disables
  /// the action buttons and shows a spinner so a double-tap can't fire
  /// the request twice.
  final RxBool isSubmittingApproval = false.obs;

  /// True while the approver's "Browse Files" pick is in flight, on the
  /// Invoice tab's upload card (see [AttachmentUploadCard]).
  final RxBool isUploadingAttachment = false.obs;

  /// The validation message for the current attachment state, or null
  /// when at least one is attached.
  String? attachmentValidationError() {
    final key =
        InvoiceDecisionValidator.approveRequiresAttachment(invoiceAttachments);
    return key?.tr;
  }

  /// Picks one or more files and uploads each as an invoice attachment,
  /// appending its stored filename to [invoiceAttachments] as soon as it
  /// succeeds (each file fails/succeeds independently).
  Future<void> addInvoiceAttachment() async {
    if (isUploadingAttachment.value) return;
    isUploadingAttachment.value = true;
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true);
      final files = result?.files ?? const [];
      if (files.isEmpty) return;

      for (final file in files) {
        try {
          final saved = await _repository.uploadInvoiceAttachment(
            AttachmentFile(
              name: file.name,
              path: file.path,
              bytes: file.bytes,
              sizeBytes: file.size,
            ),
          );
          invoiceAttachments.add(saved);
        } catch (e) {
          AppSnackbar.showError(
            prErrorMessage(e, fallbackKey: 'attachment_pick_failed'),
          );
        }
      }
    } catch (_) {
      AppSnackbar.showError('attachment_pick_failed'.tr);
    } finally {
      isUploadingAttachment.value = false;
    }
  }

  /// Removes a not-yet-submitted invoice attachment (e.g. added by
  /// mistake) before Approve is pressed.
  void removeInvoiceAttachment(String fileName) {
    invoiceAttachments.remove(fileName);
  }

  Future<void> approveRequest() async {
    if (isSubmittingApproval.value) return;

    final validation = attachmentValidationError();
    if (validation != null) {
      AppSnackbar.showError(validation);
      return;
    }

    isSubmittingApproval.value = true;
    try {
      await _repository.approveInvoiceRequest(
        invoiceId: invoice.id,
        userId: requirePrUserId(_session),
        invoiceFileNames: invoiceAttachments.toList(),
      );
      Get.back(result: true);
      AppSnackbar.showSuccess('approve_success'.tr);
    } catch (e) {
      AppSnackbar.showError(
        prErrorMessage(e, fallbackKey: 'invoice_approve_failed'),
      );
    } finally {
      isSubmittingApproval.value = false;
    }
  }

  Future<void> rejectRequest(String remarks) async {
    if (isSubmittingApproval.value) return;

    final errorKey = InvoiceDecisionValidator.rejectRemarksErrorKey(remarks);
    if (errorKey != null) {
      AppSnackbar.showError(errorKey.tr);
      return;
    }

    isSubmittingApproval.value = true;
    try {
      await _repository.rejectInvoiceRequest(
        invoiceId: invoice.id,
        userId: requirePrUserId(_session),
        remarks: remarks.trim(),
      );
      Get.back(result: true);
      AppSnackbar.showSuccess('reject_success'.tr);
    } catch (e) {
      AppSnackbar.showError(
        prErrorMessage(e, fallbackKey: 'invoice_reject_failed'),
      );
    } finally {
      isSubmittingApproval.value = false;
    }
  }
}
