import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/features/work_order/domain/entities/work_order_status.dart';

/// The pill-shaped, colored status label — shown at the top-right of a
/// list card (short labels) or inline on the Detail View's Overview tab.
class WorkOrderStatusBadge extends StatelessWidget {
  const WorkOrderStatusBadge({super.key, required this.status});

  final WorkOrderStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: status.color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.labelKey.tr,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
      ),
    );
  }
}

/// Full-width banner variant used on the list card (below the id chip)
/// for the handful of long status labels that don't fit next to it —
/// e.g. "Awaiting Closure Approval from Client".
class WorkOrderStatusBanner extends StatelessWidget {
  const WorkOrderStatusBanner({super.key, required this.status});

  final WorkOrderStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: status.color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.labelKey.tr,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
      ),
    );
  }
}