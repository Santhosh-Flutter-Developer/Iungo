import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/features/purchase_request/domain/entities/purchase_request_status.dart';

/// The pill-shaped, colored status label shown on the PR card and
/// Detail View — mirrors `InventoryRequestStatusBadge`'s styling.
class PurchaseRequestStatusBadge extends StatelessWidget {
  const PurchaseRequestStatusBadge({super.key, required this.status});

  final PurchaseRequestStatus status;

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
