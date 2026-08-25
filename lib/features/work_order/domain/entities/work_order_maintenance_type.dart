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
}