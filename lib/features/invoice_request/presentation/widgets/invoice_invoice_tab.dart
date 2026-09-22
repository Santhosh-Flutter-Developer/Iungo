import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/core/widgets/attachment_upload_card.dart';
import 'package:iungo/features/invoice_request/domain/entities/invoice_request.dart';
import 'package:iungo/features/invoice_request/presentation/controllers/invoice_detail_controller.dart';
import 'package:iungo/features/invoice_request/presentation/widgets/invoice_financial_breakdown_card.dart';
import 'package:iungo/features/purchase_request/presentation/controllers/pr_role_controller.dart';

/// The Invoice Detail View's own "Invoice" tab — the invoice
/// attachment(s) filed at this stage, followed by the same Financial
/// Breakdown card shown on every other tab. Matches the reference
/// screenshot exactly (a single "222.pdf" under an "Invoice" heading).
///
/// The approver can also add an invoice attachment from here — but
/// only while this request is theirs to decide on (Approver role,
/// still pending): the upload card ([AttachmentUploadCard]) is hidden
/// for the requestor and for a request that's already been
/// approved/rejected.
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
        if (request.invoiceFileNames.isEmpty)
          Text(
            'invoice_no_attachment'.tr,
            style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
          )
        else
          for (final fileName in request.invoiceFileNames)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AttachmentTile(fileName: fileName),
            ),
        Obx(() {
          if (!roleController.isApprover || !request.isPendingApproval) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.only(top: 10),
            child: AttachmentUploadCard(
              isUploading: controller.isUploadingAttachment.value,
              onBrowse: controller.addInvoiceAttachment,
            ),
          );
        }),
        const SizedBox(height: 16),
        InvoiceFinancialBreakdownCard(request: request),
      ],
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({required this.fileName});

  final String fileName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
              ),
            ),
          ),
          const Icon(
            Icons.download_outlined,
            size: 20,
            color: AppColors.headingBlueGrey,
          ),
        ],
      ),
    );
  }
}
