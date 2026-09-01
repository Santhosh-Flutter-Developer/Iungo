import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/core/utils/app_date_format.dart';
import 'package:iungo/features/service_request/domain/entities/service_request_priority.dart';
import 'package:iungo/features/service_request/presentation/widgets/detail_info_tile.dart';
import 'package:iungo/features/work_order/domain/entities/work_order.dart';
import 'package:iungo/features/work_order/domain/entities/work_order_maintenance_type.dart';
import 'package:iungo/features/work_order/presentation/controllers/work_order_detail_controller.dart';
import 'package:iungo/features/work_order/presentation/widgets/work_order_status_badge.dart';

class DetailOverviewTab extends StatelessWidget {
  const DetailOverviewTab({
    super.key,
    required this.workOrder,
    required this.controller,
  });

  final WorkOrder workOrder;
  final WorkOrderDetailController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        Row(
          children: [
            WorkOrderStatusBadge(status: workOrder.status),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 16, color: AppColors.headingBlueGrey),
            const SizedBox(width: 8),
            Text(
              AppDateFormat.mediumDateWithTime(workOrder.raisedAt),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.headingBlueGrey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          workOrder.title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Text(
              '# ${workOrder.serialNumber}',
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.headingBlueGrey,
              ),
            ),
            // No due date from the API — omit the countdown pill
            // entirely rather than showing a fabricated countdown.
            Obx(() {
              if (controller.workOrder.value.dueDate == null) {
                return const SizedBox.shrink();
              }
              return Row(
                children: [
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.workOrderDueUrgentBackground,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${'due'.tr}: ${controller.dueCountdown.value}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.workOrderDueUrgentText,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Icon(Icons.person_outline,
                size: 18, color: AppColors.headingBlueGrey),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                workOrder.requester,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.headingBlueGrey,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          workOrder.description.trim().isEmpty
              ? 'no_description_provided'.tr
              : workOrder.description,
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
        Text(
          'assigned_technician'.tr,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.labelGrey,
          ),
        ),
        const SizedBox(height: 14),
        if (workOrder.assignedTechnician == null)
          Text(
            'not_assigned'.tr,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
          )
        else
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary,
                child: Text(
                  _initials(workOrder.assignedTechnician!),
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  workOrder.assignedTechnician!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(height: 24),
        const Divider(color: AppColors.divider, height: 1),
        const SizedBox(height: 20),
        Text(
          'other_information'.tr,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.labelGrey,
          ),
        ),
        const SizedBox(height: 18),
        DetailInfoTile(
          icon: Icons.home_outlined,
          label: 'site_location'.tr,
          value: workOrder.site,
        ),
        DetailInfoTile(
          icon: Icons.build_outlined,
          label: 'maintenance_type'.tr,
          value: workOrder.maintenanceType?.labelKey.tr ?? '--',
        ),
        DetailInfoTile(
          icon: Icons.trending_up,
          label: 'priority'.tr,
          value: workOrder.priority?.labelKey.tr ?? '--',
        ),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}