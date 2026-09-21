import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/core/widgets/app_snackbar.dart';
import 'package:iungo/core/widgets/approval_dialogs.dart';
import 'package:iungo/features/purchase_request/presentation/controllers/pr_detail_controller.dart';
import 'package:iungo/features/purchase_request/presentation/controllers/pr_role_controller.dart';

/// Sticky bottom "Reject" / "Approve" bar for the PR Detail View — only
/// shown for the Approver role (see [PrRoleController]) on a request
/// opened from the Action Required list that is still actionable per the
/// API record. Mirrors `InventoryRequestApprovalActionBar`, including its
/// Approve/Reject confirmation dialogs.
///
/// Approve first checks that exactly one attachment is selected (see
/// `PrSummaryTab`'s attachment section) and only then asks for
/// confirmation; Reject collects the mandatory remarks.
class PrApprovalActionBar extends GetView<PrDetailController> {
  const PrApprovalActionBar({super.key});

  @override
  Widget build(BuildContext context) {
    final roleController = Get.find<PrRoleController>();

    return Obx(() {
      if (!roleController.isApprover ||
          !controller.canDecide ||
          !controller.pr.isActionable) {
        return const SizedBox.shrink();
      }

      final isSubmitting = controller.isSubmittingApproval.value;

      return DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.scaffoldWhite,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        isSubmitting ? null : () => _confirmReject(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.attachmentDeleteText,
                      side: const BorderSide(
                        color: AppColors.attachmentDeleteText,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'reject'.tr,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        isSubmitting ? null : () => _confirmApprove(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : Text(
                            'approve'.tr,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Future<void> _confirmApprove(BuildContext context) async {
    // Exactly one attachment must be selected. Checked up front so the
    // approver isn't asked to confirm something that can't go through
    // (and checked again inside approveRequest right before the API
    // call).
    final validation = controller.approvalSelectionError();
    if (validation != null) {
      AppSnackbar.showError(validation);
      return;
    }

    final confirmed = await showApproveRequestDialog(context);
    if (confirmed == true) {
      await controller.approveRequest();
    }
  }

  Future<void> _confirmReject(BuildContext context) async {
    final remarks = await showRejectRequestDialog(context);
    // null = cancelled. Anything else goes to the controller, which
    // enforces the mandatory-remarks rule before calling the API.
    if (remarks != null) {
      await controller.rejectRequest(remarks);
    }
  }
}
