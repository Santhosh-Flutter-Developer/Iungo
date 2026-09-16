import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/features/grn_request/domain/entities/grn_request.dart';
import 'package:iungo/features/grn_request/presentation/widgets/grn_financial_breakdown_card.dart';
import 'package:iungo/features/purchase_request/domain/entities/purchase_request_item.dart';

/// Requested Supply Items tab — the desktop reference's purple-header
/// spec table, reflowed into mobile-friendly item cards (S.No, material
/// code/description, quantity/unit price/total), followed by the same
/// Financial Breakdown card shown on Summary. Mirrors `PrSupplyItemsTab`
/// shape for shape.
class GrnSupplyItemsTab extends StatelessWidget {
  const GrnSupplyItemsTab({super.key, required this.request});

  final GrnRequest request;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        Text(
          'pr_requested_supply_items'.tr,
          style: const TextStyle(fontSize: 13, color: AppColors.labelGrey),
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < request.items.length; i++)
          _SupplyItemTile(index: i + 1, item: request.items[i]),
        const SizedBox(height: 10),
        GrnFinancialBreakdownCard(request: request),
      ],
    );
  }
}

class _SupplyItemTile extends StatelessWidget {
  const _SupplyItemTile({required this.index, required this.item});

  final int index;
  final PurchaseRequestItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$index',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.materialDescription,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    if (item.materialCode != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.materialCode!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.workOrderChipBackground,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.type.labelKey.tr,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          if (item.remarks.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              item.remarks,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.headingBlueGrey,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: 'pr_quantity'.tr,
                  value: item.quantity.toStringAsFixed(
                    item.quantity.truncateToDouble() == item.quantity ? 0 : 2,
                  ),
                ),
              ),
              Expanded(
                child: _Stat(
                  label: 'pr_unit_price'.tr,
                  value: item.unitPrice.toStringAsFixed(2),
                ),
              ),
              Expanded(
                child: _Stat(
                  label: 'pr_total'.tr,
                  value: item.total.toStringAsFixed(2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.labelGrey),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}
