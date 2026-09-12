import 'package:flutter/material.dart';
import 'package:iungo/core/constants/app_colors.dart';

/// Shared "coming soon" body for the Purchase Request dashboard pages
/// (PR Dashboard / GRN Dashboard / Invoice Dashboard) until their real
/// UI is shared. Mirrors the empty-state layout used elsewhere in the
/// app (e.g. Notification's empty state / error state).
class PurchaseRequestPlaceholderBody extends StatelessWidget {
  const PurchaseRequestPlaceholderBody({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 96,
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 20),
            const Text(
              'Coming soon',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
