/// Priority shown with the clock icon on each list card, and offered in the
/// "Select Priority" filter dropdown.
enum ServiceRequestPriority { noPriority, routine, urgent, emergency, ppm }

extension ServiceRequestPriorityX on ServiceRequestPriority {
  String get labelKey {
    switch (this) {
      case ServiceRequestPriority.noPriority:
        return 'priority_no_priority';
      case ServiceRequestPriority.routine:
        return 'priority_routine';
      case ServiceRequestPriority.urgent:
        return 'priority_urgent';
      case ServiceRequestPriority.emergency:
        return 'priority_emergency';
      case ServiceRequestPriority.ppm:
        return 'priority_ppm';
    }
  }

  /// Maps a label as returned by the server (either the ticket's expanded
  /// `priority_serviceRequest.displayName` or a
  /// `pickList/.../priority_serviceRequest` option's `label`) onto the
  /// fixed enum. Unknown/blank labels fall back to [noPriority].
  static ServiceRequestPriority fromApiLabel(String? label) {
    final normalized =
        (label ?? '').toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    switch (normalized) {
      case 'routine':
        return ServiceRequestPriority.routine;
      case 'urgent':
        return ServiceRequestPriority.urgent;
      case 'emergency':
        return ServiceRequestPriority.emergency;
      case 'ppm':
        return ServiceRequestPriority.ppm;
      default:
        return ServiceRequestPriority.noPriority;
    }
  }
}