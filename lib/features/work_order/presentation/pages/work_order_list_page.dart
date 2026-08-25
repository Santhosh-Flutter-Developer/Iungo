import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/core/widgets/app_drawer.dart';
import 'package:iungo/features/service_request/presentation/widgets/filter_pill_button.dart';
import 'package:iungo/features/service_request/presentation/widgets/service_request_empty_state.dart';
import 'package:iungo/features/service_request/presentation/widgets/service_request_shimmer.dart';
import 'package:iungo/features/work_order/presentation/bindings/work_order_search_binding.dart';
import 'package:iungo/features/work_order/presentation/controllers/work_order_list_controller.dart';
import 'package:iungo/features/work_order/presentation/pages/work_order_filter_page.dart';
import 'package:iungo/features/work_order/presentation/pages/work_order_search_page.dart';
import 'package:iungo/features/work_order/presentation/widgets/work_order_card.dart';

class WorkOrderListPage extends StatelessWidget {
  const WorkOrderListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WorkOrderListController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          'my_work_orders'.tr,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: controller.onNotificationsTap,
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Get.to(
              () => const WorkOrderSearchPage(),
              binding: WorkOrderSearchBinding(),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(selected: DrawerMenuItem.myWorkOrders),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: Obx(
                  () => FilterPillButton(
                    isActive: controller.hasActiveFilter,
                    onTap: () => WorkOrderFilterPage.show(
                      context,
                      controller: controller,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const ServiceRequestShimmerList();
                }

                if (controller.hasActiveFilter &&
                    controller.isFilterLoading.value) {
                  return const ServiceRequestShimmerList();
                }

                final workOrders = controller.filteredWorkOrders;

                if (workOrders.isEmpty) {
                  final failed = controller.hasActiveFilter
                      ? controller.filterHasError.value
                      : controller.hasError.value;
                  if (failed) {
                    return _WorkOrderErrorState(
                      onRetry: controller.hasActiveFilter
                          ? controller.retryFilter
                          : controller.reload,
                    );
                  }
                  return const ServiceRequestEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: controller.hasActiveFilter
                      ? controller.retryFilter
                      : controller.reload,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: workOrders.length,
                    itemBuilder: (context, index) =>
                        WorkOrderCard(workOrder: workOrders[index]),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen state shown when the list fails to load — matches the
/// empty-state layout with a retry action instead of the filter tip.
class _WorkOrderErrorState extends StatelessWidget {
  const _WorkOrderErrorState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 96,
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 20),
            Text(
              'something_went_wrong'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('retry'.tr),
            ),
          ],
        ),
      ),
    );
  }
}