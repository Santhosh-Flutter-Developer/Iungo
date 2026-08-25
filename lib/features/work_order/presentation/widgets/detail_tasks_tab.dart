import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/features/work_order/domain/entities/work_order_task.dart';

class DetailTasksTab extends StatelessWidget {
  const DetailTasksTab({
    super.key,
    required this.completed,
    required this.total,
    required this.tasks,
  });

  final int completed;
  final int total;
  final List<WorkOrderTask> tasks;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : completed / total;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'completed'.tr.toUpperCase(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
                letterSpacing: 0.4,
              ),
            ),
            Text(
              '$completed/$total',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppColors.divider,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
        const SizedBox(height: 24),
        const Divider(color: AppColors.divider, height: 1),
        const SizedBox(height: 24),
        Text(
          'all_tasks'.tr,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.textMuted,
          ),
        ),
        if (tasks.isNotEmpty) ...[
          const SizedBox(height: 20),
          for (final task in tasks) _TaskRow(task: task),
        ],
      ],
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task});

  final WorkOrderTask task;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            task.completed
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
            size: 20,
            color: task.completed ? AppColors.primary : AppColors.textMuted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              task.title,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textDark,
                decoration:
                    task.completed ? TextDecoration.lineThrough : null,
                decorationColor: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}