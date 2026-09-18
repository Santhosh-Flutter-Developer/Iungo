import 'package:get/get.dart';
import 'package:iungo/core/widgets/app_snackbar.dart';
import 'package:iungo/features/invoice_request/data/invoice_request_repository.dart';
import 'package:iungo/features/invoice_request/domain/entities/invoice_request.dart';

/// Holds the state for one Invoice Request's Detail View (Summary /
/// Requested Supply Items / GRN / Invoice tabs) plus the Approve/Reject
/// actions. Mirrors `GrnDetailController` shape for shape.
class InvoiceDetailController extends GetxController {
  InvoiceDetailController(this._repository, InvoiceRequest initial)
      : request = initial.obs;

  final InvoiceRequestRepository _repository;

  InvoiceRequest get invoice => request.value;
  final Rx<InvoiceRequest> request;

  /// True while an approve/reject submission is in flight — disables
  /// the action buttons and shows a spinner so a double-tap can't fire
  /// the request twice once the API is wired up.
  final RxBool isSubmittingApproval = false.obs;

  Future<void> approveRequest() async {
    isSubmittingApproval.value = true;
    try {
      request.value = await _repository.submitDecision(
        id: invoice.id,
        approve: true,
      );
      AppSnackbar.showSuccess('approve_success'.tr);
    } catch (_) {
      AppSnackbar.showError('something_went_wrong'.tr);
    } finally {
      isSubmittingApproval.value = false;
    }
  }

  Future<void> rejectRequest(String remarks) async {
    isSubmittingApproval.value = true;
    try {
      request.value = await _repository.submitDecision(
        id: invoice.id,
        approve: false,
        remarks: remarks,
      );
      AppSnackbar.showSuccess('reject_success'.tr);
    } catch (_) {
      AppSnackbar.showError('something_went_wrong'.tr);
    } finally {
      isSubmittingApproval.value = false;
    }
  }
}
