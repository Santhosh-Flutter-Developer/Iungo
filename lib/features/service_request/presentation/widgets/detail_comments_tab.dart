import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/features/service_request/presentation/controllers/service_request_detail_controller.dart';
import 'package:iungo/features/service_request/presentation/widgets/comment_tile.dart';

class DetailCommentsTab extends GetView<ServiceRequestDetailController> {
  const DetailCommentsTab({super.key});

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
                'add_comments_hint'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: AppColors.textDark),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: controller.retryComments,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          itemCount: comments.length,
          itemBuilder: (context, index) => CommentTile(comment: comments[index]),
        ),
      );
    });
  }
}
