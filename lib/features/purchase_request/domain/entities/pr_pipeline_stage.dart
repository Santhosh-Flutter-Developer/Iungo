import 'package:iungo/features/purchase_request/domain/entities/approval_pipeline.dart';

/// One entry of a Purchase Request's `pipeline[]` from the API:
///
/// ```json
/// { "stage": 1, "module": "Purchase Request", "state": "O",
///   "label": "Waiting", "name": "Gladson Aby", "sno": 1,
///   "accepted_time": "2026-09-12 08:47:46.050" }
/// ```
class PrPipelineStage {
  const PrPipelineStage({
    this.stage,
    this.module = '',
    this.state = '',
    this.label = '',
    this.name = '',
    this.sno,
    this.acceptedTime,
    this.extras = const {},
  });

  /// Stage number of this approver within its module.
  final int? stage;

  /// "Purchase Request", "GRN", "Invoice" ... exactly as the API names it.
  final String module;

  /// Raw state code: `O` waiting / `C` approved / `R` rejected.
  final String state;

  /// The API's human label ("Waiting", "Approved", ...).
  final String label;

  /// Approver's name.
  final String name;
  final int? sno;

  /// When the step was accepted/decided, as wall-clock time exactly as
  /// the server wrote it (no timezone conversion is applied).
  final DateTime? acceptedTime;

  /// Any additional fields the API returned for this stage, preserved
  /// untouched so nothing is lost if the backend adds more.
  final Map<String, dynamic> extras;

  /// [state] as the three-way UI state. Falls back to [label] when the
  /// state code isn't one of `O` / `C` / `R`; anything still unknown is
  /// treated as waiting.
  ApprovalStepState get stepState {
    switch (state.trim().toUpperCase()) {
      case 'C':
        return ApprovalStepState.approved;
      case 'R':
        return ApprovalStepState.rejected;
      case 'O':
        return ApprovalStepState.waiting;
    }
    final l = label.trim().toLowerCase();
    if (l.startsWith('approv') || l.startsWith('complet')) {
      return ApprovalStepState.approved;
    }
    if (l.startsWith('reject')) return ApprovalStepState.rejected;
    return ApprovalStepState.waiting;
  }

  /// Whether [state] is one of the codes the API documents.
  bool get hasKnownState {
    final s = state.trim().toUpperCase();
    return s == 'O' || s == 'C' || s == 'R';
  }
}
