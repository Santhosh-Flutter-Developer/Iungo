/// Discipline/category shown with the triangle icon on each list card —
/// e.g. "Mechanical", "Cleaning", "Pest Control".
enum WorkOrderDiscipline {
  mechanical,
  cleaning,
  pestControl,
  civil,
  electrical,
  plumbing,
  hvac,
}

extension WorkOrderDisciplineX on WorkOrderDiscipline {
  String get labelKey {
    switch (this) {
      case WorkOrderDiscipline.mechanical:
        return 'discipline_mechanical';
      case WorkOrderDiscipline.cleaning:
        return 'discipline_cleaning';
      case WorkOrderDiscipline.pestControl:
        return 'discipline_pest_control';
      case WorkOrderDiscipline.civil:
        return 'discipline_civil';
      case WorkOrderDiscipline.electrical:
        return 'discipline_electrical';
      case WorkOrderDiscipline.plumbing:
        return 'discipline_plumbing';
      case WorkOrderDiscipline.hvac:
        return 'discipline_hvac';
    }
  }
}