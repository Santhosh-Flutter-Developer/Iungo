/// Priority shown with the clock icon on each list card, and offered in the
/// "Select Priority" filter dropdown.
enum ServiceRequestPriority { noPriority, routine, urgent, emergency }

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
    }
  }
}
