/// Business rules for approving/rejecting an Invoice. Pure functions
/// returning a translation key (or null when valid), mirroring
/// `GrnDecisionValidator`.
///
/// Unlike GRN, the API guide's approve example sends an empty
/// `"invoices": []`, so approving an Invoice does NOT require an
/// attachment to already be present — only the reject remarks are
/// validated.
class InvoiceDecisionValidator {
  InvoiceDecisionValidator._();

  static const int maxRemarksLength = 250;

  static String? rejectRemarksErrorKey(String remarks) {
    final trimmed = remarks.trim();
    if (trimmed.isEmpty) return 'pr_remarks_required_reject';
    if (trimmed.length > maxRemarksLength) return 'pr_remarks_too_long';
    return null;
  }
}
