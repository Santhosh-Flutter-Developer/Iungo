import 'package:iungo/features/purchase_request/domain/entities/pr_attachment.dart';
import 'package:iungo/features/purchase_request/domain/entities/pr_pipeline_stage.dart';
import 'package:iungo/features/purchase_request/domain/entities/purchase_request.dart';

/// State of one step inside an [ApprovalPipelineSection] — drives the
/// green check / orange hourglass / grey clock / red cross shown
/// against each step in the "Approval Pipeline" sheet.
///
/// [nextApprover] is the API's `NS` state: this approver is queued
/// after the current one but the request hasn't reached them yet —
/// distinct from [waiting], which is the step currently awaiting
/// action.
enum ApprovalStepState { approved, waiting, nextApprover, rejected }

/// One approver's decision (or pending decision) inside a pipeline
/// section, e.g. "Approved — Gladson Aby" or "Waiting — Approver — mari".
class ApprovalPipelineStep {
  const ApprovalPipelineStep({
    required this.state,
    required this.approverName,
    this.stageLabel,
    this.label,
    this.acceptedTime,
  });

  final ApprovalStepState state;
  final String approverName;

  /// e.g. "Stage 5" — only shown on the current in-progress step.
  final String? stageLabel;

  /// The API's own label for the step ("Waiting", "Approved", ...). Only
  /// used as the title when the API's state code isn't one this app
  /// knows how to translate.
  final String? label;

  /// When the step was decided (wall-clock, as sent by the server).
  final DateTime? acceptedTime;
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
    this.attachmentUrls = const [],
  });

  final String title;
  final List<ApprovalPipelineStep> steps;
  final String? attachmentsLabel;
  final List<String> attachmentFileNames;

  /// Download URLs parallel to [attachmentFileNames] (same length and
  /// order) — empty for pipelines whose files can't be opened.
  final List<String> attachmentUrls;
}

/// The full multi-stage approval trail for one request, backing the
/// "Approval Pipeline" sheet opened from the list's Stage row.
class ApprovalPipeline {
  const ApprovalPipeline({
    required this.currentStage,
    required this.totalStages,
    required this.sections,
  });

  final int currentStage;
  final int totalStages;
  final List<ApprovalPipelineSection> sections;

  /// Builds the pipeline for [request] from the API's `pipeline[]`:
  /// steps are grouped by their `module` (in the order the modules first
  /// appear), and each module gets the files that belong to it —
  /// `attachments[]` for the Purchase Request module, `delivery_notes[]`
  /// for GRN and `invoices[]` for Invoice. Files whose module never
  /// appears in the pipeline still get a section of their own so they
  /// are not lost.
  factory ApprovalPipeline.forRequest(PurchaseRequest request) {
    final moduleOrder = <String>[];
    final stepsByModule = <String, List<PrPipelineStage>>{};
    for (final stage in request.pipeline) {
      final module = stage.module.trim();
      if (!stepsByModule.containsKey(module)) {
        moduleOrder.add(module);
        stepsByModule[module] = <PrPipelineStage>[];
      }
      stepsByModule[module]!.add(stage);
    }

    final sections = <ApprovalPipelineSection>[];
    final usedKinds = <_ModuleKind>{};

    for (final module in moduleOrder) {
      final kind = _kindOf(module);
      // Only the first section of a kind gets that kind's files.
      final files = usedKinds.add(kind)
          ? _filesFor(kind, request)
          : const <PrAttachment>[];
      sections.add(
        _section(
          title: module,
          stages: stepsByModule[module]!,
          kind: kind,
          files: files,
        ),
      );
    }

    // Files whose stage isn't part of the pipeline.
    for (final kind in _ModuleKind.values) {
      if (usedKinds.contains(kind)) continue;
      final files = _filesFor(kind, request);
      if (files.isEmpty) continue;
      sections.add(
        _section(
          title: _defaultTitle(kind),
          stages: const [],
          kind: kind,
          files: files,
        ),
      );
    }

    final total = request.totalStages;
    return ApprovalPipeline(
      currentStage: request.currentStage,
      totalStages: total,
      sections: sections,
    );
  }

  static ApprovalPipelineSection _section({
    required String title,
    required List<PrPipelineStage> stages,
    required _ModuleKind kind,
    required List<PrAttachment> files,
  }) {
    return ApprovalPipelineSection(
      title: title,
      steps: [
        for (final stage in stages)
          ApprovalPipelineStep(
            state: stage.stepState,
            approverName: stage.name,
            stageLabel: stage.stage == null ? null : 'Stage ${stage.stage}',
            label: stage.label,
            acceptedTime: stage.acceptedTime,
          ),
      ],
      attachmentsLabel: files.isEmpty ? null : _attachmentsLabel(kind),
      attachmentFileNames: [for (final f in files) f.name],
      attachmentUrls: [for (final f in files) f.url],
    );
  }

  static _ModuleKind _kindOf(String module) {
    final m = module.toLowerCase();
    if (m.contains('grn') || m.contains('delivery')) {
      return _ModuleKind.grn;
    }
    if (m.contains('invoice')) return _ModuleKind.invoice;
    return _ModuleKind.purchaseRequest;
  }

  static List<PrAttachment> _filesFor(_ModuleKind kind, PurchaseRequest r) {
    switch (kind) {
      case _ModuleKind.purchaseRequest:
        return r.attachments;
      case _ModuleKind.grn:
        return r.deliveryNotes;
      case _ModuleKind.invoice:
        return r.invoices;
    }
  }

  static String _attachmentsLabel(_ModuleKind kind) {
    switch (kind) {
      case _ModuleKind.purchaseRequest:
        return 'Purchase Request Attachments';
      case _ModuleKind.grn:
        return 'Delivery Notes';
      case _ModuleKind.invoice:
        return 'Invoices';
    }
  }

  static String _defaultTitle(_ModuleKind kind) {
    switch (kind) {
      case _ModuleKind.purchaseRequest:
        return 'Purchase Request';
      case _ModuleKind.grn:
        return 'GRN';
      case _ModuleKind.invoice:
        return 'Invoice';
    }
  }
}

/// Which family of files a pipeline module owns.
enum _ModuleKind { purchaseRequest, grn, invoice }
