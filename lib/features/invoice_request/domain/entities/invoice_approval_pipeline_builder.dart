import 'package:iungo/features/invoice_request/domain/entities/invoice_request.dart';
import 'package:iungo/features/purchase_request/domain/entities/approval_pipeline.dart';
import 'package:iungo/features/purchase_request/domain/entities/purchase_request_status.dart';

/// Builds the multi-stage [ApprovalPipeline] (Purchase Request → GRN →
/// Invoice) for an [InvoiceRequest], reusing the same generic
/// [ApprovalPipelineSection]/[ApprovalPipelineStep] classes the GRN
/// feature does — the "Approval Pipeline" sheet's shape is identical
/// across all three dashboards, only the source record type differs.
///
/// Since an Invoice only ever exists once its Purchase Request and GRN
/// stages are already approved, both of those sections are always
/// fully approved here. The Invoice section itself reflects
/// [InvoiceRequest.status] (pending/approved/rejected) — matching the
/// reference video, where a pending invoice shows its first approver
/// already signed off and a second one still waiting.
class InvoiceApprovalPipelineBuilder {
  InvoiceApprovalPipelineBuilder._();

  static ApprovalPipeline build(InvoiceRequest request) {
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
      ApprovalPipelineSection(
        title: 'GRN',
        steps: [
          ApprovalPipelineStep(
            state: ApprovalStepState.approved,
            approverName: approverPool[1],
          ),
          ApprovalPipelineStep(
            state: ApprovalStepState.approved,
            approverName: approverPool[2],
          ),
        ],
        attachmentsLabel: request.deliveryNoteFileNames.isEmpty
            ? null
            : 'Delivery Notes',
        attachmentFileNames: request.deliveryNoteFileNames,
      ),
    ];

    final invoiceSteps = switch (request.status) {
      PurchaseRequestStatus.pending => [
          ApprovalPipelineStep(
            state: ApprovalStepState.approved,
            approverName: approverPool[2],
          ),
          ApprovalPipelineStep(
            state: ApprovalStepState.waiting,
            approverName: request.nextApprovalName ?? approverPool[3],
            stageLabel: 'Stage ${request.totalStages}',
          ),
        ],
      PurchaseRequestStatus.rejected => [
          ApprovalPipelineStep(
            state: ApprovalStepState.approved,
            approverName: approverPool[2],
          ),
          ApprovalPipelineStep(
            state: ApprovalStepState.rejected,
            approverName: request.nextApprovalName ?? approverPool[3],
          ),
        ],
      PurchaseRequestStatus.approved => [
          ApprovalPipelineStep(
            state: ApprovalStepState.approved,
            approverName: approverPool[2],
          ),
          ApprovalPipelineStep(
            state: ApprovalStepState.approved,
            approverName: approverPool[3],
          ),
        ],
    };

    sections.add(
      ApprovalPipelineSection(
        title: 'Invoice',
        steps: invoiceSteps,
        attachmentsLabel:
            request.invoiceFileNames.isEmpty ? null : 'Invoices',
        attachmentFileNames: request.invoiceFileNames,
      ),
    );

    final totalStages = sections.fold<int>(
      0,
      (sum, section) => sum + section.steps.length,
    );
    final completedSteps = sections
        .expand((section) => section.steps)
        .where((step) => step.state != ApprovalStepState.waiting)
        .length;

    // A waiting step hasn't happened yet, so it doesn't count towards
    // "current stage" — e.g. 4 steps resolved + 1 still waiting reads
    // as "Stage 4 of 5", matching the reference video exactly for the
    // DIR-26-0028 example (Approved in the GRN Dashboard's pipeline,
    // still Pending here — same underlying data, each dashboard's own
    // stage still reflects only what's actually been resolved).
    var currentStage = completedSteps;
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
  /// mirrors `GrnApprovalPipelineBuilder._approverPool`.
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
