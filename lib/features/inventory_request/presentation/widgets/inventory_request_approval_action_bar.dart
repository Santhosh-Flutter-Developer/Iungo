import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/core/widgets/approval_dialogs.dart';
import 'package:iungo/features/inventory_request/presentation/controllers/inventory_request_detail_controller.dart';

/// Sticky bottom "Approve" / "Reject" bar for the Inventory Request
/// Detail View — shown only while the request is in the "Awaiting
/// Client Approval" state (see [InventoryRequest.isAwaitingClientApproval]).
///
/// Approve asks for a simple yes/no confirmation. Reject additionally
/// requires the user to type a remarks explaining the rejection —
/// remarks are mandatory, so the Reject button in that dialog stays
/// disabled until the field is non-empty.
///
/// UI-only for now: both actions call
/// [InventoryRequestDetailController.approveRequest]/[rejectRequest],
/// which are currently no-op stubs (TODO'd for the real API).
class InventoryRequestApprovalActionBar extends GetView<InventoryRequestDetailController> {
  const InventoryRequestApprovalActionBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value ||
          controller.errorMessage.value.isNotEmpty ||
          !controller.order.isAwaitingClientApproval) {
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
                    onPressed: isSubmitting ? null : () => _confirmReject(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.attachmentDeleteText,
                      side: const BorderSide(color: AppColors.attachmentDeleteText),
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
                    onPressed: isSubmitting ? null : () => _confirmApprove(context),
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
                            style: const TextStyle(fontWeight: FontWeight.w600),
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