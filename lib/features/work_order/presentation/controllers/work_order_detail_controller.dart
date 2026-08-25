import 'dart:async';

import 'package:get/get.dart';
import 'package:iungo/features/work_order/domain/entities/work_order.dart';

class WorkOrderDetailController extends GetxController {
  WorkOrderDetailController(this.workOrder);

  final WorkOrder workOrder;

  /// Live "Due: HH:MM:SS" (or "-HH:MM:SS" once overdue) — matches the
  /// ticking countdown pill visible in the reference Detail View.
  final RxString dueCountdown = ''.obs;

  Timer? _ticker;

  @override
  void onInit() {
    super.onInit();
    _updateCountdown();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _updateCountdown());
  }

  void _updateCountdown() {
    final now = DateTime.now();
    var remaining = workOrder.dueDate.difference(now);
    final overdue = remaining.isNegative;
    if (overdue) remaining = -remaining;

    final totalHours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    final seconds = remaining.inSeconds.remainder(60);

    String two(int n) => n.toString().padLeft(2, '0');
    dueCountdown.value =
        '${overdue ? '-' : ''}${two(totalHours)}:${two(minutes)}:${two(seconds)}';
  }

  @override
  void onClose() {
    _ticker?.cancel();
    super.onClose();
  }
}