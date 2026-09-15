import 'package:get/get.dart';
import 'package:iungo/core/widgets/app_snackbar.dart';
import 'package:iungo/features/purchase_request/data/purchase_request_repository.dart';
import 'package:iungo/features/purchase_request/domain/entities/purchase_request.dart';

/// Holds the state for one Purchase Request's Detail View (Summary /
/// Requested Supply Items tabs) plus the Approve/Reject actions.
/// Simpler than `InventoryRequestDetailController`: the card tapped to
/// get here already carries every field the Detail View needs (no
/// separate "fetch full record by id" call), since the whole feature is
/// still backed by one local, fully-populated data set.
class PrDetailController extends GetxController {
  PrDetailController(this._repository, PurchaseRequest initial)
      : request = initial.obs;

  final PurchaseRequestRepository _repository;

  PurchaseRequest get pr => request.value;
  final Rx<PurchaseRequest> request;

  /// True while an approve/reject submission is in flight — disables
  /// the action buttons and shows a spinner so a double-tap can't fire
  /// the request twice once the API is wired up.
  final RxBool isSubmittingApproval = false.obs;

  Future<void> approveRequest() async {
    isSubmittingApproval.value = true;
    try {
      request.value = await _repository.submitDecision(
        id: pr.id,
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
        id: pr.id,
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
