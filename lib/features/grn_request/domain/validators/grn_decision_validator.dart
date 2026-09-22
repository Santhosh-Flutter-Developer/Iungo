/// Business rules for approving/rejecting a GRN. Pure functions
/// returning a translation key (or null when valid), mirroring
/// `PrDecisionValidator`.
class GrnDecisionValidator {
  GrnDecisionValidator._();

  static const int maxRemarksLength = 250;

  /// Approving a GRN requires AT LEAST ONE delivery note attached — any
  /// number is fine (unlike PR's exactly-one-attachment rule).
  static String? approveRequiresDeliveryNote(List<String> deliveryNoteNames) {
    final hasOne = deliveryNoteNames.any((name) => name.trim().isNotEmpty);
    return hasOne ? null : 'grn_delivery_note_required_message';
  }

  static String? rejectRemarksErrorKey(String remarks) {
    final trimmed = remarks.trim();
    if (trimmed.isEmpty) return 'pr_remarks_required_reject';
    if (trimmed.length > maxRemarksLength) return 'pr_remarks_too_long';
    return null;
  }
}
