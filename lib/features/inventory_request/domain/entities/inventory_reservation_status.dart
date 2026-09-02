import 'package:flutter/material.dart';

/// Reservation status of an Inventory Request's line items — drives the
/// colored pill on each list card/Detail View and populates the
/// "Select Reservation Status" filter dropdown.
///
/// STATIC by requirement — never fetched from an API. The id/name pairs
/// below are fixed:
///
///   1 -> Pending
///   2 -> Partially Reserved
///   3 -> Fully Reserved
///   4 -> Partially Issued
///   5 -> Fully Issued
enum InventoryReservationStatus {
  pending,
  partiallyReserved,
  fullyReserved,
  partiallyIssued,
  fullyIssued,
}

extension InventoryReservationStatusX on InventoryReservationStatus {
  /// The fixed numeric id (as a string, matching the server's own
  /// id-as-string convention for filter/quickFilter values) used when
  /// this option is selected in the "Select Reservation Status" filter.
  String get id {
    switch (this) {
      case InventoryReservationStatus.pending:
        return '1';
      case InventoryReservationStatus.partiallyReserved:
        return '2';
      case InventoryReservationStatus.fullyReserved:
        return '3';
      case InventoryReservationStatus.partiallyIssued:
        return '4';
      case InventoryReservationStatus.fullyIssued:
        return '5';
    }
  }

  String get labelKey {
    switch (this) {
      case InventoryReservationStatus.pending:
        return 'reservation_status_pending';
      case InventoryReservationStatus.partiallyReserved:
        return 'reservation_status_partially_reserved';
      case InventoryReservationStatus.fullyReserved:
        return 'reservation_status_fully_reserved';
      case InventoryReservationStatus.partiallyIssued:
        return 'reservation_status_partially_issued';
      case InventoryReservationStatus.fullyIssued:
        return 'reservation_status_fully_issued';
    }
  }

  /// Background color of the status pill — kept in the same family as
  /// the Work Order status colors so both screens read as one design
  /// system.
  Color get color {
    switch (this) {
      case InventoryReservationStatus.pending:
        return const Color(0xFFC77A1E);
      case InventoryReservationStatus.partiallyReserved:
        return const Color(0xFF8A6FB0);
      case InventoryReservationStatus.fullyReserved:
        return const Color(0xFF3F6FA8);
      case InventoryReservationStatus.partiallyIssued:
        return const Color(0xFF3F8FA8);
      case InventoryReservationStatus.fullyIssued:
        return const Color(0xFF3D8B4E);
    }
  }

  /// Resolves a raw numeric id (as returned by/sent to the server, e.g.
  /// `"2"` or `2`) back to the matching static option — used to restore
  /// a previously-applied filter selection. Returns null for anything
  /// outside the fixed 1-5 range.
  static InventoryReservationStatus? fromId(String? id) {
    switch (id?.trim()) {
      case '1':
        return InventoryReservationStatus.pending;
      case '2':
        return InventoryReservationStatus.partiallyReserved;
      case '3':
        return InventoryReservationStatus.fullyReserved;
      case '4':
        return InventoryReservationStatus.partiallyIssued;
      case '5':
        return InventoryReservationStatus.fullyIssued;
      default:
        return null;
    }
  }

  static const List<InventoryReservationStatus> filterOptions =
      InventoryReservationStatus.values;
}
