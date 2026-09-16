import 'package:iungo/features/grn_request/domain/entities/grn_request.dart';
import 'package:iungo/features/purchase_request/domain/entities/approval_pipeline.dart';
import 'package:iungo/features/purchase_request/domain/entities/purchase_request_status.dart';

/// Builds the multi-stage [ApprovalPipeline] (Purchase Request → GRN →
/// Invoice) for a [GrnRequest], reusing the generic
/// [ApprovalPipelineSection]/[ApprovalPipelineStep] classes already
/// defined for the PR feature — the "Approval Pipeline" sheet's shape is
/// identical for both dashboards, only the source record type differs.
///
/// Since a GRN only ever exists once its Purchase Request stage is
/// already approved, the Purchase Request section is always a single
/// approved step here. The GRN section reflects [GrnRequest.status]
/// itself (pending/approved/rejected), and the Invoice section only
/// follows once the GRN is approved — matching the reference video,
/// where the Invoice stage can still show a waiting step
/// ([GrnRequest.invoicePending]) even though the GRN itself is done.
class GrnApprovalPipelineBuilder {
  GrnApprovalPipelineBuilder._();

  static ApprovalPipeline build(GrnRequest request) {
    final approverPool = _approverPool(request.id);

    final sections = <ApprovalPipelineSection>[
      ApprovalPipelineSection(
        title: 'Purchase Request',
        steps: [
          ApprovalPipelineStep(
            state: ApprovalStepState.approved,
            approverName: approverPool[0],
          ),
        ],
        attachmentsLabel: request.quotationFileNames.isEmpty
            ? null
            : 'Purchase Request Attachments',
        attachmentFileNames: request.quotationFileNames,
      ),
    ];

    final grnSteps = switch (request.status) {
      PurchaseRequestStatus.pending => [
          ApprovalPipelineStep(
            state: ApprovalStepState.waiting,
            approverName: request.nextApprovalName ?? approverPool[1],
            stageLabel: 'Stage ${request.currentStage}',
          ),
        ],
      PurchaseRequestStatus.rejected => [
          ApprovalPipelineStep(
            state: ApprovalStepState.rejected,
            approverName: request.nextApprovalName ?? approverPool[1],
          ),
        ],
      PurchaseRequestStatus.approved => [
          ApprovalPipelineStep(
            state: ApprovalStepState.approved,
            approverName: approverPool[1],
          ),
          ApprovalPipelineStep(
            state: ApprovalStepState.approved,
            approverName: approverPool[2],
          ),
        ],
    };

    sections.add(
      ApprovalPipelineSection(
        title: 'GRN',
        steps: grnSteps,
        attachmentsLabel: request.deliveryNoteFileNames.isEmpty
            ? null
            : 'Delivery Notes',
        attachmentFileNames: request.deliveryNoteFileNames,
      ),
    );

    if (request.status == PurchaseRequestStatus.approved) {
      sections.add(
        ApprovalPipelineSection(
          title: 'Invoice',
          steps: [
            ApprovalPipelineStep(
              state: ApprovalStepState.approved,
              approverName: approverPool[2],
            ),
            if (request.invoicePending)
              ApprovalPipelineStep(
                state: ApprovalStepState.waiting,
                approverName: approverPool[3],
                stageLabel: 'Stage ${request.totalStages}',
              )
            else
              ApprovalPipelineStep(
                state: ApprovalStepState.approved,
                approverName: approverPool[3],
              ),
          ],
          attachmentsLabel:
              request.invoiceFileNames.isEmpty ? null : 'Invoices',
          attachmentFileNames: request.invoiceFileNames,
        ),
      );
    }

    final totalStages = sections.fold<int>(
      0,
      (sum, section) => sum + section.steps.length,
    );
    final completedSteps = sections
        .expand((section) => section.steps)
        .where((step) => step.state != ApprovalStepState.waiting)
        .length;
    final hasWaitingStep = sections
        .any((s) => s.steps.any((st) => st.state == ApprovalStepState.waiting));

    var currentStage = completedSteps + (hasWaitingStep ? 1 : 0);
    final effectiveTotal = totalStages == 0 ? 1 : totalStages;
    if (currentStage < 1) currentStage = 1;
    if (currentStage > effectiveTotal) currentStage = effectiveTotal;

    return ApprovalPipeline(
      currentStage: currentStage,
      totalStages: effectiveTotal,
      sections: sections,
    );
  }

  /// Small, deterministic (id-seeded) pool of approver names so the
  /// same request always shows the same synthetic names across opens —
  /// mirrors `ApprovalPipeline._approverPool`.
  static List<String> _approverPool(int seed) {
    const names = [
      'Gladson Aby',
      'Approver3',
      'prem',
      'mari',
    ];
    final offset = seed % names.length;
    return List.generate(names.length, (i) => names[(i + offset) % names.length]);
  }
}
