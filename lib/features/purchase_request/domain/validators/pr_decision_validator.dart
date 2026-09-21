/// Business rules for approving/rejecting a Purchase Request. Pure
/// functions returning a translation key (or null when valid) so the
/// rules are unit-testable and every entry point (Detail View, list
/// card) enforces exactly the same thing.
class PrDecisionValidator {
  PrDecisionValidator._();

  /// Longest remarks the Reject dialog accepts.
  static const int maxRemarksLength = 250;

  /// Approving requires EXACTLY ONE selected attachment.
  ///
  ///   * none selected     -> `pr_select_one_attachment`
  ///   * more than one     -> `pr_select_only_one_attachment`
  static String? approveSelectionErrorKey(List<String> selectedFileNames) {
    if (selectedFileNames.isEmpty) return 'pr_select_one_attachment';
    if (selectedFileNames.length > 1) return 'pr_select_only_one_attachment';
    if (selectedFileNames.first.trim().isEmpty) {
      return 'pr_select_one_attachment';
    }
    return null;
  }

  /// Rejecting requires remarks (whitespace-only doesn't count), at most
  /// [maxRemarksLength] characters.
  static String? rejectRemarksErrorKey(String remarks) {
    final trimmed = remarks.trim();
    if (trimmed.isEmpty) return 'pr_remarks_required_reject';
    if (trimmed.length > maxRemarksLength) return 'pr_remarks_too_long';
    return null;
  }
}
