import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iungo/core/utils/app_date_format.dart';
import 'package:iungo/core/widgets/app_snackbar.dart';
import 'package:iungo/features/service_request/data/datasources/service_request_exceptions.dart';
import 'package:iungo/features/service_request/data/service_request_repository.dart';
import 'package:iungo/features/service_request/domain/entities/service_request.dart';
import 'package:iungo/features/service_request/domain/entities/service_request_attachment.dart';
import 'package:iungo/features/service_request/domain/entities/service_request_comment.dart';

/// Holds the tab state for one Detail View screen.
///
/// [ticket] starts out as whatever summary card was tapped (from the
/// list), then a fresh fetch by id replaces it with the richer Detail
/// View record (description, classification, requester, assigned
/// technician, etc. — fields the list API doesn't return). Comments and
/// attachments have no confirmed API yet, so they stay seeded from
/// [ticket] and any additions only live for the lifetime of this screen,
/// matching the rest of the app's static/UI-only data approach there.
class ServiceRequestDetailController extends GetxController {
  ServiceRequestDetailController(this._repository, ServiceRequest initial)
      : ticket = initial.obs,
        comments = RxList<ServiceRequestComment>(initial.comments),
        attachments = RxList<ServiceRequestAttachment>(initial.attachments);

  final ServiceRequestRepository _repository;

  /// Convenience accessor — most callers only ever want the current
  /// ticket, not the fact that it's reactive.
  ServiceRequest get request => ticket.value;

  final Rx<ServiceRequest> ticket;
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;

  final RxList<ServiceRequestComment> comments;
  final RxList<ServiceRequestAttachment> attachments;

  final RxBool isPickingAttachment = false.obs;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final fresh = await _repository.fetchServiceRequestDetail(ticket.value.id);
      // Comments/attachments aren't part of the detail API response, so
      // keep whatever this screen already had (seeded from the summary
      // card, plus anything the person has added since).
      ticket.value = fresh;
    } on ServiceRequestException catch (e) {
      errorMessage.value =
          e.message.trim().isNotEmpty ? e.message : 'something_went_wrong'.tr;
    } catch (_) {
      errorMessage.value = 'something_went_wrong'.tr;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> retry() => _loadDetail();

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