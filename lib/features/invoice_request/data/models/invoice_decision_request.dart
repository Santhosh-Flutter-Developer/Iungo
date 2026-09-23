/// Approve / reject payloads of the Invoice API (`invoice_request.php`).
///
/// Approve — takes the invoice attachment filenames:
/// ```json
/// { "approve_reject_pr_id": "142", "action_type": "approve",
///   "user_id": "...", "invoices": ["222.pdf"] }
/// ```
///
/// Reject isn't documented for the Invoice endpoint directly, but the
/// backend rejects an empty `invoices: []` list even on reject
/// (confirmed against the live server — it responds with "Please
/// attach invoice before proceeding"). PR's own reject on
/// `purchase_request.php` (which IS documented) sends
/// `selected_attachments: ""` — an empty **string**, not a list — so
/// this mirrors that shape for reject, swapping in `invoices`.
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

  /// Sends `invoices` as an empty string, not an empty list — the
  /// backend rejects an empty list even for `action_type: "reject"`.
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
      invoices: '',
    );
  }

  final int invoiceId;
  final String userId;
  final String actionType;
  final String? remarks;

  /// A list of filenames for approve, an empty string for reject —
  /// matching what the live backend actually accepts.
  final Object invoices;

  Map<String, dynamic> toJson() => {
        'approve_reject_pr_id': '$invoiceId',
        'action_type': actionType,
        'user_id': userId,
        if (remarks != null) 'remarks': remarks,
        'invoices': invoices,
      };
}
