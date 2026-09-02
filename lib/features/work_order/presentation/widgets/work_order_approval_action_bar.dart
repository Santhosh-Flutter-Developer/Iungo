import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/features/work_order/domain/entities/work_order_status.dart';
import 'package:iungo/features/work_order/presentation/controllers/work_order_detail_controller.dart';

/// Sticky bottom "Approve" / "Reject" bar for the Work Order Detail
/// View — shown only while the work order is in the "Awaiting Closure
/// Approval from Client" status (see
/// [WorkOrderStatusX.isAwaitingClosureApprovalFromClient]).
///
/// Approve asks for a simple yes/no confirmation. Reject additionally
/// requires the user to type remarks explaining the rejection —
/// remarks are mandatory, so the Reject button in that dialog stays
/// disabled until the field is non-empty.
///
/// UI-only for now: both actions call
/// [WorkOrderDetailController.approveRequest]/[rejectRequest], which
/// are currently no-op stubs (TODO'd for the real API).
class WorkOrderApprovalActionBar extends GetView<WorkOrderDetailController> {
  const WorkOrderApprovalActionBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value ||
          controller.errorMessage.value.isNotEmpty ||
          !controller.order.status.isAwaitingClosureApprovalFromClient) {
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('approve_request_confirm_title'.tr),
        content: Text('approve_request_confirm_message'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
            child: Text('approve'.tr),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await controller.approveRequest();
    }
  }

  Future<void> _confirmReject(BuildContext context) async {
    final remarks = await showDialog<String>(
      context: context,
      builder: (dialogContext) => const _RejectRemarksDialog(),
    );

    if (remarks != null && remarks.trim().isNotEmpty) {
      await controller.rejectRequest(remarks.trim());
    }
  }
}

/// The "Reject Request" dialog — a mandatory multiline remarks field
/// plus Cancel/Reject actions. The Reject action stays disabled (and,
/// if somehow tapped anyway, shows a validation message) until remarks
/// are non-empty, since remarks are required to reject a request.
class _RejectRemarksDialog extends StatefulWidget {
  const _RejectRemarksDialog();

  @override
  State<_RejectRemarksDialog> createState() => _RejectRemarksDialogState();
}

class _RejectRemarksDialogState extends State<_RejectRemarksDialog> {
  final TextEditingController _remarksController = TextEditingController();
  bool _showError = false;

  bool get _isValid => _remarksController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_isValid) {
      setState(() => _showError = true);
      return;
    }
    Navigator.of(context).pop(_remarksController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('reject_request'.tr),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'reject_request_prompt'.tr,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _remarksController,
            maxLines: 4,
            minLines: 3,
            textInputAction: TextInputAction.done,
            onChanged: (_) {
              if (_showError && _isValid) setState(() => _showError = false);
            },
            decoration: InputDecoration(
              labelText: 'remarks'.tr,
              hintText: 'enter_remarks_hint'.tr,
              filled: true,
              fillColor: AppColors.inputFill,
              errorText: _showError ? 'remarks_required'.tr : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.inputBorder),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('cancel'.tr),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.attachmentDeleteText,
            foregroundColor: AppColors.white,
          ),
          child: Text('reject'.tr),
        ),
      ],
    );
  }
}