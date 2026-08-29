import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/core/services/session_service.dart';
import 'package:iungo/features/work_order/domain/entities/work_order_attachment.dart';

/// Full-screen attachment viewer opened from the Detail View's
/// Attachments tab — black background, dark app bar with a close icon
/// and the (ellipsized) filename, pinch-zoomable image.
class WorkOrderAttachmentViewerPage extends StatelessWidget {
  const WorkOrderAttachmentViewerPage({super.key, required this.attachment});

  final WorkOrderAttachment attachment;

  /// Files are served from the portal host, not `/client` — previewUrl
  /// comes back host-relative.
  static const _portalHost = 'https://citgroup.facilioclients.com';

  @override
  Widget build(BuildContext context) {
    final isImage = (attachment.contentType ?? '').startsWith('image/');
    final previewUrl = attachment.previewUrl;

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
          child: (isImage && previewUrl != null)
              ? _RemoteImagePreview(url: _resolve(previewUrl))
              : const _PlaceholderPreview(),
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
/// the Bearer token these file endpoints require, so this sends
/// `headers` explicitly.
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
          child: CircularProgressIndicator(color: AppColors.white),
        );
      },
      errorBuilder: (context, error, stackTrace) => const _PlaceholderPreview(),
    );
  }
}

class _PlaceholderPreview extends StatelessWidget {
  const _PlaceholderPreview();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.insert_drive_file_outlined,
            size: 96, color: AppColors.white),
        const SizedBox(height: 16),
        Text(
          'preview_not_available'.tr,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, color: AppColors.white),
        ),
      ],
    );
  }
}
