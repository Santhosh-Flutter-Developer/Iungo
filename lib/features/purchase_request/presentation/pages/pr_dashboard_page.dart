import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/core/widgets/app_drawer.dart';
import 'package:iungo/features/purchase_request/presentation/bindings/pr_create_binding.dart';
import 'package:iungo/features/purchase_request/presentation/bindings/pr_detail_binding.dart';
import 'package:iungo/features/purchase_request/presentation/bindings/pr_search_binding.dart';
import 'package:iungo/features/purchase_request/presentation/controllers/pr_dashboard_controller.dart';
import 'package:iungo/features/purchase_request/presentation/controllers/pr_role_controller.dart';
import 'package:iungo/features/purchase_request/presentation/pages/pr_create_page.dart';
import 'package:iungo/features/purchase_request/presentation/pages/pr_detail_page.dart';
import 'package:iungo/features/purchase_request/presentation/pages/pr_filter_page.dart';
import 'package:iungo/features/purchase_request/presentation/pages/pr_search_page.dart';
import 'package:iungo/features/purchase_request/presentation/widgets/pr_role_switch.dart';
import 'package:iungo/features/purchase_request/presentation/widgets/pr_status_tabs.dart';
import 'package:iungo/features/purchase_request/presentation/widgets/purchase_request_card.dart';
import 'package:iungo/features/service_request/presentation/widgets/filter_pill_button.dart';
import 'package:iungo/features/service_request/presentation/widgets/service_request_empty_state.dart';
import 'package:iungo/features/service_request/presentation/widgets/service_request_shimmer.dart';

/// PR Dashboard — the three status tiles (doubling as tabs), the
/// Contract/Created-date filter, and the request list. Mirrors
/// `InventoryRequestListPage`'s chrome/refresh/filter/search flow.
///
/// The "Add" button (requestor only) and the role switch in the AppBar
/// are gated by [PrRoleController] — see [PrRoleSwitch] for why that
/// exists. Approve/Reject live on the Detail View instead of this list,
/// same split as every other approval flow in this app.
class PrDashboardPage extends GetView<PrDashboardController> {
  const PrDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final roleController = Get.find<PrRoleController>();

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
          'pr_dashboard'.tr,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          const PrRoleSwitch(),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: controller.onNotificationsTap,
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Get.to(
              () => const PrSearchPage(),
              binding: PrSearchBinding(),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(selected: DrawerMenuItem.prDashboard),
      floatingActionButton: Obx(() {
        if (!roleController.isRequestor) return const SizedBox.shrink();
        return FloatingActionButton.extended(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          icon: const Icon(Icons.add),
          label: Text('add'.tr),
          onPressed: () => Get.to(
            () => const PrCreatePage(),
            binding: PrCreateBinding(),
          )?.then((created) {
            if (created == true) controller.reload();
          }),
        );
      }),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Obx(
                () => PrStatusTabs(
                  pendingLabel: roleController.isRequestor
                      ? 'pr_status_submitted'.tr
                      : 'pr_status_action_required'.tr,
                  pendingCount: controller.pendingCount,
                  completedCount: controller.completedCount,
                  rejectedCount: controller.rejectedCount,
                  selectedIndex: controller.selectedTab.value,
                  onSelect: controller.selectTab,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: Obx(
                  () => FilterPillButton(
                    isActive: controller.hasActiveFilter,
                    onTap: () =>
                        PrFilterPage.show(context, controller: controller),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const ServiceRequestShimmerList();
                }

                if (controller.hasError.value) {
                  return _PrErrorState(onRetry: controller.reload);
                }

                final requests = controller.visibleRequests;

                if (requests.isEmpty) {
                  return const ServiceRequestEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: controller.reload,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      final request = requests[index];
                      return PurchaseRequestCard(
                        request: request,
                        onTap: () => Get.to(
                          () => const PrDetailPage(),
                          binding: PrDetailBinding(request),
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

/// Full-screen state shown when the list fails to load — matches
/// `ServiceRequestEmptyState`'s layout with a retry action.
class _PrErrorState extends StatelessWidget {
  const _PrErrorState({required this.onRetry});

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
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('retry'.tr),
            ),
          ],
        ),
      ),
    );
  }
}
