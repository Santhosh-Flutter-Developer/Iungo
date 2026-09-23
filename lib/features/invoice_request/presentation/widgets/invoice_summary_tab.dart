import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/features/invoice_request/domain/entities/invoice_request.dart';
import 'package:iungo/features/invoice_request/presentation/widgets/invoice_financial_breakdown_card.dart';
import 'package:iungo/features/purchase_request/presentation/widgets/pr_attachment_tile.dart';

/// Summary tab of the Invoice Detail View — General Specification
/// fields, the Financial Breakdown card, and the quotation attachment
/// (if any). Mirrors `GrnSummaryTab` shape for shape.
class InvoiceSummaryTab extends StatelessWidget {
  const InvoiceSummaryTab({super.key, required this.request});

  final InvoiceRequest request;

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
          leftLabel: 'pr_location'.tr,
          leftValue: request.location,
          rightLabel: 'pr_work_order_no'.tr,
          rightValue: request.workOrderNo,
        ),
        _FieldPairRow(
          leftLabel: 'pr_purpose'.tr,
          leftValue: request.purpose,
          rightLabel: 'pr_category'.tr,
          rightValue: request.category,
        ),
        _FieldPairRow(
          leftLabel: 'pr_created_by'.tr,
          leftValue: request.createdBy,
          rightLabel: 'created'.tr,
          rightValue: request.requestDateLabel,
        ),
        _FieldPairRow(
          leftLabel: 'pr_delivery_date'.tr,
          leftValue: request.deliveryDateLabel,
          rightLabel: 'pr_contract'.tr,
          rightValue: request.contract,
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
        InvoiceFinancialBreakdownCard(request: request),
        if (request.attachments.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'pr_quotation'.tr,
            style: const TextStyle(fontSize: 13, color: AppColors.labelGrey),
          ),
          const SizedBox(height: 10),
          for (final attachment in request.attachments)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: PrAttachmentTile(attachment: attachment),
            ),
        ],
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
