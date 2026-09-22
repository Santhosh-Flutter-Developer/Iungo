import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/core/widgets/attachment_upload_card.dart';
import 'package:iungo/features/grn_request/domain/entities/grn_request.dart';
import 'package:iungo/features/grn_request/presentation/controllers/grn_detail_controller.dart';
import 'package:iungo/features/grn_request/presentation/widgets/grn_financial_breakdown_card.dart';
import 'package:iungo/features/purchase_request/domain/entities/pr_attachment.dart';
import 'package:iungo/features/purchase_request/presentation/controllers/pr_role_controller.dart';
import 'package:iungo/features/purchase_request/presentation/widgets/pr_attachment_tile.dart';

/// The Detail View's third "GRN" tab — the delivery notes filed at the
/// GRN stage, followed by the same Financial Breakdown card shown on
/// Summary/Requested Supply Items. Mirrors `PrSummaryTab`'s attachment
/// section shape for shape.
///
/// For the approver, on a request that's still theirs to decide on
/// (Action Required, still pending), this also shows the
/// "+ Add Delivery Note" upload card ([AttachmentUploadCard]) — a GRN
/// can't be approved without at least one delivery note attached (see
/// [GrnDecisionValidator]), and this is the only place to add one. The
/// requestor, and an approver on a Completed/Rejected request, only
/// ever see the read-only list.
class GrnDeliveryNotesTab extends StatelessWidget {
  const GrnDeliveryNotesTab({super.key, required this.request});

  final GrnRequest request;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<GrnDetailController>();
    final roleController = Get.find<PrRoleController>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        Text(
          'grn_delivery_notes'.tr,
          style: const TextStyle(fontSize: 13, color: AppColors.labelGrey),
        ),
        const SizedBox(height: 14),
        Obx(() {
          final canEdit = roleController.isApprover &&
              controller.canDecide &&
              request.isActionable && request.fileUpload == true;
          final names = controller.deliveryNotes.toList();

          if (names.isEmpty && !canEdit) {
            return Text(
              'grn_no_delivery_notes'.tr,
              style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final name in names)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: canEdit
                      ? _DeliveryNoteRow(
                          attachment: PrAttachment.fromUrl(name),
                          onDelete: () => controller.removeDeliveryNote(name),
                        )
                      : PrAttachmentTile(
                          attachment: PrAttachment.fromUrl(name),
                        ),
                ),
              if (canEdit)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: AttachmentUploadCard(
                    isUploading: controller.isUploadingDeliveryNote.value,
                    onBrowse: controller.addDeliveryNote,
                  ),
                ),
            ],
          );
        }),
        const SizedBox(height: 16),
        GrnFinancialBreakdownCard(request: request),
      ],
    );
  }
}

/// A delivery-note row with a trailing "Delete" action, shown instead
/// of the plain download tile while the approver can still edit the
/// list (before approving).
class _DeliveryNoteRow extends StatelessWidget {
  const _DeliveryNoteRow({required this.attachment, required this.onDelete});

  final PrAttachment attachment;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: PrAttachmentTile(attachment: attachment)),
        const SizedBox(width: 8),
        TextButton(
          onPressed: onDelete,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.attachmentDeleteText,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
          child: Text(
            'delete'.tr,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
