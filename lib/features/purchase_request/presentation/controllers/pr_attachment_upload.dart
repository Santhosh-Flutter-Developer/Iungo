import 'package:dio/dio.dart' show CancelToken;
import 'package:get/get.dart';
import 'package:iungo/features/service_request/domain/entities/attachment_file.dart';

enum PrAttachmentStatus { uploading, uploaded, failed }

/// One quotation attachment on the Add Purchase Request form and its
/// live upload state. Each file is uploaded individually the moment it
/// is picked; [savedName] (the server's `saved_name`) is what the PR
/// save payload later sends in `attachments`.
class PrAttachmentUpload {
  PrAttachmentUpload({required this.id, required this.file});

  final int id;
  final AttachmentFile file;

  final Rx<PrAttachmentStatus> status = PrAttachmentStatus.uploading.obs;

  /// 0..1 of the request body sent so far.
  final RxDouble progress = 0.0.obs;
  final Rxn<String> savedName = Rxn<String>();
  final Rxn<String> errorMessage = Rxn<String>();

  /// Lets an in-flight upload be aborted when the user removes the row.
  CancelToken cancelToken = CancelToken();

  /// Set when the user removed the row — a late result is then ignored.
  bool removed = false;

  String get name => file.name;
  bool get isUploading => status.value == PrAttachmentStatus.uploading;
  bool get isUploaded => status.value == PrAttachmentStatus.uploaded;
  bool get isFailed => status.value == PrAttachmentStatus.failed;
}
