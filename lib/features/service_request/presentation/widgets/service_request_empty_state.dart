import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';

/// "No Results Found" placeholder shown when the filter/search matches
/// nothing — matches the reference video's empty state.
class ServiceRequestEmptyState extends StatelessWidget {
  const ServiceRequestEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.note_add_outlined,
              size: 96,
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 20),
            Text(
              'no_results_found'.tr,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'try_adjusting_filters'.tr,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
