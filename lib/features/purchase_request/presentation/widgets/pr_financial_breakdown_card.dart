import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/features/purchase_request/domain/entities/purchase_request.dart';

/// "Total lines / Administrative expenses / Total Before VAT / VAT 15% /
/// Total" breakdown card — shown on both the Summary and Requested
/// Supply Items tabs of the Detail View, matching the reference video.
class PrFinancialBreakdownCard extends StatelessWidget {
  const PrFinancialBreakdownCard({super.key, required this.request});

  final PurchaseRequest request;

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
            value: '${_percent(request.administrativeExpensesPercent)} %',
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

/// "6" for a whole percentage, "6.5" otherwise.
String _percent(double value) {
  final rounded = value.roundToDouble();
  if ((value - rounded).abs() < 0.005) return rounded.toStringAsFixed(0);
  return value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
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
