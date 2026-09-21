import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/core/widgets/app_snackbar.dart';
import 'package:iungo/features/purchase_request/domain/entities/pr_attachment.dart';
import 'package:iungo/features/purchase_request/presentation/widgets/pr_attachment_tile.dart';

/// Bottom sheet used when an approver taps Approve on a list card: an
/// approval needs EXACTLY ONE attachment, and the card has nowhere to
/// pick one, so this asks for it (radio-style, single selection).
/// Resolves to the chosen attachment, or null if dismissed.
Future<PrAttachment?> showPrAttachmentSelectSheet(
  BuildContext context,
  List<PrAttachment> attachments,
) {
  return showModalBottomSheet<PrAttachment>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.scaffoldWhite,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _PrAttachmentSelectSheet(attachments: attachments),
  );
}

class _PrAttachmentSelectSheet extends StatefulWidget {
  const _PrAttachmentSelectSheet({required this.attachments});

  final List<PrAttachment> attachments;

  @override
  State<_PrAttachmentSelectSheet> createState() =>
      _PrAttachmentSelectSheetState();
}

class _PrAttachmentSelectSheetState extends State<_PrAttachmentSelectSheet> {
  PrAttachment? _selected;

  void _confirm() {
    final selected = _selected;
    if (selected == null) {
      AppSnackbar.showError('pr_select_one_attachment'.tr);
      return;
    }
    Navigator.of(context).pop(selected);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'pr_select_attachment'.tr,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'pr_select_attachment_hint'.tr,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final attachment in widget.attachments)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: PrAttachmentTile(
                        attachment: attachment,
                        selectable: true,
                        selected: _selected == attachment,
                        onSelect: () => setState(() => _selected = attachment),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textDark,
                      side: const BorderSide(color: AppColors.divider),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'cancel'.tr,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _confirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'approve'.tr,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
