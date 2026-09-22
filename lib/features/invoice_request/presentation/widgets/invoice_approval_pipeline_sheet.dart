import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/core/utils/app_date_format.dart';
import 'package:iungo/features/invoice_request/domain/entities/invoice_approval_pipeline_builder.dart';
import 'package:iungo/features/invoice_request/domain/entities/invoice_request.dart';
import 'package:iungo/features/purchase_request/domain/entities/approval_pipeline.dart';

/// The "Approval Pipeline" sheet opened by tapping a request's Stage
/// row on the Invoice Dashboard list — a Request Overview box followed
/// by each pipeline section (Purchase Request / GRN / Invoice) as a
/// vertical status timeline, with that section's attachments (if any)
/// underneath. Mirrors `GrnApprovalPipelineSheet` exactly, adapted to
/// read from an [InvoiceRequest] instead of a `GrnRequest`.
class InvoiceApprovalPipelineSheet extends StatelessWidget {
  const InvoiceApprovalPipelineSheet({super.key, required this.request});

  final InvoiceRequest request;

  static Future<void> show(BuildContext context, InvoiceRequest request) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InvoiceApprovalPipelineSheet(request: request),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pipeline = InvoiceApprovalPipelineBuilder.build(request);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.scaffoldWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _Header(pipeline: pipeline),
              const Divider(height: 1, color: AppColors.divider),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    _RequestOverviewCard(request: request),
                    const SizedBox(height: 24),
                    Text(
                      'pr_approval_pipeline'.tr.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                        color: AppColors.labelGrey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final section in pipeline.sections)
                      _PipelineSectionView(section: section),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.pipeline});

  final ApprovalPipeline pipeline;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'pr_approval_pipeline'.tr,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'pr_stage_of'.trParams({
                    'current': '${pipeline.currentStage}',
                    'total': '${pipeline.totalStages}',
                  }),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textMuted),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _RequestOverviewCard extends StatelessWidget {
  const _RequestOverviewCard({required this.request});

  final InvoiceRequest request;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Text(
            'pr_request_overview'.tr.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              color: AppColors.labelGrey,
            ),
          ),
          const SizedBox(height: 14),
          _OverviewRow(label: 'pr_number'.tr, value: request.number),
          _OverviewRow(
            label: 'pr_request_date'.tr,
            value: AppDateFormat.mediumDate(request.requestDate),
          ),
          _OverviewRow(label: 'pr_contract'.tr, value: request.contract),
          _OverviewRow(
            label: 'pr_total_amount'.tr,
            value: '${request.totalAmount.toStringAsFixed(2)} SAR',
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _OverviewRow extends StatelessWidget {
  const _OverviewRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _PipelineSectionView extends StatelessWidget {
  const _PipelineSectionView({required this.section});

  final ApprovalPipelineSection section;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 14),
          for (var i = 0; i < section.steps.length; i++)
            _StepRow(
              step: section.steps[i],
              isLast: i == section.steps.length - 1 &&
                  section.attachmentFileNames.isEmpty,
            ),
          if (section.attachmentFileNames.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.attach_file,
                          size: 15, color: AppColors.headingBlueGrey),
                      const SizedBox(width: 6),
                      Text(
                        (section.attachmentsLabel ?? '').toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                          color: AppColors.headingBlueGrey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  for (final fileName in section.attachmentFileNames)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _AttachmentTile(fileName: fileName),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step, required this.isLast});

  final ApprovalPipelineStep step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;
    final String title;
    final String subtitle;
    switch (step.state) {
      case ApprovalStepState.approved:
        color = const Color(0xFF3D8B4E);
        icon = Icons.check;
        title = 'pr_approved_dash'.tr;
        subtitle = 'pr_approved_by'.trParams({'name': step.approverName});
      case ApprovalStepState.rejected:
        color = const Color(0xFFB3261E);
        icon = Icons.close;
        title = 'pr_rejected_dash'.tr;
        subtitle = 'pr_rejected_by'.trParams({'name': step.approverName});
      case ApprovalStepState.waiting:
        color = const Color(0xFFC77A1E);
        icon = Icons.hourglass_empty;
        title = 'pr_waiting_dash'.tr;
        subtitle = 'pr_waiting_in_progress'.tr;
      case ApprovalStepState.nextApprover:
        color = const Color(0xFF9AA0A6);
        icon = Icons.schedule;
        title = 'pr_next_approver_dash'.tr;
        subtitle = 'pr_next_approver_by'.trParams({'name': step.approverName});
    }

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, size: 14, color: AppColors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
                if (step.state == ApprovalStepState.waiting) ...[
                  const SizedBox(height: 4),
                  Text(
                    'pr_approver_label'.trParams({'name': step.approverName}),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  if (step.stageLabel != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.workOrderChipBackground,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        step.stageLabel!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({required this.fileName});

  final String fileName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          const Icon(Icons.picture_as_pdf_outlined,
              size: 18, color: AppColors.attachmentDeleteText),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
              ),
            ),
          ),
          const Icon(Icons.download_outlined,
              size: 18, color: AppColors.headingBlueGrey),
        ],
      ),
    );
  }
}
