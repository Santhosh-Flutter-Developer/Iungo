import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/features/service_request/presentation/controllers/service_request_detail_controller.dart';
import 'package:iungo/features/service_request/presentation/pages/add_comment_page.dart';
import 'package:iungo/features/service_request/presentation/widgets/add_attachment_sheet.dart';
import 'package:iungo/features/service_request/presentation/widgets/detail_attachments_tab.dart';
import 'package:iungo/features/service_request/presentation/widgets/detail_comments_tab.dart';
import 'package:iungo/features/service_request/presentation/widgets/detail_overview_tab.dart';

class ServiceRequestDetailPage extends GetView<ServiceRequestDetailController> {
  const ServiceRequestDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.arrow_forward
                  : Icons.arrow_back,
              color: AppColors.white,
            ),
            onPressed: () => Get.back(),
          ),
          title: Obx(
            () => Text(
              controller.request.title.isEmpty
                  ? 'detail_view'.tr
                  : controller.request.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          bottom: TabBar(
            indicatorColor: AppColors.white,
            indicatorWeight: 3,
            isScrollable: true,
            labelColor: AppColors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
            tabs: [
              Tab(text: 'overview'.tr.toUpperCase()),
              Tab(text: 'comments'.tr.toUpperCase()),
              Tab(text: 'attachments'.tr.toUpperCase()),
            ],
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (controller.errorMessage.value.isNotEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      controller.errorMessage.value,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: controller.retry,
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
          return TabBarView(
            children: [
              DetailOverviewTab(request: controller.request),
              const DetailCommentsTab(),
              const DetailAttachmentsTab(),
            ],
          );
        }),
        floatingActionButton: Builder(
          builder: (context) {
            return AnimatedBuilder(
              animation: DefaultTabController.of(context),
              builder: (context, _) {
                final index = DefaultTabController.of(context).index;
                if (index == 0) return const SizedBox.shrink();
                return FloatingActionButton(
                  heroTag: 'detail_fab',
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onPressed: () => index == 1
                      ? Get.to(() => const AddCommentPage())
                      : AddAttachmentSheet.show(
                          context,
                          onCameraTap: controller.pickAttachmentFromCamera,
                          onGalleryTap: controller.pickAttachmentFromFiles,
                        ),
                  child: const Icon(Icons.add, color: AppColors.white),
                );
              },
            );
          },
        ),
      ),
    );
  }
}