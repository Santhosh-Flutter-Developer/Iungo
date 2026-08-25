import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/features/service_request/presentation/controllers/service_request_detail_controller.dart';

class AddCommentPage extends GetView<ServiceRequestDetailController> {
  const AddCommentPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textController = TextEditingController();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.white),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'add_comment'.tr,
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          Obx(() {
            if (controller.isPostingComment.value) {
              return const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.white,
                  ),
                ),
              );
            }
            return IconButton(
              icon: const Icon(Icons.check, color: AppColors.white),
              onPressed: () async {
                // Only close on a confirmed post — a failed request keeps
                // the draft on screen (with an error snackbar) instead of
                // silently losing what was typed.
                final success = await controller.addComment(
                  textController.text,
                );
                if (success) Get.back();
              },
            );
          }),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Obx(
            () => TextField(
              controller: textController,
              autofocus: true,
              enabled: !controller.isPostingComment.value,
              minLines: 1,
              maxLines: 12,
              style: const TextStyle(fontSize: 16, color: AppColors.textDark),
              decoration: InputDecoration(
                hintText: 'enter_your_comment'.tr,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
