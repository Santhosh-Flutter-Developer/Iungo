import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/features/grn_request/domain/entities/grn_request.dart';
import 'package:iungo/features/grn_request/presentation/widgets/grn_financial_breakdown_card.dart';

/// The Detail View's third "GRN" tab — the delivery note attachments
/// filed at the GRN stage, followed by the same Financial Breakdown
/// card shown on Summary/Requested Supply Items. Matches the reference
/// screenshot exactly (Delivery notes list on the left, Financial
/// Breakdown card on the right on wide layouts, stacked on mobile).
class GrnDeliveryNotesTab extends StatelessWidget {
  const GrnDeliveryNotesTab({super.key, required this.request});

  final GrnRequest request;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        Text(
          'grn_delivery_notes'.tr,
          style: const TextStyle(fontSize: 13, color: AppColors.labelGrey),
        ),
        const SizedBox(height: 14),
        if (request.deliveryNoteFileNames.isEmpty)
          Text(
            'grn_no_delivery_notes'.tr,
            style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
          )
        else
          for (final fileName in request.deliveryNoteFileNames)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DeliveryNoteTile(fileName: fileName),
            ),
        const SizedBox(height: 16),
        GrnFinancialBreakdownCard(request: request),
      ],
    );
  }
}

class _DeliveryNoteTile extends StatelessWidget {
  const _DeliveryNoteTile({required this.fileName});

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
              Icons.local_shipping_outlined,
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
