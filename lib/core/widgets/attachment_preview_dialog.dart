import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdfx/pdfx.dart';

import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/core/services/attachment_file_service.dart';
import 'package:iungo/core/services/session_service.dart';
import 'package:iungo/core/utils/attachment_kind.dart';
import 'package:iungo/core/widgets/app_snackbar.dart';

/// Everything the shared attachment preview popup needs, decoupled
/// from any one feature's attachment entity — [ServiceRequestAttachment],
/// [WorkOrderAttachment], etc. all map into this before calling
/// [showAttachmentPreview].
class AttachmentPreviewData {
  const AttachmentPreviewData({
    required this.name,
    required this.extension,
    this.contentType,
    this.previewUrl,
    this.downloadUrl,
    this.bytes,
    this.localPath,
    this.authHeaders,
  });

  final String name;

  /// Upper- or lower-case file extension, e.g. "PDF" / "mp4".
  final String extension;

  /// MIME type from the server, e.g. "image/jpeg".
  final String? contentType;

  /// Already-resolved, absolute URL for a rendered preview (used for
  /// images). May be a smaller/transcoded copy of [downloadUrl].
  final String? previewUrl;

  /// Already-resolved, absolute URL for the original file — used for
  /// the in-app PDF preview and for the "View" external-open fallback.
  final String? downloadUrl;

  /// In-memory bytes for a locally-picked, not-yet-uploaded file (web).
  final Uint8List? bytes;

  /// Local file path for a locally-picked, not-yet-uploaded file
  /// (mobile).
  final String? localPath;

  /// Headers (Bearer token, etc.) required to fetch [previewUrl] /
  /// [downloadUrl] from the portal host.
  final Map<String, String>? authHeaders;
}

/// Shows the attachment preview as a popup overlay — the same pattern
/// already used across every Detail View (Service Request, Work Order,
/// Inventory Request): a dimmed background with a rounded card on top,
/// closed with the X in its header. What renders inside depends on the
/// attachment's kind:
///  - image: pinch-zoomable inline preview (unchanged behaviour)
///  - pdf: downloaded and rendered inline, with a loading state
///  - video / audio / anything else: a "Preview isn't available"
///    message with a View button that downloads the file and opens it
///    in whatever app the device has for it
Future<void> showAttachmentPreview(
  BuildContext context,
  AttachmentPreviewData data,
) {
  return showDialog(
    context: context,
    barrierColor: Colors.black87,
    builder: (_) => _AttachmentPreviewDialog(data: data),
  );
}

/// Convenience for callers that already have a Bearer token to attach —
/// builds the `Authorization` header map [AttachmentPreviewData] expects.
Map<String, String> attachmentAuthHeaders() {
  final token = Get.isRegistered<SessionService>()
      ? Get.find<SessionService>().token.value
      : null;
  return {
    if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
  };
}

class _AttachmentPreviewDialog extends StatefulWidget {
  const _AttachmentPreviewDialog({required this.data});

  final AttachmentPreviewData data;

  @override
  State<_AttachmentPreviewDialog> createState() =>
      _AttachmentPreviewDialogState();
}

class _AttachmentPreviewDialogState extends State<_AttachmentPreviewDialog> {
  late final AttachmentKind _kind = classifyAttachment(
    contentType: widget.data.contentType,
    extension: widget.data.extension,
  );

  bool _isOpeningExternally = false;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: screenSize.height * 0.82,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            color: AppColors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Header(name: widget.data.name, extension: widget.data.extension),
                const Divider(height: 1, color: AppColors.divider),
                Flexible(child: _buildContent(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (_kind) {
      case AttachmentKind.image:
        return _ImagePreview(data: widget.data);
      case AttachmentKind.pdf:
        return _PdfPreview(
          data: widget.data,
          onViewExternally: _openExternally,
          isOpeningExternally: _isOpeningExternally,
        );
      case AttachmentKind.video:
      case AttachmentKind.audio:
      case AttachmentKind.other:
        return _UnsupportedPreview(
          kind: _kind,
          name: widget.data.name,
          onView: _openExternally,
          isOpening: _isOpeningExternally,
        );
    }
  }

  Future<void> _openExternally() async {
    final url = widget.data.downloadUrl ?? widget.data.previewUrl;
    if (url == null) {
      AppSnackbar.showError('open_attachment_failed'.tr);
      return;
    }
    setState(() => _isOpeningExternally = true);
    try {
      final result = await AttachmentFileService.instance.openExternally(
        url,
        widget.data.name,
        headers: widget.data.authHeaders,
      );
      if (result.type != ResultType.done && mounted) {
        AppSnackbar.showError('open_attachment_failed'.tr);
      }
    } catch (_) {
      if (mounted) AppSnackbar.showError('open_attachment_failed'.tr);
    } finally {
      if (mounted) setState(() => _isOpeningExternally = false);
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.extension});

  final String name;
  final String extension;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
          if (extension.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                extension.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.headingBlueGrey,
                ),
              ),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textDark),
            onPressed: () => Get.back(),
          ),
        ],
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.data});

  final AttachmentPreviewData data;

  @override
  Widget build(BuildContext context) {
    Widget image;
    if (data.bytes != null) {
      image = Image.memory(data.bytes!, fit: BoxFit.contain);
    } else if (!kIsWeb && data.localPath != null) {
      image = Image.file(File(data.localPath!), fit: BoxFit.contain);
    } else if (data.previewUrl != null || data.downloadUrl != null) {
      image = Image.network(
        (data.previewUrl ?? data.downloadUrl)!,
        fit: BoxFit.contain,
        headers: data.authHeaders,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Padding(
            padding: EdgeInsets.all(48),
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        },
        errorBuilder: (context, error, stackTrace) =>
            _PreviewErrorText(name: data.name),
      );
    } else {
      image = _PreviewErrorText(name: data.name);
    }

    return InteractiveViewer(
      minScale: 1,
      maxScale: 4,
      child: Center(child: image),
    );
  }
}

class _PdfPreview extends StatefulWidget {
  const _PdfPreview({
    required this.data,
    required this.onViewExternally,
    required this.isOpeningExternally,
  });

  final AttachmentPreviewData data;
  final VoidCallback onViewExternally;
  final bool isOpeningExternally;

  @override
  State<_PdfPreview> createState() => _PdfPreviewState();
}

class _PdfPreviewState extends State<_PdfPreview> {
  late Future<PdfControllerPinch> _controllerFuture;

  @override
  void initState() {
    super.initState();
    _controllerFuture = _load();
  }

  Future<PdfControllerPinch> _load() async {
    final url = widget.data.downloadUrl ?? widget.data.previewUrl;
    Uint8List bytes;
    if (widget.data.bytes != null) {
      bytes = widget.data.bytes!;
    } else if (!kIsWeb && widget.data.localPath != null) {
      bytes = await File(widget.data.localPath!).readAsBytes();
    } else if (url != null) {
      bytes = await AttachmentFileService.instance.fetchBytes(
        url,
        headers: widget.data.authHeaders,
      );
    } else {
      throw StateError('No source available for this attachment.');
    }
    return PdfControllerPinch(document: PdfDocument.openData(bytes));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PdfControllerPinch>(
      future: _controllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: 16),
                Text(
                  'loading_attachment'.tr,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.headingBlueGrey,
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _UnsupportedPreview(
            kind: AttachmentKind.pdf,
            name: widget.data.name,
            onView: widget.onViewExternally,
            isOpening: widget.isOpeningExternally,
          );
        }

        return PdfViewPinch(controller: snapshot.data!);
      },
    );
  }

  @override
  void dispose() {
    _controllerFuture
        .then((controller) => controller.dispose())
        .catchError((_) {});
    super.dispose();
  }
}

class _UnsupportedPreview extends StatelessWidget {
  const _UnsupportedPreview({
    required this.kind,
    required this.name,
    required this.onView,
    required this.isOpening,
  });

  final AttachmentKind kind;
  final String name;
  final VoidCallback onView;
  final bool isOpening;

  IconData get _icon {
    switch (kind) {
      case AttachmentKind.video:
        return Icons.videocam_outlined;
      case AttachmentKind.audio:
        return Icons.audiotrack_outlined;
      case AttachmentKind.image:
      case AttachmentKind.pdf:
      case AttachmentKind.other:
        return Icons.insert_drive_file_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 56, color: AppColors.headingBlueGrey),
          const SizedBox(height: 16),
          Text(
            'preview_not_available_attachment'.tr,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.textDark),
          ),
          const SizedBox(height: 20),
          Material(
            color: AppColors.attachmentViewBackground,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: isOpening ? null : onView,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: isOpening
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.open_in_new,
                              size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            'view'.tr,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewErrorText extends StatelessWidget {
  const _PreviewErrorText({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        'preview_not_available_attachment'.tr,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 14, color: AppColors.textDark),
      ),
    );
  }
}
