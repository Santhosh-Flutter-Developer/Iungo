import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/features/work_order/presentation/controllers/work_order_detail_controller.dart';
import 'package:iungo/features/work_order/presentation/pages/work_order_attachment_viewer_page.dart';
import 'package:iungo/features/work_order/presentation/widgets/work_order_attachment_card.dart';

class DetailAttachmentsTab extends GetView<WorkOrderDetailController> {
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
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          itemCount: attachments.length,
          itemBuilder: (context, index) {
            final attachment = attachments[index];
            return WorkOrderAttachmentCard(
              attachment: attachment,
              onView: () => Get.to(
                () => WorkOrderAttachmentViewerPage(attachment: attachment),
              ),
            );
          },
        ),
      );
    });
  }
}
