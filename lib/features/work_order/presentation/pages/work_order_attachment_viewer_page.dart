import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/features/work_order/domain/entities/work_order_attachment.dart';

/// Full-screen attachment viewer opened from the Detail View's
/// Attachments tab — black background, dark app bar with a close icon
/// and the (ellipsized) filename, pinch-zoomable image.
class WorkOrderAttachmentViewerPage extends StatelessWidget {
  const WorkOrderAttachmentViewerPage({super.key, required this.attachment});

  final WorkOrderAttachment attachment;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.white),
          onPressed: () => Get.back(),
        ),
        title: Text(
          attachment.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: attachment.assetPath != null
              ? Image.asset(
                  attachment.assetPath!,
                  fit: BoxFit.contain,
                  // loadingBuilder: (context, child, frame) {
                  //   if (frame == null) {
                  //     return const SizedBox(
                  //       width: 32,
                  //       height: 32,
                  //       child: CircularProgressIndicator(
                  //         strokeWidth: 2.5,
                  //         color: AppColors.white,
                  //       ),
                  //     );
                  //   }
                  //   return child;
                  // },
                )
              : _PlaceholderPreview(attachment: attachment),
        ),
      ),
    );
  }
}

class _PlaceholderPreview extends StatelessWidget {
  const _PlaceholderPreview({required this.attachment});

  final WorkOrderAttachment attachment;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.insert_drive_file_outlined,
            size: 96, color: AppColors.white),
        const SizedBox(height: 16),
        Text(
          attachment.name,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, color: AppColors.white),
        ),
      ],
    );
  }
}