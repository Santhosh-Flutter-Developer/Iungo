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
import 'package:iungo/features/purchase_request/presentation/widgets/pr_status_tabs.dart';
import 'package:iungo/features/purchase_request/presentation/widgets/purchase_request_card.dart';
import 'package:iungo/features/service_request/presentation/widgets/filter_pill_button.dart';
import 'package:iungo/features/service_request/presentation/widgets/service_request_empty_state.dart';
import 'package:iungo/features/service_request/presentation/widgets/service_request_shimmer.dart';

/// PR Dashboard — the three status tiles (doubling as tabs), the
/// Contract/Created-date filter, and the request list. Mirrors
/// `InventoryRequestListPage`'s chrome/refresh/filter/search flow.
///
/// The "Add" button (requestor only) is gated by [PrRoleController],
/// which derives the role from the login response's
/// `add_purchase_request` flag (1 = Requestor, 0 = Approver) — there is
/// no in-app role picker. Approve/Reject also show inline on each card for the
/// approver role's pending tab (see [PurchaseRequestCard]), in addition
/// to the Detail View's action bar.
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Obx(
                    () => _ExportButton(
                      isLoading: controller.isExporting.value,
                      onTap: controller.exportToExcel,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Obx(
                    () => FilterPillButton(
                      isActive: controller.hasActiveFilter,
                      onTap: () =>
                          PrFilterPage.show(context, controller: controller),
                    ),
                  ),
                ],
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
                      return Obx(() {
                        // Approve/Reject only ever show for the
                        // approver role's pending tab (index 0) — the
                        // requestor's "Submitted" tab and the
                        // Completed/Rejected tabs never get the
                        // buttons. Read both reactively so a change in
                        // the session's role updates this immediately.
                        final showActions = roleController.isApprover &&
                            controller.selectedTab.value == 0;
                        return PurchaseRequestCard(
                          request: request,
                          onTap: () => Get.to(
                            () => const PrDetailPage(),
                            binding: PrDetailBinding(request),
                          )?.then((_) => controller.reload()),
                          showApprovalActions: showActions,
                          isSubmitting: controller.isSubmitting(request.id),
                          onApprove: () =>
                              controller.approveFromList(context, request),
                          onReject: () =>
                              controller.rejectFromList(context, request),
                        );
                      });
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

/// The round "export to Excel" button shown beside the Filter pill —
/// mirrors the export icon above the table in the reference web app.
class _ExportButton extends StatelessWidget {
  const _ExportButton({required this.isLoading, required this.onTap});

  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            else
              const Icon(Icons.file_download_outlined,
                  size: 17, color: AppColors.headingBlueGrey),
            const SizedBox(width: 6),
            Text(
              'export_excel'.tr,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.headingBlueGrey,
              ),
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
