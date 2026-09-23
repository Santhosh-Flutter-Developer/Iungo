import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/features/invoice_request/domain/entities/invoice_request.dart';
import 'package:iungo/features/invoice_request/presentation/widgets/invoice_financial_breakdown_card.dart';
import 'package:iungo/features/purchase_request/presentation/widgets/pr_attachment_tile.dart';

/// The Invoice Detail View's "GRN" tab — the delivery note attachments
/// carried over from the GRN stage, followed by the same Financial
/// Breakdown card shown on every other tab. Read-only: by the time a
/// request reaches the Invoice stage its GRN stage is already
/// completed. Mirrors `GrnDeliveryNotesTab` shape for shape.
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
        if (request.deliveryNotes.isEmpty)
          Text(
            'grn_no_delivery_notes'.tr,
            style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
          )
        else
          for (final attachment in request.deliveryNotes)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: PrAttachmentTile(attachment: attachment),
            ),
        const SizedBox(height: 16),
        InvoiceFinancialBreakdownCard(request: request),
      ],
    );
  }
}
