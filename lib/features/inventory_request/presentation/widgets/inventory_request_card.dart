import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/core/utils/app_date_format.dart';
import 'package:iungo/features/inventory_request/domain/entities/inventory_request.dart';
import 'package:iungo/features/inventory_request/domain/entities/inventory_reservation_status.dart';
import 'package:iungo/features/inventory_request/presentation/bindings/inventory_request_detail_binding.dart';
import 'package:iungo/features/inventory_request/presentation/pages/inventory_request_detail_page.dart';
import 'package:iungo/features/inventory_request/presentation/widgets/inventory_request_status_badge.dart';
import 'package:iungo/features/service_request/presentation/widgets/status_badge.dart'
    show TicketIdChip;

/// One card in the "Awaiting Client Approval" list. Tapping the card
/// opens the Detail View. Deliberately mirrors [WorkOrderCard]'s
/// composition, spacing, and colors — the id chip / status badge row,
/// title, a pill chip, then a light info-grid box — just with Inventory
/// Request's own fields in place of Work Order's.
class InventoryRequestCard extends StatelessWidget {
  const InventoryRequestCard({super.key, required this.request, this.onTap});

  final InventoryRequest request;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ??
          () => Get.to(
                () => const InventoryRequestDetailPage(),
                binding: InventoryRequestDetailBinding(request),
              ),
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
                TicketIdChip(id: request.id),
                const Spacer(),
                InventoryRequestStatusBadge(status: request.status),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              request.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              request.description.trim().isEmpty
                  ? 'no_description_provided'.tr
                  : request.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 14),
            _PillChip(
              icon: Icons.build_outlined,
              label: '${'work_order'.tr}: ${request.workOrderTitle}',
              background: AppColors.workOrderChipBackground,
              foreground: AppColors.primary,
            ),
            const SizedBox(height: 10),
            _PillChip(
              icon: Icons.calendar_today_outlined,
              label: '${'created'.tr}: '
                  '${AppDateFormat.mediumDate(request.createdTime)}',
              background: AppColors.workOrderChipBackground,
              foreground: AppColors.primary,
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
                  Row(
                    children: [
                      Expanded(
                        child: _InfoItem(
                          icon: Icons.person_outline,
                          label: '${'requested_for'.tr}: ${request.requestedFor}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoItem(
                          icon: Icons.assignment_ind_outlined,
                          label: '${'requested_by'.tr}: ${request.requestedBy}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoItem(
                          icon: Icons.fact_check_outlined,
                          label: '${'reservation_status'.tr}: '
                              '${request.reservationStatus.labelKey.tr}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoItem(
                          icon: Icons.category_outlined,
                          label: '${'service_line'.tr}: ${request.serviceLine}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoItem(
                          icon: Icons.edit_note_outlined,
                          label: '${'created_by'.tr}: ${request.createdBy}',
                        ),
                      ),
                    ],
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
  const _PillChip({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: foreground,
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Flexible(
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
