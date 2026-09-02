import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';

/// Shared "Approve Request" / "Reject Request" dialogs used by every
/// detail view that supports a client-approval workflow (Work Order,
/// Inventory Request, ...).
///
/// Pulling these out of the individual action bars means:
///  - Work Order and Inventory Request no longer carry two byte-for-byte
///    copies of the same dialog code.
///  - Any future visual or copy change happens in one place.
///  - Every approval flow in the app looks and behaves identically.

/// Shows the "Approve Request" confirmation dialog.
/// Returns `true` if the user confirmed, `null`/`false` if they cancelled.
Future<bool?> showApproveRequestDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (dialogContext) => _ConfirmDialog(
      icon: Icons.task_alt_rounded,
      accentColor: AppColors.primary,
      iconBackground: AppColors.workOrderChipBackground,
      title: 'approve_request_confirm_title'.tr,
      message: 'approve_request_confirm_message'.tr,
      confirmLabel: 'approve'.tr,
      onConfirm: () => Navigator.of(dialogContext).pop(true),
      onCancel: () => Navigator.of(dialogContext).pop(false),
    ),
  );
}

/// Shows the "Reject Request" dialog with a mandatory remarks field.
/// Returns the trimmed remarks string if the user submitted, `null` if
/// they cancelled.
Future<String?> showRejectRequestDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (dialogContext) => const _RejectRemarksDialog(),
  );
}

/// Common frame both dialogs share: a tinted icon badge, title, spacing,
/// and a rounded sheet — so the two dialogs read as one family even
/// though only Approve uses the simple variant directly.
class _DialogFrame extends StatelessWidget {
  const _DialogFrame({
    required this.child,
    this.maxWidth = 340,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.scaffoldWhite,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
          child: child,
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    required this.color,
    required this.background,
    this.size = 56,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

class _DialogActionRow extends StatelessWidget {
  const _DialogActionRow({
    required this.cancelLabel,
    required this.confirmLabel,
    required this.confirmColor,
    required this.onCancel,
    required this.onConfirm,
    this.confirmEnabled = true,
  });

  final String cancelLabel;
  final String confirmLabel;
  final Color confirmColor;
  final VoidCallback onCancel;
  final VoidCallback? onConfirm;
  final bool confirmEnabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textDark,
              side: const BorderSide(color: AppColors.divider),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(cancelLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: confirmEnabled ? onConfirm : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              disabledBackgroundColor: confirmColor.withValues(alpha: 0.35),
              foregroundColor: AppColors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(confirmLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

/// Simple centered confirm dialog — icon badge, title, message, two
/// equal-width actions. Used for the "Approve Request" confirmation.
class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.icon,
    required this.accentColor,
    required this.iconBackground,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.onConfirm,
    required this.onCancel,
  });

  final IconData icon;
  final Color accentColor;
  final Color iconBackground;
  final String title;
  final String message;
  final String confirmLabel;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return _DialogFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _IconBadge(icon: icon, color: accentColor, background: iconBackground),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, height: 1.4, color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          _DialogActionRow(
            cancelLabel: 'cancel'.tr,
            confirmLabel: confirmLabel,
            confirmColor: accentColor,
            onCancel: onCancel,
            onConfirm: onConfirm,
          ),
        ],
      ),
    );
  }
}

/// The "Reject Request" dialog — a mandatory multiline remarks field
/// plus Cancel/Reject actions. The Reject button stays disabled until
/// remarks are non-empty, so there's no way to submit an invalid form
/// and no need for a validation message to appear after the fact.
class _RejectRemarksDialog extends StatefulWidget {
  const _RejectRemarksDialog();

  @override
  State<_RejectRemarksDialog> createState() => _RejectRemarksDialogState();
}

class _RejectRemarksDialogState extends State<_RejectRemarksDialog> {
  static const int _maxRemarksLength = 250;

  final TextEditingController _remarksController = TextEditingController();

  bool get _isValid => _remarksController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _remarksController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_isValid) return;
    Navigator.of(context).pop(_remarksController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return _DialogFrame(
      maxWidth: 380,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const _IconBadge(
                icon: Icons.report_gmailerrorred_rounded,
                color: AppColors.attachmentDeleteText,
                background: AppColors.attachmentDeleteBackground,
                size: 48,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'reject_request'.tr,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'reject_request_prompt'.tr,
            style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _remarksController,
            maxLines: 4,
            minLines: 3,
            maxLength: _maxRemarksLength,
            textInputAction: TextInputAction.done,
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            decoration: InputDecoration(
              labelText: 'remarks'.tr,
              hintText: 'enter_remarks_hint'.tr,
              alignLabelWithHint: true,
              filled: true,
              fillColor: AppColors.inputFill,
              counterStyle: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.inputBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.inputBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _DialogActionRow(
            cancelLabel: 'cancel'.tr,
            confirmLabel: 'reject'.tr,
            confirmColor: AppColors.attachmentDeleteText,
            confirmEnabled: _isValid,
            onCancel: () => Navigator.of(context).pop(),
            onConfirm: _submit,
          ),
        ],
      ),
    );
  }
}