/// Everything selected on the PR Dashboard's Filter screen. Immutable —
/// the controller swaps in a new instance whenever a value changes.
/// Mirrors `InventoryRequestFilter`'s shape, with Contract in place of
/// Reservation Status.
class PurchaseRequestFilter {
  const PurchaseRequestFilter({
    this.contract,
    this.createdDateStart,
    this.createdDateEnd,
  });

  final String? contract;
  final DateTime? createdDateStart;
  final DateTime? createdDateEnd;

  bool get isEmpty =>
      contract == null && createdDateStart == null && createdDateEnd == null;

  PurchaseRequestFilter copyWith({
    String? contract,
    bool clearContract = false,
    DateTime? createdDateStart,
    DateTime? createdDateEnd,
    bool clearCreatedDate = false,
  }) {
    return PurchaseRequestFilter(
      contract: clearContract ? null : (contract ?? this.contract),
      createdDateStart:
          clearCreatedDate ? null : (createdDateStart ?? this.createdDateStart),
      createdDateEnd:
          clearCreatedDate ? null : (createdDateEnd ?? this.createdDateEnd),
    );
  }
}
