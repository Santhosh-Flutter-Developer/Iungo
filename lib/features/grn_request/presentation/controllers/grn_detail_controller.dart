import 'package:get/get.dart';
import 'package:iungo/core/widgets/app_snackbar.dart';
import 'package:iungo/features/grn_request/data/grn_request_repository.dart';
import 'package:iungo/features/grn_request/domain/entities/grn_request.dart';

/// Holds the state for one GRN Request's Detail View (Summary /
/// Requested Supply Items / GRN tabs) plus the Approve/Reject actions.
/// Mirrors `PrDetailController` shape for shape.
class GrnDetailController extends GetxController {
  GrnDetailController(this._repository, GrnRequest initial)
      : request = initial.obs;

  final GrnRequestRepository _repository;

  GrnRequest get grn => request.value;
  final Rx<GrnRequest> request;

  /// True while an approve/reject submission is in flight — disables
  /// the action buttons and shows a spinner so a double-tap can't fire
  /// the request twice once the API is wired up.
  final RxBool isSubmittingApproval = false.obs;

  Future<void> approveRequest() async {
    isSubmittingApproval.value = true;
    try {
      request.value = await _repository.submitDecision(
        id: grn.id,
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
        id: grn.id,
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
