import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/features/inventory_request/presentation/controllers/inventory_request_detail_controller.dart';

/// Mirrors [DetailCommentsTab] (Work Order) exactly — no backing API for
/// Inventory Request yet, so this renders the existing empty state.
class InventoryRequestDetailCommentsTab
    extends GetView<InventoryRequestDetailController> {
  const InventoryRequestDetailCommentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingComments.value) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      }

      if (controller.commentsError.value.isNotEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  controller.commentsError.value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, color: AppColors.textDark),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.retryComments,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                  ),
                  child: Text('retry'.tr),
                ),
              ],
            ),
          ),
        );
      }

      final comments = controller.comments;
      if (comments.isEmpty) {
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: controller.retryComments,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 120),
            children: [
              Text(
                'no_comments_found'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: AppColors.textMuted),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: controller.retryComments,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
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
        ),
      );
    });
  }
}
