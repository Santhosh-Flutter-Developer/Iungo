/// Business rules for approving/rejecting an Invoice. Pure functions
/// returning a translation key (or null when valid), mirroring
/// `GrnDecisionValidator`.
///
/// Approving an Invoice requires AT LEAST ONE invoice attachment — any
/// number is fine (mirrors GRN's rule). Rejecting does not require any
/// attachment — only the reject remarks are validated.
class InvoiceDecisionValidator {
  InvoiceDecisionValidator._();

  static const int maxRemarksLength = 250;

  /// Approving an Invoice requires AT LEAST ONE attachment — any number
  /// is fine (mirrors `GrnDecisionValidator.approveRequiresDeliveryNote`).
  static String? approveRequiresAttachment(List<String> attachmentNames) {
    final hasOne = attachmentNames.any((name) => name.trim().isNotEmpty);
    return hasOne ? null : 'invoice_attachment_required_message';
  }

  static String? rejectRemarksErrorKey(String remarks) {
    final trimmed = remarks.trim();
    if (trimmed.isEmpty) return 'pr_remarks_required_reject';
    if (trimmed.length > maxRemarksLength) return 'pr_remarks_too_long';
    return null;
  }
}
