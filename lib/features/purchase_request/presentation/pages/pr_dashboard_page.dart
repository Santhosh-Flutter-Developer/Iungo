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
/// The "Add" button shows only for the requestor role
/// ([PrRoleController], derived from the login response's
/// `add_purchase_request` flag — there is no in-app role picker) AND only
/// when the list API itself reports `add_purchase_request == 1`.
/// Approve/Reject also show inline on each card for the approver role's
/// Action Required tab (see [PurchaseRequestCard]), in addition to the
/// Detail View's action bar.
///
/// The list is lazy-loaded: scrolling near the bottom fetches the next
/// page (see [PrDashboardController.loadMore]) and pull-to-refresh
/// reloads page 1.
class PrDashboardPage extends GetView<PrDashboardController> {
  const PrDashboardPage({super.key});

  /// How close to the bottom (in pixels) the user has to scroll before
  /// the next page is requested.
  static const double _loadMoreThreshold = 240;

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
        // Never for an approver; for a requestor only when the API says so.
        if (!roleController.isRequestor ||
            !controller.canAddPurchaseRequest.value) {
          return const SizedBox.shrink();
        }
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
                  pendingCount: controller.pendingCount.value,
                  completedCount: controller.completedCount.value,
                  rejectedCount: controller.rejectedCount.value,
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
                  return _PrErrorState(
                    message: controller.errorMessage.value,
                    onRetry: controller.reload,
                  );
                }

                final requests = controller.records.toList();

                if (requests.isEmpty) {
                  // Still pull-to-refreshable so an empty list can be
                  // re-checked.
                  return LayoutBuilder(
                    builder: (context, constraints) => RefreshIndicator(
                      onRefresh: controller.refreshList,
                      color: AppColors.primary,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: constraints.maxHeight,
                          child: const ServiceRequestEmptyState(),
                        ),
                      ),
                    ),
                  );
                }

                // A footer row (spinner, or Retry after a failed page)
                // sits after the last card while more pages exist.
                final showFooter = controller.isLoadingMore.value ||
                    controller.loadMoreFailed.value;

                return RefreshIndicator(
                  onRefresh: controller.refreshList,
                  color: AppColors.primary,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      // Near the bottom -> next page. loadMore() ignores
                      // the call while a page is already loading, so
                      // repeated scroll ticks can't fire duplicates.
                      if (notification.metrics.axis == Axis.vertical &&
                          notification.metrics.extentAfter <
                              _loadMoreThreshold) {
                        controller.loadMore();
                      }
                      return false;
                    },
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: requests.length + (showFooter ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= requests.length) {
                          return _LoadMoreFooter(
                            failed: controller.loadMoreFailed.value,
                            onRetry: controller.retryLoadMore,
                          );
                        }

                        final request = requests[index];
                        return Obx(() {
                          // Approve/Reject only ever show for the
                          // approver role's Action Required tab (index
                          // 0) on a request that is still actionable —
                          // never for the requestor, and never on the
                          // Completed/Rejected tabs. Read both reactively
                          // so a change in the session's role updates
                          // this immediately.
                          final showActions = roleController.isApprover &&
                              controller.selectedTab.value == 0 &&
                              request.isActionable;
                          return PurchaseRequestCard(
                            request: request,
                            onTap: () => Get.to(
                              () => const PrDetailPage(),
                              binding: PrDetailBinding(
                                request,
                                canDecide: controller.isActionRequiredTab,
                              ),
                            )?.then((result) {
                              // The request was approved/rejected on the
                              // detail screen -> reload from the server.
                              if (result == true) controller.reload();
                            }),
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
  const _PrErrorState({required this.message, required this.onRetry});

  /// The API's/translated failure message; falls back to the generic
  /// "Unable to load purchase requests" text when empty.
  final String message;
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
              message.isEmpty ? 'pr_load_failed'.tr : message,
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

/// The row after the last card while the next page loads (spinner) or
/// after it failed (Retry).
class _LoadMoreFooter extends StatelessWidget {
  const _LoadMoreFooter({required this.failed, required this.onRetry});

  final bool failed;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: failed
            ? TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, color: AppColors.primary),
                label: Text(
                  'retry'.tr,
                  style: const TextStyle(color: AppColors.primary),
                ),
              )
            : const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primary,
                ),
              ),
      ),
    );
  }
}
