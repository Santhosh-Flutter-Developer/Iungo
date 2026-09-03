import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/core/constants/app_urls.dart';
import 'package:iungo/core/widgets/attachment_preview_dialog.dart';
import 'package:iungo/features/service_request/domain/entities/service_request_attachment.dart';
import 'package:iungo/features/service_request/presentation/controllers/service_request_detail_controller.dart';
import 'package:iungo/features/service_request/presentation/widgets/attachment_card.dart';

class DetailAttachmentsTab extends GetView<ServiceRequestDetailController> {
  const DetailAttachmentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingAttachments.value) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      }

      if (controller.attachmentsError.value.isNotEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  controller.attachmentsError.value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, color: AppColors.textDark),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.retryAttachments,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                  ),
                  child: Text('retry'.tr),
                ),
              ],
            ),
          ),
        );
      }

      final attachments = controller.attachments;
      if (attachments.isEmpty) {
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: controller.retryAttachments,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 120),
            children: [
              Text(
                'no_attachments_hint'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: AppColors.textDark),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: controller.retryAttachments,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          itemCount: attachments.length,
          itemBuilder: (context, index) {
            final attachment = attachments[index];
            return Obx(() {
              // Always read deletingAttachmentIds (even when id is null,
              // e.g. an in-flight upload placeholder) so Obx has an
              // observable to subscribe to. Short-circuiting past it with
              // `attachment.id != null && ...` skips the read entirely and
              // trips GetX's "improper use of Obx" error.
              final isDeleting =
                  controller.deletingAttachmentIds.contains(attachment.id);
              return AttachmentCard(
                attachment: attachment,
                isDeleting: isDeleting,
                onView: () => _showPreview(context, attachment),
                onDelete: () => controller.removeAttachment(attachment),
              );
            });
          },
        ),
      );
    });
  }

  void _showPreview(BuildContext context, ServiceRequestAttachment attachment) {
    showAttachmentPreview(
      context,
      AttachmentPreviewData(
        name: attachment.name,
        extension: attachment.extension,
        contentType: attachment.contentType,
        previewUrl: attachment.previewUrl == null
            ? null
            : AppUrls.resolve(attachment.previewUrl!),
        downloadUrl: attachment.downloadUrl == null
            ? null
            : AppUrls.resolve(attachment.downloadUrl!),
        bytes: attachment.bytes,
        localPath: attachment.path,
        authHeaders: attachmentAuthHeaders(),
      ),
    );
  }
}
