import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/core/widgets/app_drawer.dart';
import 'package:iungo/features/grn_request/presentation/bindings/grn_detail_binding.dart';
import 'package:iungo/features/grn_request/presentation/bindings/grn_search_binding.dart';
import 'package:iungo/features/grn_request/presentation/controllers/grn_dashboard_controller.dart';
import 'package:iungo/features/grn_request/presentation/pages/grn_detail_page.dart';
import 'package:iungo/features/grn_request/presentation/pages/grn_filter_page.dart';
import 'package:iungo/features/grn_request/presentation/pages/grn_search_page.dart';
import 'package:iungo/features/grn_request/presentation/widgets/grn_request_card.dart';
import 'package:iungo/features/purchase_request/presentation/controllers/pr_role_controller.dart';
import 'package:iungo/features/purchase_request/presentation/widgets/pr_role_switch.dart';
import 'package:iungo/features/purchase_request/presentation/widgets/pr_status_tabs.dart';
import 'package:iungo/features/service_request/presentation/widgets/filter_pill_button.dart';
import 'package:iungo/features/service_request/presentation/widgets/service_request_empty_state.dart';
import 'package:iungo/features/service_request/presentation/widgets/service_request_shimmer.dart';

/// GRN Dashboard — the three status tiles (doubling as tabs), the
/// Contract/Created-date filter, and the request list. Mirrors
/// `PrDashboardPage`'s chrome/refresh/filter/search flow exactly,
/// minus the "Add" FAB — GRN records are only ever created downstream
/// of an approved Purchase Request, never directly from this screen.
///
/// The role switch in the AppBar is the same shared [PrRoleController]
/// the PR Dashboard uses, so switching Requestor/Approver there is
/// reflected here too. Approve/Reject show inline on each card for the
/// approver role's pending ("Submitted"/"Action required") tab, in
/// addition to the Detail View's action bar.
class GrnDashboardPage extends GetView<GrnDashboardController> {
  const GrnDashboardPage({super.key});

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
          'grn_dashboard'.tr,
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
              () => const GrnSearchPage(),
              binding: GrnSearchBinding(),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(selected: DrawerMenuItem.grnDashboard),
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
                          GrnFilterPage.show(context, controller: controller),
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
                  return _GrnErrorState(onRetry: controller.reload);
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
                        // buttons. Read both reactively so toggling the
                        // dev-only role switch updates this immediately.
                        final showActions = roleController.isApprover &&
                            controller.selectedTab.value == 0;
                        return GrnRequestCard(
                          request: request,
                          onTap: () => Get.to(
                            () => const GrnDetailPage(),
                            binding: GrnDetailBinding(request),
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
class _GrnErrorState extends StatelessWidget {
  const _GrnErrorState({required this.onRetry});

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
