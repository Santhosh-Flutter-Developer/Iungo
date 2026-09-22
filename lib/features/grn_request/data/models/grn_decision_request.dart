/// Approve / reject payloads of the GRN API (`grn_request.php`).
///
/// Approve — takes the delivery note filenames instead of PR's
/// `selected_attachments`:
/// ```json
/// { "approve_reject_pr_id": "134", "action_type": "approve",
///   "user_id": "...", "delivery_notes": ["converted-image.png"] }
/// ```
///
/// Reject isn't documented for GRN. The API guide documents PR's own
/// reject on `purchase_request.php` as
/// `{approve_reject_pr_id, action_type: "reject", user_id, remarks,
/// selected_attachments: ""}`; this assumes `grn_request.php` accepts
/// the same shape with the GRN id, swapping `selected_attachments` for
/// an empty `delivery_notes` list for consistency with GRN's approve
/// payload. **This half is unconfirmed by the API document — please
/// verify against the backend before relying on it.**
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

  /// Unconfirmed shape — see the class doc.
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
      deliveryNotes: const [],
    );
  }

  final int grnId;
  final String userId;
  final String actionType;
  final String? remarks;
  final List<String> deliveryNotes;

  Map<String, dynamic> toJson() => {
        'approve_reject_pr_id': '$grnId',
        'action_type': actionType,
        'user_id': userId,
        if (remarks != null) 'remarks': remarks,
        'delivery_notes': deliveryNotes,
      };
}
