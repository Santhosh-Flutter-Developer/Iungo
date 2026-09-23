import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/core/widgets/attachment_upload_card.dart';
import 'package:iungo/features/invoice_request/domain/entities/invoice_request.dart';
import 'package:iungo/features/invoice_request/presentation/controllers/invoice_detail_controller.dart';
import 'package:iungo/features/invoice_request/presentation/widgets/invoice_financial_breakdown_card.dart';
import 'package:iungo/features/purchase_request/domain/entities/pr_attachment.dart';
import 'package:iungo/features/purchase_request/presentation/controllers/pr_role_controller.dart';
import 'package:iungo/features/purchase_request/presentation/widgets/pr_attachment_tile.dart';

/// The Invoice Detail View's own "Invoice" tab — the invoice
/// attachment(s) filed at this stage, followed by the same Financial
/// Breakdown card shown on every other tab. Matches the reference
/// screenshot exactly (a single "222.pdf" under an "Invoice" heading).
/// Mirrors `GrnDeliveryNotesTab` shape for shape.
///
/// The approver can also add (or remove a not-yet-submitted) invoice
/// attachment from here — but only while this request is theirs to
/// decide on (Action Required, still pending): the upload card
/// ([AttachmentUploadCard]) is hidden for the requestor and for a
/// request that's already been approved/rejected. Unlike GRN, at least
/// one attachment is NOT required to approve.
class InvoiceInvoiceTab extends StatelessWidget {
  const InvoiceInvoiceTab({super.key, required this.request});

  final InvoiceRequest request;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<InvoiceDetailController>();
    final roleController = Get.find<PrRoleController>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        Text(
          'pr_invoice'.tr,
          style: const TextStyle(fontSize: 13, color: AppColors.labelGrey),
        ),
        const SizedBox(height: 14),
        Obx(() {
          final canEdit = roleController.isApprover &&
              controller.canDecide &&
              request.isActionable &&
              request.fileUpload == true;
          final names = controller.invoiceAttachments.toList();

          if (names.isEmpty && !canEdit) {
            return Text(
              'invoice_no_attachment'.tr,
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
                      ? _InvoiceAttachmentRow(
                          attachment: PrAttachment.fromUrl(name),
                          onDelete: () =>
                              controller.removeInvoiceAttachment(name),
                        )
                      : PrAttachmentTile(
                          attachment: PrAttachment.fromUrl(name),
                        ),
                ),
              if (canEdit)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: AttachmentUploadCard(
                    isUploading: controller.isUploadingAttachment.value,
                    onBrowse: controller.addInvoiceAttachment,
                  ),
                ),
            ],
          );
        }),
        const SizedBox(height: 16),
        InvoiceFinancialBreakdownCard(request: request),
      ],
    );
  }
}

/// An invoice-attachment row with a trailing "Delete" action, shown
/// instead of the plain download tile while the approver can still edit
/// the list (before approving).
class _InvoiceAttachmentRow extends StatelessWidget {
  const _InvoiceAttachmentRow({required this.attachment, required this.onDelete});

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
