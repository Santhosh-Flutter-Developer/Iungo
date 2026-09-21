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
    this.materialId,
    required this.materialDescription,
    this.remarks = '',
    required this.quantity,
    required this.unitPrice,
    this.id,
    this.sno,
    this.materialTypeLabel,
    this.apiTotal,
  });

  final PurchaseRequestItemType type;

  /// The Purchase Request API's `items[].id` — only set for items that
  /// were read back from the API.
  final int? id;

  /// The API's `items[].sno` (the S.No shown against the item).
  final int? sno;

  /// The API's raw `items[].material_type` (e.g. "Inventory"). [type] is
  /// derived from it; the raw text is kept so a type this app doesn't
  /// know about can still be shown as the badge.
  final String? materialTypeLabel;

  /// The API's own `items[].total`. When present it wins over
  /// `quantity * unitPrice` so the screen shows exactly what the server
  /// calculated.
  final double? apiTotal;

  /// Only set for [PurchaseRequestItemType.inventory] items — the
  /// catalog code shown alongside the description (e.g. "MIN-DR-ELE-041").
  final String? materialCode;

  /// Facilio inventory record id of the picked material — sent as `ids`
  /// on save. Only set for [PurchaseRequestItemType.inventory] items
  /// created through the Add Purchase Request form.
  final int? materialId;
  final String materialDescription;
  final String remarks;
  final double quantity;
  final double unitPrice;

  double get total => apiTotal ?? quantity * unitPrice;
}
