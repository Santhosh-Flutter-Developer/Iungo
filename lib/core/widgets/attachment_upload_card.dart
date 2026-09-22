import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';

/// A "browse files to add an attachment" card — an approver-only upload
/// affordance shown above a read-only attachment list (e.g. the GRN
/// Detail View's "GRN" tab, the Invoice Detail View's "Invoice" tab).
///
/// Mirrors the reference web dashboard's drag-and-drop area, minus the
/// drag target itself (there's nothing to drag from on a phone): an
/// icon, a short hint, and a "Browse Files" button that opens the
/// device's file picker.
class AttachmentUploadCard extends StatelessWidget {
  const AttachmentUploadCard({
    super.key,
    required this.onBrowse,
    this.isUploading = false,
  });

  final VoidCallback onBrowse;
  final bool isUploading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_upload_outlined,
            size: 32,
            color: AppColors.headingBlueGrey,
          ),
          const SizedBox(height: 10),
          Text(
            'attachment_upload_hint'.tr,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: isUploading ? null : onBrowse,
            icon: isUploading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : const Icon(Icons.folder_open_outlined, size: 18),
            label: Text(
              isUploading
                  ? 'attachment_uploading'.tr
                  : 'attachment_browse_files'.tr,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
