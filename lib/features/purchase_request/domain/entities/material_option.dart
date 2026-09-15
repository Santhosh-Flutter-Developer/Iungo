/// One entry in the "Material Code" picklist shown when adding an
/// Inventory-type supply item — selecting one auto-fills the material
/// description and unit price, matching the reference "Add Purchase
/// Request" form.
class MaterialOption {
  const MaterialOption({
    required this.code,
    required this.description,
    required this.unitPrice,
  });

  final String code;
  final String description;
  final double unitPrice;

  String get displayLabel => '$description ($code)';
}
