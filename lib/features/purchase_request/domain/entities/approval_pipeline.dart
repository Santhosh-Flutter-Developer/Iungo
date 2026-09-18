import 'package:iungo/features/purchase_request/domain/entities/purchase_request.dart';
import 'package:iungo/features/purchase_request/domain/entities/purchase_request_status.dart';

/// State of one step inside an [ApprovalPipelineSection] — drives the
/// green check / orange dot / red cross shown against each step in the
/// "Approval Pipeline" sheet.
enum ApprovalStepState { approved, waiting, rejected }

/// One approver's decision (or pending decision) inside a pipeline
/// section, e.g. "Approved — Gladson Aby" or "Waiting — Approver — mari".
class ApprovalPipelineStep {
  const ApprovalPipelineStep({
    required this.state,
    required this.approverName,
    this.stageLabel,
  });

  final ApprovalStepState state;
  final String approverName;

  /// e.g. "Stage 5" — only shown on the current in-progress step.
  final String? stageLabel;
}

/// One stage of the overall pipeline — "Purchase Request", "GRN", or
/// "Invoice" — grouping its approval step(s) and any attachments filed
/// at that stage (quotations, delivery notes, invoices).
class ApprovalPipelineSection {
  const ApprovalPipelineSection({
    required this.title,
    required this.steps,
    this.attachmentsLabel,
    this.attachmentFileNames = const [],
  });

  final String title;
  final List<ApprovalPipelineStep> steps;
  final String? attachmentsLabel;
  final List<String> attachmentFileNames;
}

/// The full multi-stage approval trail for one [PurchaseRequest],
/// backing the "Approval Pipeline" sheet opened from the list's Stage
/// row. GRN/Invoice stages only follow once the Purchase Request stage
/// itself is approved, matching the reference flow.
class ApprovalPipeline {
  const ApprovalPipeline({
    required this.currentStage,
    required this.totalStages,
    required this.sections,
  });

  final int currentStage;
  final int totalStages;
  final List<ApprovalPipelineSection> sections;

  /// Builds the pipeline for [request]. There is no dedicated pipeline
  /// API yet — the Purchase Request stage reflects the request's own
  /// status/approver fields directly, and (once that stage is approved)
  /// a representative GRN/Invoice trail is generated so the sheet has
  /// something to show. Swap this for a real fetched pipeline once the
  /// backend exposes one.
  factory ApprovalPipeline.forRequest(PurchaseRequest request) {
    final approverPool = _approverPool(request.id);

    final prStep = switch (request.status) {
      PurchaseRequestStatus.pending => ApprovalPipelineStep(
          state: ApprovalStepState.waiting,
          approverName: request.nextApprovalName ?? approverPool[0],
          stageLabel: 'Stage ${request.currentStage}',
        ),
      PurchaseRequestStatus.rejected => ApprovalPipelineStep(
          state: ApprovalStepState.rejected,
          approverName: request.nextApprovalName ?? approverPool[0],
        ),
      PurchaseRequestStatus.approved => ApprovalPipelineStep(
          state: ApprovalStepState.approved,
          approverName: approverPool[0],
        ),
    };

    final sections = <ApprovalPipelineSection>[
      ApprovalPipelineSection(
        title: 'Purchase Request',
        steps: [prStep],
        attachmentsLabel: request.quotationFileNames.isEmpty
            ? null
            : 'Purchase Request Attachments',
        attachmentFileNames: request.quotationFileNames,
      ),
    ];

    if (request.status == PurchaseRequestStatus.approved) {
      sections.add(
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
          attachmentsLabel: 'Delivery Notes',
          attachmentFileNames: request.quotationFileNames.isNotEmpty
              ? request.quotationFileNames
              : const ['delivery_note.pdf'],
        ),
      );
      sections.add(
        ApprovalPipelineSection(
          title: 'Invoice',
          steps: [
            ApprovalPipelineStep(
              state: ApprovalStepState.approved,
              approverName: approverPool[2],
            ),
            ApprovalPipelineStep(
              state: ApprovalStepState.waiting,
              approverName: approverPool[3],
              stageLabel: 'Stage ${request.totalStages}',
            ),
          ],
          attachmentsLabel: 'Invoices',
          attachmentFileNames: const ['invoice.pdf'],
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

    // A waiting step hasn't happened yet, so it doesn't count towards
    // "current stage" — e.g. 4 steps resolved + 1 still waiting reads
    // as "Stage 4 of 5", not "Stage 5 of 5". Once nothing is waiting,
    // currentStage naturally equals totalStages (fully done).
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
  /// same request always shows the same synthetic names across opens.
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
