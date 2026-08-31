import 'package:iungo/features/inventory_request/domain/entities/inventory_reservation_status.dart';

/// Everything selected on the Inventory Request Filter screen. Immutable
/// — the controller swaps in a new instance whenever a value changes.
/// Mirrors [WorkOrderFilter]'s shape (Status/Reservation Status + a
/// created-date range).
class InventoryRequestFilter {
  const InventoryRequestFilter({
    this.status,
    this.reservationStatus,
    this.createdDateStart,
    this.createdDateEnd,
  });

  /// Raw ticket status, e.g. "Awaiting Client Approval" / "Fully Issued".
  final String? status;
  final InventoryReservationStatus? reservationStatus;
  final DateTime? createdDateStart;
  final DateTime? createdDateEnd;

  bool get isEmpty =>
      status == null &&
      reservationStatus == null &&
      createdDateStart == null &&
      createdDateEnd == null;

  InventoryRequestFilter copyWith({
    String? status,
    bool clearStatus = false,
    InventoryReservationStatus? reservationStatus,
    bool clearReservationStatus = false,
    DateTime? createdDateStart,
    DateTime? createdDateEnd,
    bool clearCreatedDate = false,
  }) {
    return InventoryRequestFilter(
      status: clearStatus ? null : (status ?? this.status),
      reservationStatus: clearReservationStatus
          ? null
          : (reservationStatus ?? this.reservationStatus),
      createdDateStart:
          clearCreatedDate ? null : (createdDateStart ?? this.createdDateStart),
      createdDateEnd:
          clearCreatedDate ? null : (createdDateEnd ?? this.createdDateEnd),
    );
  }
}
