import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/core/utils/app_date_format.dart';
import 'package:iungo/features/invoice_request/domain/entities/invoice_request.dart';
import 'package:iungo/features/invoice_request/presentation/widgets/invoice_financial_breakdown_card.dart';

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
          rightValue: AppDateFormat.mediumDate(request.requestDate),
        ),
        _FieldPairRow(
          leftLabel: 'pr_delivery_date'.tr,
          leftValue: AppDateFormat.mediumDate(request.deliveryDate),
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
        if (request.quotationFileNames.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'pr_quotation'.tr,
            style: const TextStyle(fontSize: 13, color: AppColors.labelGrey),
          ),
          const SizedBox(height: 10),
          for (final fileName in request.quotationFileNames)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AttachmentTile(fileName: fileName),
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
              Icons.insert_drive_file_outlined,
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
