/// Approve / reject payloads of the Purchase Request API.
///
/// Approve:
/// ```json
/// { "approve_reject_pr_id": "118", "action_type": "approve",
///   "user_id": "...", "remarks": "",
///   "selected_attachments": ["Iungo_Portal_API_Guide.pdf"] }
/// ```
///
/// Reject (remarks mandatory, no attachment):
/// ```json
/// { "approve_reject_pr_id": "97", "action_type": "reject",
///   "user_id": "...", "remarks": "Test", "selected_attachments": "" }
/// ```
class PrDecisionRequest {
  const PrDecisionRequest._({
    required this.prId,
    required this.userId,
    required this.actionType,
    required this.remarks,
    required this.selectedAttachments,
  });

  /// [attachmentFileName] is the ONE attachment chosen for approval.
  factory PrDecisionRequest.approve({
    required int prId,
    required String userId,
    required String attachmentFileName,
  }) {
    return PrDecisionRequest._(
      prId: prId,
      userId: userId,
      actionType: 'approve',
      remarks: '',
      selectedAttachments: [attachmentFileName],
    );
  }

  factory PrDecisionRequest.reject({
    required int prId,
    required String userId,
    required String remarks,
  }) {
    return PrDecisionRequest._(
      prId: prId,
      userId: userId,
      actionType: 'reject',
      remarks: remarks,
      selectedAttachments: '',
    );
  }

  final int prId;
  final String userId;
  final String actionType;
  final String remarks;

  /// A one-item list for approve, an empty string for reject — exactly
  /// what the API documents.
  final Object selectedAttachments;

  Map<String, dynamic> toJson() => {
        'approve_reject_pr_id': '$prId',
        'action_type': actionType,
        'user_id': userId,
        'remarks': remarks,
        'selected_attachments': selectedAttachments,
      };
}
