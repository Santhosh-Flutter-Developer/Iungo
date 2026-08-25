import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/features/work_order/domain/entities/work_order_comment.dart';

class DetailCommentsTab extends StatelessWidget {
  const DetailCommentsTab({super.key, required this.comments});

  final List<WorkOrderComment> comments;

  @override
  Widget build(BuildContext context) {
    if (comments.isEmpty) {
      return Center(
        child: Text(
          'no_comments_found'.tr,
          style: const TextStyle(fontSize: 16, color: AppColors.textMuted),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      itemCount: comments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 18),
      itemBuilder: (context, index) {
        final comment = comments[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  comment.author,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  comment.dateLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              comment.message,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.headingBlueGrey,
                height: 1.4,
              ),
            ),
          ],
        );
      },
    );
  }
}