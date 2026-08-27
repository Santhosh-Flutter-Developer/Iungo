import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/core/utils/app_date_format.dart';
import 'package:iungo/features/service_request/domain/entities/service_request_priority.dart';
import 'package:iungo/features/service_request/presentation/widgets/status_badge.dart'
    show TicketIdChip;
import 'package:iungo/features/work_order/domain/entities/work_order.dart';
import 'package:iungo/features/work_order/domain/entities/work_order_maintenance_type.dart';
import 'package:iungo/features/work_order/domain/entities/work_order_status.dart';
import 'package:iungo/features/work_order/presentation/bindings/work_order_detail_binding.dart';
import 'package:iungo/features/work_order/presentation/pages/work_order_detail_page.dart';
import 'package:iungo/features/work_order/presentation/widgets/work_order_status_badge.dart';

/// One card in the "My Work Orders" list. Tapping the card opens the
/// Detail View.
class WorkOrderCard extends StatelessWidget {
  const WorkOrderCard({super.key, required this.workOrder});

  final WorkOrder workOrder;

  bool get _isDueTodayOrOverdue {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(
      workOrder.dueDate.year,
      workOrder.dueDate.month,
      workOrder.dueDate.day,
    );
    return !due.isAfter(today);
  }

  @override
  Widget build(BuildContext context) {
    final status = workOrder.status;

    return InkWell(
      onTap: () => Get.to(
        () => const WorkOrderDetailPage(),
        binding: WorkOrderDetailBinding(workOrder),
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
            if (status.isLongLabel) ...[
              TicketIdChip(id: workOrder.serialNumber),
              const SizedBox(height: 10),
              WorkOrderStatusBanner(status: status),
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TicketIdChip(id: workOrder.serialNumber),
                  const Spacer(),
                  WorkOrderStatusBadge(status: status),
                ],
              ),
            const SizedBox(height: 14),
            Text(
              workOrder.title,
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
              workOrder.description.trim().isEmpty
                  ? 'no_description_provided'.tr
                  : workOrder.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 14),
            if (workOrder.assignedTechnician != null) ...[
              _PillChip(
                icon: Icons.person_outline,
                label:
                    '${'assigned_technician'.tr}: ${workOrder.assignedTechnician}',
                background: AppColors.workOrderChipBackground,
                foreground: AppColors.primary,
              ),
              const SizedBox(height: 10),
            ],
            _DueChip(
              label: _isDueTodayOrOverdue
                  ? '${'due'.tr}: ${'today'.tr}'
                  : '${'due'.tr}: ${AppDateFormat.mediumDate(workOrder.dueDate)}',
              urgent: _isDueTodayOrOverdue,
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
                          label: workOrder.requester,
                        ),
                      ),
                      Expanded(
                        child: _InfoItem(
                          icon: Icons.location_on_outlined,
                          label: workOrder.site,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoItem(
                          icon: Icons.access_time,
                          label: workOrder.priority.labelKey.tr,
                        ),
                      ),
                      Expanded(
                        child: _InfoItem(
                          icon: Icons.change_history,
                          label: workOrder.discipline.isEmpty
                              ? '--'
                              : workOrder.discipline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _InfoItem(
                    icon: Icons.build_outlined,
                    label: workOrder.maintenanceType.labelKey.tr,
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

class _DueChip extends StatelessWidget {
  const _DueChip({required this.label, required this.urgent});

  final String label;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final background = urgent
        ? AppColors.workOrderDueUrgentBackground
        : AppColors.workOrderChipBackground;
    final foreground =
        urgent ? AppColors.workOrderDueUrgentText : AppColors.primary;
    return _PillChip(
      icon: Icons.calendar_today_outlined,
      label: label,
      background: background,
      foreground: foreground,
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