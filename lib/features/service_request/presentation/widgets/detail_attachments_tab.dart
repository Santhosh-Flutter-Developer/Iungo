import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/core/services/session_service.dart';
import 'package:iungo/features/service_request/domain/entities/service_request_attachment.dart';
import 'package:iungo/features/service_request/presentation/controllers/service_request_detail_controller.dart';
import 'package:iungo/features/service_request/presentation/widgets/attachment_card.dart';

class DetailAttachmentsTab extends GetView<ServiceRequestDetailController> {
  const DetailAttachmentsTab({super.key});

  /// Files are served from the portal host, not `/client` — previewUrl
  /// / downloadUrl come back host-relative (Portal API Guide §4.3).
  static const _portalHost = 'https://citgroup.facilioclients.com';

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
    Widget preview;
    if (attachment.bytes != null) {
      preview = Image.memory(attachment.bytes!, fit: BoxFit.contain);
    } else if (!kIsWeb && attachment.path != null) {
      preview = Image.file(File(attachment.path!), fit: BoxFit.contain);
    } else if ((attachment.contentType ?? '').startsWith('image/') &&
        attachment.previewUrl != null) {
      preview = _RemoteImagePreview(url: _resolve(attachment.previewUrl!));
    } else {
      preview = Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.insert_drive_file_outlined,
              size: 40,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            Text(
              attachment.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            Text(
              'preview_not_available'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.headingBlueGrey),
            ),
          ],
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

  String _resolve(String hostRelativeUrl) {
    if (hostRelativeUrl.startsWith('http://') ||
        hostRelativeUrl.startsWith('https://')) {
      return hostRelativeUrl;
    }
    return '$_portalHost$hostRelativeUrl';
  }
}

/// An authenticated preview image — [Image.network] alone can't attach
/// the Bearer token these file endpoints require (Portal API Guide §4.3),
/// so this sends `headers` explicitly.
class _RemoteImagePreview extends StatelessWidget {
  const _RemoteImagePreview({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final token = Get.find<SessionService>().token.value;
    return Image.network(
      url,
      fit: BoxFit.contain,
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      },
      errorBuilder: (context, error, stackTrace) => Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'preview_not_available'.tr,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: AppColors.textDark),
        ),
      ),
    );
  }
}
