import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/features/invoice_request/domain/entities/invoice_request.dart';
import 'package:iungo/features/invoice_request/presentation/widgets/invoice_financial_breakdown_card.dart';

/// The Invoice Detail View's "GRN" tab — the delivery note attachments
/// carried over from the GRN stage, followed by the same Financial
/// Breakdown card shown on every other tab. Matches the reference
/// screenshot exactly. Mirrors `GrnDeliveryNotesTab` shape for shape.
class InvoiceGrnTab extends StatelessWidget {
  const InvoiceGrnTab({super.key, required this.request});

  final InvoiceRequest request;

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
              child: _AttachmentTile(
                fileName: fileName,
                icon: Icons.local_shipping_outlined,
              ),
            ),
        const SizedBox(height: 16),
        InvoiceFinancialBreakdownCard(request: request),
      ],
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({required this.fileName, required this.icon});

  final String fileName;
  final IconData icon;

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
            child: Icon(icon, size: 20, color: AppColors.primary),
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
