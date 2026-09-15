/// Whether a "Requested Supply Item" line is picked from the client's
/// inventory catalog or is a free-text, non-inventory material —
/// matches the "Type" dropdown on the reference "Add Purchase Request"
/// form exactly.
enum PurchaseRequestItemType { inventory, nonInventory }

extension PurchaseRequestItemTypeX on PurchaseRequestItemType {
  String get labelKey {
    switch (this) {
      case PurchaseRequestItemType.inventory:
        return 'pr_item_type_inventory';
      case PurchaseRequestItemType.nonInventory:
        return 'pr_item_type_non_inventory';
    }
  }
}

/// One row of a Purchase Request's "Requested Supply Items" — backs
/// both the Detail View's Requested Supply Items tab and the "Add
/// Items" builder on the Add Purchase Request form.
class PurchaseRequestItem {
  const PurchaseRequestItem({
    required this.type,
    this.materialCode,
    required this.materialDescription,
    this.remarks = '',
    required this.quantity,
    required this.unitPrice,
  });

  final PurchaseRequestItemType type;

  /// Only set for [PurchaseRequestItemType.inventory] items — the
  /// catalog code shown alongside the description (e.g. "MIN-DR-ELE-041").
  final String? materialCode;
  final String materialDescription;
  final String remarks;
  final double quantity;
  final double unitPrice;

  double get total => quantity * unitPrice;
}
