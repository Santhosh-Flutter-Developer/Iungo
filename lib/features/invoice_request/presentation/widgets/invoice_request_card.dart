import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/core/utils/app_date_format.dart';
import 'package:iungo/features/invoice_request/domain/entities/invoice_approval_pipeline_builder.dart';
import 'package:iungo/features/invoice_request/domain/entities/invoice_request.dart';
import 'package:iungo/features/invoice_request/presentation/widgets/invoice_approval_pipeline_sheet.dart';
import 'package:iungo/features/purchase_request/domain/entities/approval_pipeline.dart';
import 'package:iungo/features/purchase_request/presentation/widgets/purchase_request_status_badge.dart';

/// One card in the Invoice Dashboard list. Tapping it opens the Detail
/// View. Mirrors `GrnRequestCard`'s composition exactly (id/status row,
/// pill chips, light info-grid box, Stage dots opening the pipeline
/// sheet) with the Invoice feature's own [InvoiceRequest]/
/// [InvoiceApprovalPipelineBuilder].
class InvoiceRequestCard extends StatelessWidget {
  const InvoiceRequestCard({
    super.key,
    required this.request,
    this.onTap,
    this.showApprovalActions = false,
    this.isSubmitting = false,
    this.onApprove,
    this.onReject,
    this.onPrint,
  });

  final InvoiceRequest request;
  final VoidCallback? onTap;

  /// Show the inline Reject/Approve buttons on this card. Callers are
  /// expected to only pass true for the approver role's pending tab.
  final bool showApprovalActions;
  final bool isSubmitting;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  /// Tapping the print icon in the card header. When left null, a
  /// placeholder "coming soon" snackbar is shown, mirroring the printer
  /// icon in the reference web dashboard's Action column.
  final VoidCallback? onPrint;

  void _handlePrint() {
    if (onPrint != null) {
      onPrint!();
      return;
    }
    Get.snackbar(
      'pr_print'.tr,
      'pr_print_coming_soon'.tr,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.primary,
      colorText: AppColors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pipelineSteps = InvoiceApprovalPipelineBuilder.build(request)
        .sections
        .expand((section) => section.steps)
        .map((step) => step.state)
        .toList();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.number,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                PurchaseRequestStatusBadge(status: request.status),
                const SizedBox(width: 8),
                _CardIconButton(
                  icon: Icons.print_outlined,
                  tooltip: 'pr_print'.tr,
                  onTap: _handlePrint,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _PillChip(
              icon: Icons.description_outlined,
              label: '${'pr_contract'.tr}: ${request.contract}',
            ),
            const SizedBox(height: 10),
            _PillChip(
              icon: Icons.calendar_today_outlined,
              label: '${'created'.tr}: '
                  '${AppDateFormat.mediumDate(request.requestDate)}',
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.workOrderInfoGridBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoItem(
                    icon: Icons.payments_outlined,
                    label: '${'pr_total'.tr}: '
                        '${request.totalAmount.toStringAsFixed(2)} SAR',
                  ),
                  const SizedBox(height: 10),
                  _InfoItem(
                    icon: Icons.person_outline,
                    label: '${'pr_next_approval'.tr}: '
                        '${request.nextApprovalName ?? '--'}',
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () =>
                        InvoiceApprovalPipelineSheet.show(context, request),
                    child: Row(
                      children: [
                        const Icon(Icons.timeline_outlined,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          '${'pr_stage'.tr}: ',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textDark,
                          ),
                        ),
                        Expanded(child: _StageDots(steps: pipelineSteps)),
                        const Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (showApprovalActions) ...[
              const SizedBox(height: 14),
              _CardApprovalActions(
                isSubmitting: isSubmitting,
                onApprove: onApprove,
                onReject: onReject,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact Reject/Approve buttons shown at the bottom of a card when
/// [InvoiceRequestCard.showApprovalActions] is true.
class _CardApprovalActions extends StatelessWidget {
  const _CardApprovalActions({
    required this.isSubmitting,
    this.onApprove,
    this.onReject,
  });

  final bool isSubmitting;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: isSubmitting ? null : onReject,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.attachmentDeleteText,
              side: const BorderSide(color: AppColors.attachmentDeleteText),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Text(
                'reject'.tr,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: isSubmitting ? null : onApprove,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: isSubmitting
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : Text(
                    'approve'.tr,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                  ),
          ),
        ),
      ],
    );
  }
}

class _PillChip extends StatelessWidget {
  const _PillChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.workOrderChipBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small circular icon button used for the card header's print action.
class _CardIconButton extends StatelessWidget {
  const _CardIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.workOrderChipBackground,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: AppColors.primary),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// Color-dot row replacing the plain "1/1" stage text — one dot per
/// approval step across the whole pipeline (Purchase Request / GRN /
/// Invoice), colored green/orange/red to match [ApprovalStepState].
class _StageDots extends StatelessWidget {
  const _StageDots({required this.steps});

  final List<ApprovalStepState> steps;

  static Color _colorFor(ApprovalStepState state) {
    switch (state) {
      case ApprovalStepState.approved:
        return const Color(0xFF3D8B4E);
      case ApprovalStepState.rejected:
        return const Color(0xFFB3261E);
      case ApprovalStepState.waiting:
        return const Color(0xFFC77A1E);
      case ApprovalStepState.nextApprover:
        return const Color(0xFF9AA0A6);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 5,
      runSpacing: 5,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final state in steps)
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _colorFor(state),
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }
}
