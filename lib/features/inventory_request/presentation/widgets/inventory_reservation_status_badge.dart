import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/features/inventory_request/domain/entities/inventory_reservation_status.dart';

/// The pill-shaped, colored reservation-status label — shown at the
/// top-right of a list card and inline on the Detail View's Overview
/// tab. Styled identically to [WorkOrderStatusBadge].
class InventoryReservationStatusBadge extends StatelessWidget {
  const InventoryReservationStatusBadge({super.key, required this.status});

  final InventoryReservationStatus status;

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
