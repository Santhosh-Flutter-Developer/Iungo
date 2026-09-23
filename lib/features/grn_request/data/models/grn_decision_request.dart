/// Approve / reject payloads of the GRN API (`grn_request.php`).
///
/// Approve — takes the delivery note filenames instead of PR's
/// `selected_attachments`:
/// ```json
/// { "approve_reject_pr_id": "134", "action_type": "approve",
///   "user_id": "...", "delivery_notes": ["converted-image.png"] }
/// ```
///
/// Reject isn't documented for GRN directly, but (mirroring the same
/// issue confirmed on the Invoice endpoint) the backend rejects an
/// empty `delivery_notes: []` list even on reject, responding with an
/// "attach before proceeding"-style error. PR's own reject on
/// `purchase_request.php` (which IS documented) sends
/// `selected_attachments: ""` — an empty **string**, not a list — so
/// this mirrors that shape for reject, swapping in `delivery_notes`.
class GrnDecisionRequest {
  const GrnDecisionRequest._({
    required this.grnId,
    required this.userId,
    required this.actionType,
    required this.remarks,
    required this.deliveryNotes,
  });

  factory GrnDecisionRequest.approve({
    required int grnId,
    required String userId,
    required List<String> deliveryNoteFileNames,
  }) {
    return GrnDecisionRequest._(
      grnId: grnId,
      userId: userId,
      actionType: 'approve',
      remarks: null,
      deliveryNotes: deliveryNoteFileNames,
    );
  }

  /// Sends `delivery_notes` as an empty string, not an empty list —
  /// the backend rejects an empty list even for `action_type:
  /// "reject"`.
  factory GrnDecisionRequest.reject({
    required int grnId,
    required String userId,
    required String remarks,
  }) {
    return GrnDecisionRequest._(
      grnId: grnId,
      userId: userId,
      actionType: 'reject',
      remarks: remarks,
      deliveryNotes: '',
    );
  }

  final int grnId;
  final String userId;
  final String actionType;
  final String? remarks;

  /// A list of filenames for approve, an empty string for reject —
  /// matching what the live backend actually accepts.
  final Object deliveryNotes;

  Map<String, dynamic> toJson() => {
        'approve_reject_pr_id': '$grnId',
        'action_type': actionType,
        'user_id': userId,
        if (remarks != null) 'remarks': remarks,
        'delivery_notes': deliveryNotes,
      };
}
