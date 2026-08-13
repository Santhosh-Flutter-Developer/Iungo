import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iungo/core/utils/app_date_format.dart';
import 'package:iungo/core/widgets/app_snackbar.dart';
import 'package:iungo/features/service_request/domain/entities/service_request.dart';
import 'package:iungo/features/service_request/domain/entities/service_request_attachment.dart';
import 'package:iungo/features/service_request/domain/entities/service_request_comment.dart';

/// Holds the tab state for one Detail View screen. Nothing here talks to
/// a real API — comments/attachments are seeded from [request] and any
/// additions only live for the lifetime of this screen, matching the
/// rest of the app's static/UI-only data approach.
class ServiceRequestDetailController extends GetxController {
  ServiceRequestDetailController(this.request);

  final ServiceRequest request;

  late final RxList<ServiceRequestComment> comments =
      RxList<ServiceRequestComment>(request.comments);
  late final RxList<ServiceRequestAttachment> attachments =
      RxList<ServiceRequestAttachment>(request.attachments);

  final RxBool isPickingAttachment = false.obs;
  final ImagePicker _imagePicker = ImagePicker();

  void addComment(String message) {
    final text = message.trim();
    if (text.isEmpty) return;
    comments.add(
      ServiceRequestComment(
        author: 'You',
        dateLabel: 'today'.tr,
        message: text,
      ),
    );
  }

  Future<void> pickAttachmentFromCamera() async {
    if (isPickingAttachment.value) return;
    isPickingAttachment.value = true;
    try {
      final photo = await _imagePicker.pickImage(source: ImageSource.camera);
      if (photo == null) return;
      final bytes = kIsWeb ? await photo.readAsBytes() : null;
      _addAttachment(
        name: photo.name,
        path: kIsWeb ? null : photo.path,
        bytes: bytes,
      );
    } catch (_) {
      AppSnackbar.showError('attachment_camera_failed'.tr);
    } finally {
      isPickingAttachment.value = false;
    }
  }

  Future<void> pickAttachmentFromFiles() async {
    if (isPickingAttachment.value) return;
    isPickingAttachment.value = true;
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        withData: kIsWeb,
      );
      if (result == null) return;
      for (final file in result.files) {
        _addAttachment(
          name: file.name,
          path: kIsWeb ? null : file.path,
          bytes: kIsWeb ? file.bytes : null,
          sizeBytes: file.size,
        );
      }
    } catch (_) {
      AppSnackbar.showError('attachment_pick_failed'.tr);
    } finally {
      isPickingAttachment.value = false;
    }
  }

  void _addAttachment({
    required String name,
    String? path,
    Uint8List? bytes,
    int? sizeBytes,
  }) {
    final dotIndex = name.lastIndexOf('.');
    final extension =
        dotIndex == -1 ? '' : name.substring(dotIndex + 1).toUpperCase();
    final sizeLabel = sizeBytes != null
        ? '${(sizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB'
        : '--';
    attachments.add(
      ServiceRequestAttachment(
        name: name,
        extension: extension,
        sizeLabel: sizeLabel,
        dateLabel: AppDateFormat.mediumDate(DateTime.now()),
        path: path,
        bytes: bytes,
      ),
    );
  }

  void removeAttachment(ServiceRequestAttachment attachment) {
    attachments.remove(attachment);
  }
}
