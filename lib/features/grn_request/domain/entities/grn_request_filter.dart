/// Everything selected on the GRN Dashboard's Filter screen. Immutable —
/// the controller swaps in a new instance whenever a value changes.
/// Mirrors `PurchaseRequestFilter`'s shape exactly.
class GrnRequestFilter {
  const GrnRequestFilter({
    this.contract,
    this.createdDateStart,
    this.createdDateEnd,
  });

  final String? contract;
  final DateTime? createdDateStart;
  final DateTime? createdDateEnd;

  bool get isEmpty =>
      contract == null && createdDateStart == null && createdDateEnd == null;

  GrnRequestFilter copyWith({
    String? contract,
    bool clearContract = false,
    DateTime? createdDateStart,
    DateTime? createdDateEnd,
    bool clearCreatedDate = false,
  }) {
    return GrnRequestFilter(
      contract: clearContract ? null : (contract ?? this.contract),
      createdDateStart:
          clearCreatedDate ? null : (createdDateStart ?? this.createdDateStart),
      createdDateEnd:
          clearCreatedDate ? null : (createdDateEnd ?? this.createdDateEnd),
    );
  }
}
