import 'package:flutter/material.dart';

/// Lifecycle state of one Purchase Request. Mirrors the three summary
/// tiles at the top of the PR Dashboard reference video (Action
/// required/Submitted, Completed, Rejected) — "pending" backs both the
/// approver's "Action required" tile and the requestor's "Submitted"
/// tile, since it's the same underlying state just labelled from each
/// role's point of view (see [PrDashboardController]).
enum PurchaseRequestStatus { pending, approved, rejected }

extension PurchaseRequestStatusX on PurchaseRequestStatus {
  String get labelKey {
    switch (this) {
      case PurchaseRequestStatus.pending:
        return 'pr_status_pending';
      case PurchaseRequestStatus.approved:
        return 'pr_status_approved';
      case PurchaseRequestStatus.rejected:
        return 'pr_status_rejected';
    }
  }

  /// Badge color — orange (in progress) / green (approved) / red
  /// (rejected), matching the rest of the app's status badges
  /// (see `InventoryRequestStatusBadge`).
  Color get color {
    switch (this) {
      case PurchaseRequestStatus.pending:
        return const Color(0xFFC77A1E);
      case PurchaseRequestStatus.approved:
        return const Color(0xFF3D8B4E);
      case PurchaseRequestStatus.rejected:
        return const Color(0xFFB3261E);
    }
  }
}
