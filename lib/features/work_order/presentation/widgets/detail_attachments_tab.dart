import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/features/work_order/domain/entities/work_order_attachment.dart';
import 'package:iungo/features/work_order/presentation/pages/work_order_attachment_viewer_page.dart';
import 'package:iungo/features/work_order/presentation/widgets/work_order_attachment_card.dart';

class DetailAttachmentsTab extends StatelessWidget {
  const DetailAttachmentsTab({super.key, required this.attachments});

  final List<WorkOrderAttachment> attachments;

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) {
      return Center(
        child: Text(
          'no_attachments_found'.tr,
          style: const TextStyle(fontSize: 16, color: AppColors.textMuted),
        ),
      );
    }

    return ListView.builder(
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
    );
  }
}