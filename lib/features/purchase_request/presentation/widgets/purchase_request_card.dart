import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/core/utils/app_date_format.dart';
import 'package:iungo/features/purchase_request/domain/entities/purchase_request.dart';
import 'package:iungo/features/purchase_request/presentation/widgets/purchase_request_status_badge.dart';

/// One card in the PR Dashboard list. Tapping it opens the Detail View.
/// Mirrors `InventoryRequestCard`'s composition (id/status row, pill
/// chips, light info-grid box) with Purchase Request's own fields:
/// Number, Contract, Total, Next Approval, Stage.
class PurchaseRequestCard extends StatelessWidget {
  const PurchaseRequestCard({super.key, required this.request, this.onTap});

  final PurchaseRequest request;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.prNumber,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                PurchaseRequestStatusBadge(status: request.status),
              ],
            ),
            const SizedBox(height: 14),
            _PillChip(
              icon: Icons.description_outlined,
              label: '${'pr_contract'.tr}: ${request.contract}',
            ),
            const SizedBox(height: 10),
            _PillChip(
              icon: Icons.calendar_today_outlined,
              label: '${'created'.tr}: '
                  '${AppDateFormat.mediumDate(request.requestDate)}',
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.workOrderInfoGridBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoItem(
                    icon: Icons.payments_outlined,
                    label: '${'pr_total'.tr}: '
                        '${request.totalAmount.toStringAsFixed(2)} SAR',
                  ),
                  const SizedBox(height: 10),
                  _InfoItem(
                    icon: Icons.person_outline,
                    label: '${'pr_next_approval'.tr}: '
                        '${request.nextApprovalName ?? '--'}',
                  ),
                  const SizedBox(height: 10),
                  _InfoItem(
                    icon: Icons.timeline_outlined,
                    label: '${'pr_stage'.tr}: '
                        '${request.currentStage}/${request.totalStages}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PillChip extends StatelessWidget {
  const _PillChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.workOrderChipBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }
}
