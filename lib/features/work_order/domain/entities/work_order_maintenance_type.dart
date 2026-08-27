/// Maintenance type shown with the wrench icon on each list card and in
/// the Detail View's "Other Information" block.
enum WorkOrderMaintenanceType { proactive, corrective, preventive }

extension WorkOrderMaintenanceTypeX on WorkOrderMaintenanceType {
  String get labelKey {
    switch (this) {
      case WorkOrderMaintenanceType.proactive:
        return 'maintenance_type_proactive';
      case WorkOrderMaintenanceType.corrective:
        return 'maintenance_type_corrective';
      case WorkOrderMaintenanceType.preventive:
        return 'maintenance_type_preventive';
    }
  }

  /// Maps the `type.name`/`displayName` the list/detail API returns
  /// (e.g. "Proactive") onto the fixed enum. Unknown/blank labels fall
  /// back to [corrective], the most common catch-all "type" value.
  static WorkOrderMaintenanceType fromApiLabel(String? label) {
    final normalized =
        (label ?? '').toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    switch (normalized) {
      case 'proactive':
        return WorkOrderMaintenanceType.proactive;
      case 'preventive':
        return WorkOrderMaintenanceType.preventive;
      case 'corrective':
      default:
        return WorkOrderMaintenanceType.corrective;
    }
  }
}