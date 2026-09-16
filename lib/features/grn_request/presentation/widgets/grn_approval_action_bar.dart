import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/core/widgets/approval_dialogs.dart';
import 'package:iungo/features/grn_request/presentation/controllers/grn_detail_controller.dart';
import 'package:iungo/features/purchase_request/presentation/controllers/pr_role_controller.dart';

/// Sticky bottom "Reject" / "Approve" bar for the GRN Detail View — only
/// shown for the Approver role (shared [PrRoleController]) while the
/// request is still pending. Mirrors `PrApprovalActionBar` exactly.
class GrnApprovalActionBar extends GetView<GrnDetailController> {
  const GrnApprovalActionBar({super.key});

  @override
  Widget build(BuildContext context) {
    final roleController = Get.find<PrRoleController>();

    return Obx(() {
      if (!roleController.isApprover || !controller.grn.isPendingApproval) {
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
    final confirmed = await showApproveRequestDialog(context);
    if (confirmed == true) {
      await controller.approveRequest();
    }
  }

  Future<void> _confirmReject(BuildContext context) async {
    final remarks = await showRejectRequestDialog(context);
    if (remarks != null && remarks.trim().isNotEmpty) {
      await controller.rejectRequest(remarks.trim());
    }
  }
}
