import 'package:iungo/features/inventory_request/domain/entities/inventory_reservation_status.dart';

/// Everything selected on the Inventory Request Filter screen. Immutable
/// — the controller swaps in a new instance whenever a value changes.
/// Mirrors [WorkOrderFilter]'s shape (Reservation Status + a created-date
/// range, since there is no "priority" concept here).
class InventoryRequestFilter {
  const InventoryRequestFilter({
    this.reservationStatus,
    this.isSparePartRequest,
    this.createdDateStart,
    this.createdDateEnd,
  });

  final InventoryReservationStatus? reservationStatus;
  final bool? isSparePartRequest;
  final DateTime? createdDateStart;
  final DateTime? createdDateEnd;

  bool get isEmpty =>
      reservationStatus == null &&
      isSparePartRequest == null &&
      createdDateStart == null &&
      createdDateEnd == null;

  InventoryRequestFilter copyWith({
    InventoryReservationStatus? reservationStatus,
    bool clearReservationStatus = false,
    bool? isSparePartRequest,
    bool clearIsSparePartRequest = false,
    DateTime? createdDateStart,
    DateTime? createdDateEnd,
    bool clearCreatedDate = false,
  }) {
    return InventoryRequestFilter(
      reservationStatus: clearReservationStatus
          ? null
          : (reservationStatus ?? this.reservationStatus),
      isSparePartRequest: clearIsSparePartRequest
          ? null
          : (isSparePartRequest ?? this.isSparePartRequest),
      createdDateStart:
          clearCreatedDate ? null : (createdDateStart ?? this.createdDateStart),
      createdDateEnd:
          clearCreatedDate ? null : (createdDateEnd ?? this.createdDateEnd),
    );
  }
}
