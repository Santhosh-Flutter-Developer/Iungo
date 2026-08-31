import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';

/// The pill-shaped, colored **status** label — shown at the top-right of
/// a list card and inline on the Detail View's Overview tab. Reads the
/// request's raw `status` field (e.g. "Awaiting Client Approval",
/// "Fully Issued", "Rejected") rather than the line items' reservation
/// status, matching the reference admin panel's "Status" column. Falls
/// back to "Awaiting Client Approval" when the raw status is blank,
/// since every record on this screen belongs to that queue.
class InventoryRequestStatusBadge extends StatelessWidget {
  const InventoryRequestStatusBadge({super.key, required this.status});

  final String? status;

  String get _label {
    final trimmed = status?.trim() ?? '';
    return trimmed.isEmpty ? 'awaiting_client_approval'.tr : trimmed;
  }

  Color get _color {
    final normalized = (status ?? '').trim().toLowerCase();
    if (normalized.contains('fully issued')) return const Color(0xFF3D8B4E);
    if (normalized.contains('partially issued')) return const Color(0xFF3F6FA8);
    if (normalized.contains('rejected')) return const Color(0xFFB3261E);
    // Blank, "Awaiting Client Approval", or any other in-progress value.
    return const Color(0xFFC77A1E);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _label,
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
