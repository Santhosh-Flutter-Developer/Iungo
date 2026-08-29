import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/features/work_order/presentation/controllers/work_order_detail_controller.dart';
import 'package:iungo/features/work_order/presentation/widgets/detail_attachments_tab.dart';
import 'package:iungo/features/work_order/presentation/widgets/detail_comments_tab.dart';
import 'package:iungo/features/work_order/presentation/widgets/detail_overview_tab.dart';
import 'package:iungo/features/work_order/presentation/widgets/detail_tasks_tab.dart';

class WorkOrderDetailPage extends GetView<WorkOrderDetailController> {
  const WorkOrderDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
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
          title: Text(
            'detail_view'.tr,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w500,
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
              Tab(text: 'tasks'.tr.toUpperCase()),
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
              DetailOverviewTab(
                workOrder: controller.order,
                controller: controller,
              ),
              const DetailTasksTab(),
              const DetailCommentsTab(),
              const DetailAttachmentsTab(),
            ],
          );
        }),
      ),
    );
  }
}
