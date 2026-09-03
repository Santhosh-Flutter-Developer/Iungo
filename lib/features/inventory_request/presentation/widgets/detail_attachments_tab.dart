import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/core/constants/app_urls.dart';
import 'package:iungo/core/widgets/attachment_preview_dialog.dart';
import 'package:iungo/features/inventory_request/presentation/controllers/inventory_request_detail_controller.dart';
import 'package:iungo/features/work_order/domain/entities/work_order_attachment.dart';
import 'package:iungo/features/work_order/presentation/widgets/work_order_attachment_card.dart';

/// Renders the live "Attachments" for an Inventory Request —
/// loading/error/empty/list states driven by
/// [InventoryRequestDetailController]. Mirrors [DetailAttachmentsTab]
/// (Work Order) exactly, reusing [WorkOrderAttachmentCard] since both
/// features share the same attachment shape. "View" opens the same
/// shared popup-overlay preview as every other Detail View.
class InventoryRequestDetailAttachmentsTab
    extends GetView<InventoryRequestDetailController> {
  const InventoryRequestDetailAttachmentsTab({super.key});

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
                'no_attachments_available'.tr,
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
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          itemCount: attachments.length,
          itemBuilder: (context, index) {
            final attachment = attachments[index];
            return WorkOrderAttachmentCard(
              attachment: attachment,
              onView: () => _showPreview(context, attachment),
            );
          },
        ),
      );
    });
  }

  void _showPreview(BuildContext context, WorkOrderAttachment attachment) {
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
        authHeaders: attachmentAuthHeaders(),
      ),
    );
  }
}
