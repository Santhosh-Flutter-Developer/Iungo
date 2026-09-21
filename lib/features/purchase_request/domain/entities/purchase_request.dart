import 'package:iungo/core/utils/app_date_format.dart';
import 'package:iungo/features/purchase_request/domain/entities/approval_pipeline.dart';
import 'package:iungo/features/purchase_request/domain/entities/pr_attachment.dart';
import 'package:iungo/features/purchase_request/domain/entities/pr_pipeline_stage.dart';
import 'package:iungo/features/purchase_request/domain/entities/purchase_request_item.dart';
import 'package:iungo/features/purchase_request/domain/entities/purchase_request_status.dart';

/// A single Purchase Request record as returned by the Purchase Request
/// API's `data.records[]` — backs the PR Dashboard list card, the Detail
/// View's Summary/Requested Supply Items tabs and the Approval Pipeline
/// sheet. Every field is read from the API response (see
/// `PrApiMapper`); nothing here is calculated locally except the pure
/// presentation helpers below (totals of lines, stage progress).
class PurchaseRequest {
  const PurchaseRequest({
    required this.id,
    required this.prNumber,
    required this.contract,
    required this.status,
    this.requestDate,
    this.contractId = '',
    this.contractName = '',
    this.location = '',
    this.workOrderNo = '',
    this.requestDescription = '',
    this.deliveryDate,
    this.category = '',
    this.purpose = '',
    this.creatorId = '',
    this.createdBy = '',
    this.statusText = '',
    this.moduleState = '',
    this.nextApprovalRaw,
    this.nextApprovalName,
    this.margin = 0,
    this.totalBeforeVat = 0,
    this.vatAmount = 0,
    this.totalAmount = 0,
    this.items = const [],
    this.attachments = const [],
    this.deliveryNotes = const [],
    this.invoices = const [],
    this.pipeline = const [],
    this.pdfPath,
  });

  /// `id` — sent as `approve_reject_pr_id` when approving/rejecting.
  final int id;

  /// `pr_number`, e.g. "DIR-26-0029".
  final String prNumber;

  /// `pr_date` ("12-Sep-2026"), null when missing/unparseable.
  final DateTime? requestDate;

  final String contractId;
  final String contractName;

  /// `contract`, e.g. "Diriyah - DIR" (falls back to the name when the
  /// API omits it).
  final String contract;

  final String location;
  final String workOrderNo;
  final String requestDescription;

  /// `expect_date` — the delivery date.
  final DateTime? deliveryDate;
  final String category;
  final String purpose;

  /// `creator` — the creator's user id.
  final String creatorId;

  /// `created_by` — the creator's user name.
  final String createdBy;

  /// The badge state, derived from `status` (falling back to
  /// `moduleState`).
  final PurchaseRequestStatus status;

  /// The API's raw `status` text ("Pending", "Approved", ...).
  final String statusText;

  /// The API's raw `moduleState` code (`O` / `C` / `R`).
  final String moduleState;

  /// `next_approval` exactly as sent, e.g. "Gladson Aby (Pending)".
  final String? nextApprovalRaw;

  /// `next_approval` without the "(Pending)" suffix, e.g.
  /// "Gladson Aby" — null when nobody is pending ("--" / empty).
  final String? nextApprovalName;

  /// `margin` — the administrative-expenses percentage.
  final double margin;

  final double totalBeforeVat;
  final double vatAmount;
  final double totalAmount;

  final List<PurchaseRequestItem> items;

  /// `attachments[]` — the quotation files. These are what an approver
  /// picks from (exactly one) before approving.
  final List<PrAttachment> attachments;

  /// `delivery_notes[]` — shown under the GRN stage of the pipeline.
  final List<PrAttachment> deliveryNotes;

  /// `invoices[]` — shown under the Invoice stage of the pipeline.
  final List<PrAttachment> invoices;

  /// `pipeline[]`, in the order the API returned it.
  final List<PrPipelineStage> pipeline;

  /// `pdf_path` — absolute URL of the printable Purchase Request PDF
  /// (e.g. `.../reports/rpt_purchase_report_a4.php?view_pr_id=20&type=purchase_return`).
  /// Null when the API sent none.
  final String? pdfPath;

  /// Σ of the item totals. The API sends no separate "total lines"
  /// value, so it is read from the items (falling back to backing the
  /// margin out of `total_before_vat` if a record has no items).
  double get totalLines {
    if (items.isNotEmpty) {
      return items.fold<double>(0, (sum, item) => sum + item.total);
    }
    if (margin > 0) return totalBeforeVat / (1 + margin / 100);
    return totalBeforeVat;
  }

  /// Administrative-expenses percentage (`margin`).
  double get administrativeExpensesPercent => margin;

  bool get isPendingApproval => status == PurchaseRequestStatus.pending;

  /// Whether this record can still be approved/rejected: it is pending
  /// and, when the API reports a `moduleState`, that state is the
  /// waiting one (`O`).
  bool get isActionable {
    if (!isPendingApproval) return false;
    final state = moduleState.trim();
    return state.isEmpty || state.toUpperCase() == 'O';
  }

  /// "Sep 12, 2026", or "--" when the date is missing.
  String get requestDateLabel => AppDateFormat.mediumDateOrDash(requestDate);

  String get deliveryDateLabel => AppDateFormat.mediumDateOrDash(deliveryDate);

  // ---- Stage progress (from the pipeline) ------------------------------

  int get _pipelineSteps => pipeline.length;

  /// Steps already decided (approved/rejected) — a waiting step hasn't
  /// happened yet, so it doesn't count. Never below 1 while there is a
  /// pipeline, e.g. "1/1" for a single waiting step, "4/5" for four
  /// resolved steps and one waiting.
  int get currentStage {
    if (_pipelineSteps == 0) return 0;
    final resolved = pipeline
        .where((s) => s.stepState != ApprovalStepState.waiting)
        .length;
    if (resolved < 1) return 1;
    return resolved > _pipelineSteps ? _pipelineSteps : resolved;
  }

  int get totalStages => _pipelineSteps;

  /// "1/1", or "--" when the API sent no pipeline.
  String get stageLabel =>
      totalStages == 0 ? '--' : '$currentStage/$totalStages';
}
