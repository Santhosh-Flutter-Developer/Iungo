import 'package:flutter/material.dart';

/// Reservation status of an Inventory Request's line items — drives the
/// colored pill on each list card/Detail View and populates the
/// "Select Reservation Status" filter dropdown. Matches the "Reservation
/// Status" column in the reference screenshots (Pending / Fully Issued).
enum InventoryReservationStatus {
  pending,
  partiallyIssued,
  fullyIssued,
  rejected,
}

extension InventoryReservationStatusX on InventoryReservationStatus {
  String get labelKey {
    switch (this) {
      case InventoryReservationStatus.pending:
        return 'reservation_status_pending';
      case InventoryReservationStatus.partiallyIssued:
        return 'reservation_status_partially_issued';
      case InventoryReservationStatus.fullyIssued:
        return 'reservation_status_fully_issued';
      case InventoryReservationStatus.rejected:
        return 'reservation_status_rejected';
    }
  }

  /// Background color of the status pill — kept in the same family as
  /// the Work Order status colors so both screens read as one design
  /// system.
  Color get color {
    switch (this) {
      case InventoryReservationStatus.pending:
        return const Color(0xFFC77A1E);
      case InventoryReservationStatus.partiallyIssued:
        return const Color(0xFF3F6FA8);
      case InventoryReservationStatus.fullyIssued:
        return const Color(0xFF3D8B4E);
      case InventoryReservationStatus.rejected:
        return const Color(0xFFB3261E);
    }
  }

  static const List<InventoryReservationStatus> filterOptions =
      InventoryReservationStatus.values;
}
