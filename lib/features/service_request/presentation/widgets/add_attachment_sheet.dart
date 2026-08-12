import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';

class AddAttachmentSheet extends StatelessWidget {
  const AddAttachmentSheet({
    super.key,
    required this.onCameraTap,
    required this.onGalleryTap,
  });

  final VoidCallback onCameraTap;
  final VoidCallback onGalleryTap;

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onCameraTap,
    required VoidCallback onGalleryTap,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => AddAttachmentSheet(
        onCameraTap: onCameraTap,
        onGalleryTap: onGalleryTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'add_attachment'.tr,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            _OptionRow(
              icon: Icons.camera_alt_outlined,
              label: 'open_camera'.tr,
              onTap: () {
                Get.back();
                onCameraTap();
              },
            ),
            _OptionRow(
              icon: Icons.folder_outlined,
              label: 'open_gallery'.tr,
              onTap: () {
                Get.back();
                onGalleryTap();
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: () => Get.back(),
                child: Text(
                  'cancel'.tr,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        // Reference design keeps the icon pinned to the right edge in both
        // locales, so layout direction is fixed here rather than inherited.
        child: Row(
          textDirection: TextDirection.ltr,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textDark,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Icon(icon, size: 22, color: AppColors.textDark),
          ],
        ),
      ),
    );
  }
}
