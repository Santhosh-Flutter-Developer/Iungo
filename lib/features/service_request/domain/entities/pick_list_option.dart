/// One `{label, value}` entry from a Facilio `pickList` API — used to
/// populate the Status and Priority filter dropdowns from the live
/// server list rather than a hardcoded set.
class PickListOption {
  const PickListOption({required this.value, required this.label});

  /// The numeric id Facilio uses to identify this option (e.g. the
  /// `moduleState`/`priority_serviceRequest` id).
  final int value;

  /// Display label as returned by the server (e.g. "Awaiting Approval").
  final String label;

  factory PickListOption.fromJson(Map<String, dynamic> json) {
    return PickListOption(
      value: (json['value'] as num?)?.toInt() ?? 0,
      label: (json['label'] as String?)?.trim() ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PickListOption && other.value == value;

  @override
  int get hashCode => value.hashCode;
}