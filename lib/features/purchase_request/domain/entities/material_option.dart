/// One entry in the "Material Code" dropdown shown when adding an
/// Inventory-type supply item — sourced from the Facilio
/// `inventoryrequest` list (only `id`, `name`, `description` are read).
///
/// The dropdown displays [name]; on save, [name] is sent as
/// `material_code`, [description] as `material_desc` and [id] as `ids`.
class MaterialOption {
  const MaterialOption({
    required this.id,
    required this.name,
    required this.description,
  });

  final int id;
  final String name;
  final String description;

  String get displayLabel => name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is MaterialOption && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
