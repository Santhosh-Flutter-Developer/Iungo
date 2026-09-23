/// Approve / reject payloads of the Invoice API (`invoice_request.php`).
///
/// Approve — takes the invoice attachment filenames:
/// ```json
/// { "approve_reject_pr_id": "142", "action_type": "approve",
///   "user_id": "...", "invoices": [] }
/// ```
/// The API guide's own example sends an empty list, so — unlike GRN's
/// delivery notes — at least one invoice attachment is NOT required to
/// approve.
///
/// Reject isn't documented for the Invoice endpoint. The API guide
/// documents PR's own reject on `purchase_request.php` as
/// `{approve_reject_pr_id, action_type: "reject", user_id, remarks,
/// selected_attachments: ""}`; this assumes `invoice_request.php` accepts
/// the same shape with the Invoice id, swapping `selected_attachments`
/// for an empty `invoices` list for consistency with the approve
/// payload. **This half is unconfirmed by the API document — please
/// verify against the backend before relying on it.**
class InvoiceDecisionRequest {
  const InvoiceDecisionRequest._({
    required this.invoiceId,
    required this.userId,
    required this.actionType,
    required this.remarks,
    required this.invoices,
  });

  factory InvoiceDecisionRequest.approve({
    required int invoiceId,
    required String userId,
    required List<String> invoiceFileNames,
  }) {
    return InvoiceDecisionRequest._(
      invoiceId: invoiceId,
      userId: userId,
      actionType: 'approve',
      remarks: null,
      invoices: invoiceFileNames,
    );
  }

  /// Unconfirmed shape — see the class doc.
  factory InvoiceDecisionRequest.reject({
    required int invoiceId,
    required String userId,
    required String remarks,
  }) {
    return InvoiceDecisionRequest._(
      invoiceId: invoiceId,
      userId: userId,
      actionType: 'reject',
      remarks: remarks,
      invoices: const [],
    );
  }

  final int invoiceId;
  final String userId;
  final String actionType;
  final String? remarks;
  final List<String> invoices;

  Map<String, dynamic> toJson() => {
        'approve_reject_pr_id': '$invoiceId',
        'action_type': actionType,
        'user_id': userId,
        if (remarks != null) 'remarks': remarks,
        'invoices': invoices,
      };
}
