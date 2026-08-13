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
      final comments = controller.comments;
      if (comments.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'add_comments_hint'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textDark,
              ),
            ),
          ),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        itemCount: comments.length,
        itemBuilder: (context, index) => CommentTile(comment: comments[index]),
      );
    });
  }
}
