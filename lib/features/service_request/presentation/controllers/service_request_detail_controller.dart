import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iungo/core/widgets/app_snackbar.dart';
import 'package:iungo/features/service_request/data/datasources/service_request_exceptions.dart';
import 'package:iungo/features/service_request/data/service_request_repository.dart';
import 'package:iungo/features/service_request/domain/entities/attachment_file.dart';
import 'package:iungo/features/service_request/domain/entities/service_request.dart';
import 'package:iungo/features/service_request/domain/entities/service_request_attachment.dart';
import 'package:iungo/features/service_request/domain/entities/service_request_comment.dart';

/// Holds the tab state for one Detail View screen.
///
/// [ticket] starts out as whatever summary card was tapped (from the
/// list), then a fresh fetch by id replaces it with the richer Detail
/// View record (description, classification, requester, assigned
/// technician, etc. — fields the list API doesn't return).
///
/// Comments and Attachments are each backed by their own API call (Portal
/// API Guide §3/§4) with their own loading/error state, fetched in
/// parallel with the ticket detail on [onInit] so a slow overview fetch
/// doesn't block the other two tabs.
class ServiceRequestDetailController extends GetxController {
  ServiceRequestDetailController(this._repository, ServiceRequest initial)
      : ticket = initial.obs;

  final ServiceRequestRepository _repository;

  /// Convenience accessor — most callers only ever want the current
  /// ticket, not the fact that it's reactive.
  ServiceRequest get request => ticket.value;

  final Rx<ServiceRequest> ticket;
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;

  // ---- Comments --------------------------------------------------------

  final RxList<ServiceRequestComment> comments = <ServiceRequestComment>[].obs;
  final RxBool isLoadingComments = true.obs;
  final RxString commentsError = ''.obs;
  final RxBool isPostingComment = false.obs;

  // ---- Attachments -------------------------------------------------------

  final RxList<ServiceRequestAttachment> attachments =
      <ServiceRequestAttachment>[].obs;
  final RxBool isLoadingAttachments = true.obs;
  final RxString attachmentsError = ''.obs;
  final RxBool isPickingAttachment = false.obs;

  /// Ids of attachments currently mid-delete — lets the card show a
  /// per-item spinner and ignore a second tap instead of double-firing
  /// the delete call.
  final RxSet<int> deletingAttachmentIds = <int>{}.obs;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    _loadDetail();
    _loadComments();
    _loadAttachments();
  }

  Future<void> _loadDetail() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final fresh = await _repository.fetchServiceRequestDetail(ticket.value.id);
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

  // ---- Comments --------------------------------------------------------

  Future<void> _loadComments() async {
    isLoadingComments.value = true;
    commentsError.value = '';
    try {
      final fetched = await _repository.fetchComments(ticket.value.id);
      comments.assignAll(fetched);
    } on ServiceRequestException catch (e) {
      commentsError.value =
          e.message.trim().isNotEmpty ? e.message : 'something_went_wrong'.tr;
    } catch (_) {
      commentsError.value = 'something_went_wrong'.tr;
    } finally {
      isLoadingComments.value = false;
    }
  }

  Future<void> retryComments() => _loadComments();

  /// Posts [message] as a new comment. Returns whether it succeeded, so
  /// the Add Comment screen can stay open and show the error instead of
  /// closing on a failed post.
  Future<bool> addComment(String message) async {
    final text = message.trim();
    if (text.isEmpty) return false;
    if (isPostingComment.value) return false;

    isPostingComment.value = true;
    try {
      final posted = await _repository.addComment(ticket.value.id, text);
      comments.add(posted);
      return true;
    } on ServiceRequestException catch (e) {
      AppSnackbar.showError(
        e.message.trim().isNotEmpty ? e.message : 'something_went_wrong'.tr,
      );
      return false;
    } catch (_) {
      AppSnackbar.showError('something_went_wrong'.tr);
      return false;
    } finally {
      isPostingComment.value = false;
    }
  }

  // ---- Attachments -------------------------------------------------------

  Future<void> _loadAttachments() async {
    isLoadingAttachments.value = true;
    attachmentsError.value = '';
    try {
      final fetched = await _repository.fetchAttachments(ticket.value.id);
      attachments.assignAll(fetched);
    } on ServiceRequestException catch (e) {
      attachmentsError.value =
          e.message.trim().isNotEmpty ? e.message : 'something_went_wrong'.tr;
    } catch (_) {
      attachmentsError.value = 'something_went_wrong'.tr;
    } finally {
      isLoadingAttachments.value = false;
    }
  }

  Future<void> retryAttachments() => _loadAttachments();

  Future<void> pickAttachmentFromCamera() async {
    if (isPickingAttachment.value) return;
    isPickingAttachment.value = true;
    try {
      final photo = await _imagePicker.pickImage(source: ImageSource.camera);
      if (photo == null) return;
      final bytes = kIsWeb ? await photo.readAsBytes() : null;
      int? sizeBytes;
      try {
        sizeBytes = await photo.length();
      } catch (_) {
        // Best-effort — upload still proceeds without a client-side size
        // check; the server enforces the limit either way (§4.4).
      }
      await _uploadAttachments([
        AttachmentFile(
          name: photo.name,
          path: kIsWeb ? null : photo.path,
          bytes: bytes,
          sizeBytes: sizeBytes,
        ),
      ]);
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
      if (result == null || result.files.isEmpty) return;
      await _uploadAttachments([
        for (final file in result.files)
          AttachmentFile(
            name: file.name,
            path: kIsWeb ? null : file.path,
            bytes: kIsWeb ? file.bytes : null,
            sizeBytes: file.size,
          ),
      ]);
    } catch (_) {
      AppSnackbar.showError('attachment_pick_failed'.tr);
    } finally {
      isPickingAttachment.value = false;
    }
  }

  Future<void> _uploadAttachments(List<AttachmentFile> files) async {
    if (files.isEmpty) return;

    // Placeholder tiles so the person sees their pick immediately instead
    // of a silent pause while the multipart request is in flight.
    final placeholders = [
      for (final file in files)
        ServiceRequestAttachment(
          name: file.name,
          extension: _extensionOf(file.name),
          sizeLabel: '--',
          dateLabel: '',
          path: file.path,
          bytes: file.bytes,
          isUploading: true,
        ),
    ];
    attachments.addAll(placeholders);

    try {
      final uploaded = await _repository.uploadServiceRequestAttachments(
        ticket.value.id,
        files,
      );
      attachments.removeWhere((a) => placeholders.contains(a));
      attachments.addAll(uploaded);
    } on ServiceRequestException catch (e) {
      attachments.removeWhere((a) => placeholders.contains(a));
      AppSnackbar.showError(
        e.message.trim().isNotEmpty ? e.message : 'something_went_wrong'.tr,
      );
    } catch (_) {
      attachments.removeWhere((a) => placeholders.contains(a));
      AppSnackbar.showError('something_went_wrong'.tr);
    }
  }

  Future<void> removeAttachment(ServiceRequestAttachment attachment) async {
    final id = attachment.id;
    if (id == null || deletingAttachmentIds.contains(id)) return;

    deletingAttachmentIds.add(id);
    try {
      await _repository.deleteServiceRequestAttachment(ticket.value.id, id);
      attachments.removeWhere((a) => a.id == id);
    } on ServiceRequestException catch (e) {
      AppSnackbar.showError(
        e.message.trim().isNotEmpty ? e.message : 'something_went_wrong'.tr,
      );
    } catch (_) {
      AppSnackbar.showError('something_went_wrong'.tr);
    } finally {
      deletingAttachmentIds.remove(id);
    }
  }

  String _extensionOf(String name) {
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == name.length - 1) return '';
    return name.substring(dotIndex + 1).toUpperCase();
  }
}
