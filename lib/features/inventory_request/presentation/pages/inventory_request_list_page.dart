import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/core/widgets/app_drawer.dart';
import 'package:iungo/features/inventory_request/presentation/bindings/inventory_request_detail_binding.dart';
import 'package:iungo/features/inventory_request/presentation/bindings/inventory_request_search_binding.dart';
import 'package:iungo/features/inventory_request/presentation/controllers/inventory_request_list_controller.dart';
import 'package:iungo/features/inventory_request/presentation/pages/inventory_request_detail_page.dart';
import 'package:iungo/features/inventory_request/presentation/pages/inventory_request_filter_page.dart';
import 'package:iungo/features/inventory_request/presentation/pages/inventory_request_search_page.dart';
import 'package:iungo/features/inventory_request/presentation/widgets/inventory_request_card.dart';
import 'package:iungo/features/service_request/presentation/widgets/filter_pill_button.dart';
import 'package:iungo/features/service_request/presentation/widgets/service_request_empty_state.dart';

/// "Inventory Request → Awaiting Client Approval" screen. Deliberately
/// mirrors [WorkOrderListPage] / [PendingWorkOrderListPage]'s UI,
/// spacing, and filter flow exactly — the only difference is the data
/// source is a small local seed list instead of a live API call, since
/// the backing endpoint doesn't exist yet.
class InventoryRequestListPage extends GetView<InventoryRequestListController> {
  const InventoryRequestListPage({super.key});

  @override
  Widget build(BuildContext context) {
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
          'awaiting_client_approval'.tr,
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
              () => const InventoryRequestSearchPage(),
              binding: InventoryRequestSearchBinding(),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(
        selected: DrawerMenuItem.inventoryRequestAwaitingClientApproval,
      ),
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
                    onTap: () => InventoryRequestFilterPage.show(
                      context,
                      controller: controller,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                final requests = controller.filteredRequests;

                if (requests.isEmpty) {
                  return const ServiceRequestEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: controller.hasActiveFilter
                      ? controller.retryFilter
                      : controller.reload,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      final request = requests[index];
                      return InventoryRequestCard(
                        request: request,
                        onTap: () => Get.to(
                          () => const InventoryRequestDetailPage(),
                          binding: InventoryRequestDetailBinding(request),
                        ),
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
