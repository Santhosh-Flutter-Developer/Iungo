import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';

/// The three big status tiles at the top of the PR Dashboard — doubles
/// as the tab selector (tapping one switches the list below). Matches
/// the reference video: the selected tile is solid green, the other two
/// are light grey, each showing a count and a label.
class PrStatusTabs extends StatelessWidget {
  const PrStatusTabs({
    super.key,
    required this.pendingLabel,
    required this.pendingCount,
    required this.completedCount,
    required this.rejectedCount,
    required this.selectedIndex,
    required this.onSelect,
  });

  final String pendingLabel;
  final int pendingCount;
  final int completedCount;
  final int rejectedCount;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatusTile(
            count: pendingCount,
            label: pendingLabel,
            selected: selectedIndex == 0,
            onTap: () => onSelect(0),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatusTile(
            count: completedCount,
            label: 'completed'.tr,
            selected: selectedIndex == 1,
            onTap: () => onSelect(1),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatusTile(
            count: rejectedCount,
            label: 'pr_status_rejected'.tr,
            selected: selectedIndex == 2,
            onTap: () => onSelect(2),
          ),
        ),
      ],
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.count,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final int count;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? AppColors.white : AppColors.textDark;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.prStatusGreen
              : AppColors.prTileInactiveBackground,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: foreground,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
