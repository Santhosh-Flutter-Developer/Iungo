import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/features/service_request/domain/entities/service_request_status.dart';

/// The pill-shaped, colored status label on the top-right of each list card.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final ServiceRequestStatus status;

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
          fontWeight: FontWeight.w700,
          color: AppColors.white,
        ),
      ),
    );
  }
}

/// Small grey pill on the top-left of each card ("# 674").
class TicketIdChip extends StatelessWidget {
  const TicketIdChip({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(
        '# $id',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      ),
    );
  }
}
