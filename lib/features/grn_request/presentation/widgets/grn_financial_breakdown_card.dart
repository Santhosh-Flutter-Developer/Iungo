import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/features/grn_request/domain/entities/grn_request.dart';

/// "Total lines / Administrative expenses / Total Before VAT / VAT 15% /
/// Total" breakdown card — shown on the Summary, Requested Supply Items
/// and GRN tabs of the Detail View, matching the reference screenshots.
/// Mirrors `PrFinancialBreakdownCard` shape for shape.
class GrnFinancialBreakdownCard extends StatelessWidget {
  const GrnFinancialBreakdownCard({super.key, required this.request});

  final GrnRequest request;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          _Row(
            label: 'pr_total_lines'.tr,
            value: '${request.totalLines.toStringAsFixed(2)} SAR',
          ),
          const SizedBox(height: 12),
          _Row(
            label: 'pr_administrative_expenses'.tr,
            value:
                '${request.administrativeExpensesPercent.toStringAsFixed(0)} %',
          ),
          const SizedBox(height: 12),
          _Row(
            label: 'pr_total_before_vat'.tr,
            value: '${request.totalBeforeVat.toStringAsFixed(2)} SAR',
          ),
          const SizedBox(height: 12),
          _Row(
            label: 'pr_vat_15'.tr,
            value: '${request.vatAmount.toStringAsFixed(2)} SAR',
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 14),
          _Row(
            label: 'pr_total'.tr,
            value: '${request.totalAmount.toStringAsFixed(2)} SAR',
            emphasized: true,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: emphasized ? 16 : 14,
            fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
            color: emphasized ? AppColors.textDark : AppColors.headingBlueGrey,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: emphasized ? 16 : 14,
            fontWeight: FontWeight.w700,
            color: emphasized ? AppColors.prStatusGreen : AppColors.textDark,
          ),
        ),
      ],
    );
  }
}
