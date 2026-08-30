import 'package:iungo/features/work_order/domain/entities/work_order_status.dart';

/// Distinguishes the two static, not-yet-API-integrated "My Work Orders"
/// variants reachable from the "Work Order" drawer submenu — same list
/// UI, same filters, same Detail View as the real (API-backed) "All Work
/// Orders" screen, just seeded with local placeholder data for now.
enum PendingApprovalKind { pauseApproval, closureApproval }

extension PendingApprovalKindX on PendingApprovalKind {
  /// App bar title / drawer label for this variant.
  String get titleKey {
    switch (this) {
      case PendingApprovalKind.pauseApproval:
        return 'awaiting_pause_approval';
      case PendingApprovalKind.closureApproval:
        return 'awaiting_approval_closure';
    }
  }

  /// The status the seeded placeholder cards are shown in — matches the
  /// status this list will eventually be server-filtered by, once the
  /// real API is wired up.
  WorkOrderStatus get status {
    switch (this) {
      case PendingApprovalKind.pauseApproval:
        return WorkOrderStatus.awaitingPauseApprovalFromClient;
      case PendingApprovalKind.closureApproval:
        return WorkOrderStatus.awaitingClosureApprovalFromClient;
    }
  }

  /// Tag used to register/find this variant's controller instance so the
  /// two screens never share state.
  String get tag => name;
}
