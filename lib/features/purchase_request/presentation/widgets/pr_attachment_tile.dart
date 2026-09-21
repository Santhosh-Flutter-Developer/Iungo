import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/core/widgets/app_snackbar.dart';
import 'package:iungo/core/network/iungo_dio.dart';
import 'package:iungo/core/widgets/attachment_preview_dialog.dart';
import 'package:iungo/features/purchase_request/domain/entities/pr_attachment.dart';
import 'package:iungo/features/purchase_request/domain/entities/purchase_request.dart';

/// Opens a Purchase Request attachment — in-app for images/PDFs, handed
/// to the device's own app for anything else (the shared attachment
/// preview). The files live on the Iungo host, so NO Bearer token is
/// attached (that token belongs to the Facilio portal) — but they DO
/// need [IungoDio.instance] (the Iungo host's certificate override)
/// rather than whatever `Dio` GetX happens to have registered ambiently
/// for a different host, which is what silently broke every PR
/// attachment/PDF preview before this.
Future<void> openPrAttachment(BuildContext context, PrAttachment attachment) {
  return showAttachmentPreview(
    context,
    AttachmentPreviewData(
      name: attachment.name,
      extension: attachment.extension,
      previewUrl: attachment.url,
      downloadUrl: attachment.url,
      dio: IungoDio.instance,
    ),
  );
}

/// Opens the printable PDF of [request] (the API's `pdf_path`) in the
/// in-app PDF viewer, which also offers "View" to hand the file to the
/// device's own PDF app (from where it can be printed or shared). Shows a
/// message when the API sent no PDF for the request. Like the
/// attachments, the file lives on the Iungo host, so no Bearer token is
/// attached.
Future<void> openPrPdf(BuildContext context, PurchaseRequest request) async {
  final url = request.pdfPath;
  if (url == null || url.isEmpty) {
    AppSnackbar.showError('pr_pdf_unavailable'.tr);
    return;
  }
  final fileName =
      request.prNumber.isEmpty ? 'purchase_request.pdf' : '${request.prNumber}.pdf';
  await showAttachmentPreview(
    context,
    AttachmentPreviewData(
      name: fileName,
      extension: 'pdf',
      contentType: 'application/pdf',
      previewUrl: url,
      downloadUrl: url,
      dio: IungoDio.instance,
    ),
  );
}

/// One attachment row. Two modes:
///
///  * normal (requestor, or an approver looking at a non-actionable
///    request): a downloadable/openable file — tapping opens it.
///  * [selectable] (approver on an Action Required request): a
///    radio-style card. Tapping the card selects it (only one can be
///    selected at a time — the owner enforces that), the download icon
///    still opens the file so the approver can look at it first.
class PrAttachmentTile extends StatelessWidget {
  const PrAttachmentTile({
    super.key,
    required this.attachment,
    this.selectable = false,
    this.selected = false,
    this.onSelect,
    this.onOpen,
  });

  final PrAttachment attachment;
  final bool selectable;
  final bool selected;
  final VoidCallback? onSelect;

  /// Overrides what the download icon / normal tap does (defaults to
  /// [openPrAttachment]).
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final highlighted = selectable && selected;
    final open = onOpen ?? () => openPrAttachment(context, attachment);

    return Semantics(
      inMutuallyExclusiveGroup: selectable ? true : null,
      checked: selectable ? selected : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: selectable ? onSelect : open,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: highlighted
                ? AppColors.workOrderChipBackground
                : AppColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: highlighted ? AppColors.primary : AppColors.divider,
              width: highlighted ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              if (selectable)
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 24,
                  color: selected ? AppColors.primary : AppColors.textMuted,
                )
              else
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.insert_drive_file_outlined,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  attachment.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: highlighted ? FontWeight.w600 : FontWeight.w500,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: open,
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.download_outlined,
                    size: 20,
                    color: AppColors.headingBlueGrey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
