import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_colors.dart';

/// One tappable row inside the "Create Service Request" bottom sheet.
class _RequestSheetOption {
  const _RequestSheetOption({
    required this.icon,
    required this.labelKey,
    required this.onTap,
  });

  final IconData icon;
  final String labelKey;
  final VoidCallback onTap;
}

/// Bottom sheet shown when the user taps "Create Service Request" on the
/// dashboard. Static UI only — no navigation / API wiring.
class CreateServiceRequestSheet extends StatelessWidget {
  const CreateServiceRequestSheet({super.key});

  static Future<void> show() {
    return Get.bottomSheet(
      const CreateServiceRequestSheet(),
      backgroundColor: AppColors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final options = <_RequestSheetOption>[
      _RequestSheetOption(
        icon: Icons.note_add_outlined,
        labelKey: 'service_request',
        onTap: () {},
      ),
      _RequestSheetOption(
        icon: Icons.ramen_dining_outlined,
        labelKey: 'catering_request',
        onTap: () {},
      ),
      _RequestSheetOption(
        icon: Icons.shopping_bag_outlined,
        labelKey: 'laundry_request',
        onTap: () {},
      ),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'create_service_request'.tr,
                textAlign: TextAlign.start,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ),
            const SizedBox(height: 12),
            for (final option in options)
              _SheetOptionRow(
                icon: option.icon,
                label: option.labelKey.tr,
                onTap: option.onTap,
              ),
          ],
        ),
      ),
    );
  }
}

class _SheetOptionRow extends StatelessWidget {
  const _SheetOptionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 24, color: AppColors.inputIcon),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isRtl ? Icons.chevron_left : Icons.chevron_right,
              size: 22,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}