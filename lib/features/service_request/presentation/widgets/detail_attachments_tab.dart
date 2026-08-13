import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/features/service_request/domain/entities/service_request_attachment.dart';
import 'package:iungo/features/service_request/presentation/controllers/service_request_detail_controller.dart';
import 'package:iungo/features/service_request/presentation/widgets/attachment_card.dart';

class DetailAttachmentsTab extends GetView<ServiceRequestDetailController> {
  const DetailAttachmentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final attachments = controller.attachments;
      if (attachments.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'no_attachments_hint'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textDark,
              ),
            ),
          ),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        itemCount: attachments.length,
        itemBuilder: (context, index) {
          final attachment = attachments[index];
          return AttachmentCard(
            attachment: attachment,
            onView: () => _showPreview(context, attachment),
            onDelete: () => controller.removeAttachment(attachment),
          );
        },
      );
    });
  }

  void _showPreview(BuildContext context, ServiceRequestAttachment attachment) {
    Widget preview;
    if (attachment.bytes != null) {
      preview = Image.memory(attachment.bytes!, fit: BoxFit.contain);
    } else if (!kIsWeb && attachment.path != null) {
      preview = Image.file(File(attachment.path!), fit: BoxFit.contain);
    } else {
      preview = Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          attachment.name,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, color: AppColors.textDark),
        ),
      );
    }

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(color: AppColors.white, child: preview),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.white),
              onPressed: () => Get.back(),
            ),
          ],
        ),
      ),
    );
  }
}
