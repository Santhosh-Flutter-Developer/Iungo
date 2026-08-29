/// One task inside the Detail View's "Tasks" tab checklist. Backed by
/// the Tasks API (GET .../v2/tasks/parent/{id}).
class WorkOrderTask {
  const WorkOrderTask({this.id, required this.title, required this.completed});

  final int? id;
  final String title;
  final bool completed;
}
