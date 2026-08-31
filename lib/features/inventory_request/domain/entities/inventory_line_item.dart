/// One row of an Inventory Request's "Line Items" table (Detail View,
/// Overview tab) — the material/tool being requested, which store room it
/// comes from, and the requested/available/issued quantities.
class InventoryLineItem {
  const InventoryLineItem({
    required this.itemCode,
    required this.itemName,
    required this.storeRoom,
    required this.requestedQty,
    required this.availableQty,
    required this.issuedQty,
  });

  /// Item/tool code, e.g. "MIN-DR-MCH-SPR-132".
  final String itemCode;

  /// Display name, e.g. "ANGLE VALVE 1/2\"".
  final String itemName;
  final String storeRoom;
  final int requestedQty;
  final int availableQty;
  final int issuedQty;
}
