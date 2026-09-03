import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/core/widgets/app_drawer.dart';
import 'package:iungo/features/service_request/presentation/widgets/filter_pill_button.dart';
import 'package:iungo/features/service_request/presentation/widgets/service_request_empty_state.dart';
import 'package:iungo/features/work_order/domain/entities/pending_approval_kind.dart';
import 'package:iungo/features/work_order/presentation/bindings/pending_work_order_search_binding.dart';
import 'package:iungo/features/work_order/presentation/bindings/work_order_detail_binding.dart';
import 'package:iungo/features/work_order/presentation/controllers/pending_work_order_list_controller.dart';
import 'package:iungo/features/work_order/presentation/pages/pending_work_order_search_page.dart';
import 'package:iungo/features/work_order/presentation/pages/work_order_detail_page.dart';
import 'package:iungo/features/work_order/presentation/pages/work_order_filter_page.dart';
import 'package:iungo/features/work_order/presentation/widgets/work_order_card.dart';

/// "Awaiting for Pause Approval" / "Awaiting Approval for Closure"
/// screen. Deliberately mirrors [WorkOrderListPage]'s UI, spacing, and
/// filter flow exactly — the only difference is the data source is a
/// small local seed list (see [PendingWorkOrderListController]) instead
/// of a live API call, since the backing endpoint doesn't exist yet.
class PendingWorkOrderListPage extends StatelessWidget {
  const PendingWorkOrderListPage({super.key, required this.kind});

  final PendingApprovalKind kind;

  @override
  Widget build(BuildContext context) {
    final controller =
        Get.find<PendingWorkOrderListController>(tag: kind.tag);

    final drawerItem = kind == PendingApprovalKind.pauseApproval
        ? DrawerMenuItem.awaitingPauseApproval
        : DrawerMenuItem.awaitingClosureApproval;

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
          kind.titleKey.tr,
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
              () => PendingWorkOrderSearchPage(kind: kind),
              binding: PendingWorkOrderSearchBinding(kind),
            ),
          ),
        ],
      ),
      drawer: AppDrawer(selected: drawerItem),
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
                final workOrders = controller.filteredWorkOrders;

                if (workOrders.isEmpty) {
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
                    itemBuilder: (context, index) {
                      final workOrder = workOrders[index];
                      return WorkOrderCard(
                        workOrder: workOrder,
                        onTap: () => Get.to(
                          () => const WorkOrderDetailPage(),
                          binding: WorkOrderDetailBinding(
                            workOrder,
                            staticMode: true,
                          ),
                        )?.then((_) => controller.reload()),
                      );
                    },
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
