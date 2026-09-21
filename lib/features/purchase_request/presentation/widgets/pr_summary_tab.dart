import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/features/purchase_request/domain/entities/pr_attachment.dart';
import 'package:iungo/features/purchase_request/domain/entities/purchase_request.dart';
import 'package:iungo/features/purchase_request/presentation/controllers/pr_detail_controller.dart';
import 'package:iungo/features/purchase_request/presentation/controllers/pr_role_controller.dart';
import 'package:iungo/features/purchase_request/presentation/widgets/pr_attachment_tile.dart';
import 'package:iungo/features/purchase_request/presentation/widgets/pr_financial_breakdown_card.dart';

/// Summary tab of the PR Detail View — General Specification fields,
/// the Financial Breakdown card, and the attachments (if any). Every
/// value comes from the API record.
/// Field grid styling mirrors
/// `InventoryRequestDetailOverviewTab`'s `_FieldPairRow`/`_FieldItem`.
class PrSummaryTab extends StatelessWidget {
  const PrSummaryTab({super.key, required this.request});

  final PurchaseRequest request;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        Text(
          'pr_general_specification'.tr,
          style: const TextStyle(fontSize: 13, color: AppColors.labelGrey),
        ),
        const SizedBox(height: 18),
        _FieldPairRow(
          leftLabel: 'pr_contract'.tr,
          leftValue: request.contract,
          rightLabel: 'pr_location'.tr,
          rightValue: request.location,
        ),
        _FieldPairRow(
          leftLabel: 'pr_work_order_no'.tr,
          leftValue: request.workOrderNo,
          rightLabel: 'created'.tr,
          rightValue: request.requestDateLabel,
        ),
        _FieldPairRow(
          leftLabel: 'pr_delivery_date'.tr,
          leftValue: request.deliveryDateLabel,
          rightLabel: 'pr_category'.tr,
          rightValue: request.category,
        ),
        _FieldPairRow(
          leftLabel: 'pr_purpose'.tr,
          leftValue: request.purpose,
          rightLabel: 'pr_created_by'.tr,
          rightValue: request.createdBy,
        ),
        _FieldPairRow(
          leftLabel: 'pr_next_approval'.tr,
          leftValue: request.nextApprovalName ?? '--',
          rightLabel: 'pr_stage'.tr,
          rightValue: request.stageLabel,
          isLast: true,
        ),
        const SizedBox(height: 10),
        Text(
          'pr_request_description'.tr,
          style: const TextStyle(fontSize: 13, color: AppColors.labelGrey),
        ),
        const SizedBox(height: 6),
        Text(
          request.requestDescription.trim().isEmpty
              ? '--'
              : request.requestDescription,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.headingBlueGrey,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        const Divider(color: AppColors.divider, height: 1),
        const SizedBox(height: 20),
        PrFinancialBreakdownCard(request: request),
        PrAttachmentsSection(request: request),
      ],
    );
  }
}

class _FieldPairRow extends StatelessWidget {
  const _FieldPairRow({
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
    this.isLast = false,
  });

  final String leftLabel;
  final String leftValue;
  final String rightLabel;
  final String rightValue;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _FieldItem(label: leftLabel, value: leftValue)),
          const SizedBox(width: 16),
          Expanded(child: _FieldItem(label: rightLabel, value: rightValue)),
        ],
      ),
    );
  }
}

class _FieldItem extends StatelessWidget {
  const _FieldItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.labelGrey),
        ),
        const SizedBox(height: 4),
        Text(
          value.trim().isEmpty ? '--' : value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }
}

/// The "Quotation" attachment list.
///
///  * Requestor (or anyone on a non-actionable request): plain
///    downloadable files.
///  * Approver on an Action Required request that is still pending: the
///    files become a single-selection (radio-style) list — exactly one
///    must be selected before the request can be approved. The selected
///    file's name is what `selected_attachments` carries.
class PrAttachmentsSection extends StatelessWidget {
  const PrAttachmentsSection({super.key, required this.request});

  final PurchaseRequest request;

  @override
  Widget build(BuildContext context) {
    if (request.attachments.isEmpty) return const SizedBox.shrink();

    final controller = Get.find<PrDetailController>();
    final roleController = Get.find<PrRoleController>();

    return Obx(() {
      final selectable = roleController.isApprover &&
          controller.canDecide &&
          controller.pr.isActionable;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            'pr_quotation'.tr,
            style: const TextStyle(fontSize: 13, color: AppColors.labelGrey),
          ),
          if (selectable) ...[
            const SizedBox(height: 4),
            Text(
              'pr_select_attachment_hint'.tr,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
          const SizedBox(height: 10),
          for (final PrAttachment attachment in request.attachments)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: PrAttachmentTile(
                attachment: attachment,
                selectable: selectable,
                selected:
                    selectable && controller.isAttachmentSelected(attachment),
                onSelect: () => controller.selectAttachment(attachment),
              ),
            ),
        ],
      );
    });
  }
}
