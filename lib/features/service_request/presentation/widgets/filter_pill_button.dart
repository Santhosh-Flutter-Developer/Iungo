import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';

/// The rounded "▽ Filter" button shown top-right above the list.
class FilterPillButton extends StatelessWidget {
  const FilterPillButton({
    super.key,
    required this.onTap,
    this.isActive = false,
  });

  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.divider,
            width: isActive ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_alt_outlined,
                size: 18, color: AppColors.headingBlueGrey),
            const SizedBox(width: 6),
            Text(
              'filter'.tr,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.headingBlueGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
