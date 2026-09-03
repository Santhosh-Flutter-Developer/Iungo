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
import 'package:iungo/features/service_request/presentation/widgets/service_request_shimmer.dart';

/// "Inventory Request → Awaiting Client Approval" screen. Deliberately
/// mirrors [WorkOrderClosureApprovalListPage]'s UI, spacing, pagination,
/// search, filter, and refresh flow exactly — backed by the live
/// `awaitingclientapproval_1` view API via [InventoryRequestListController].
class InventoryRequestListPage extends StatefulWidget {
  const InventoryRequestListPage({super.key});

  @override
  State<InventoryRequestListPage> createState() =>
      _InventoryRequestListPageState();
}

class _InventoryRequestListPageState extends State<InventoryRequestListPage> {
  final InventoryRequestListController controller =
      Get.find<InventoryRequestListController>();

  final ScrollController _scrollController = ScrollController();

  /// How close to the bottom (in pixels) the user has to scroll before
  /// the next page is requested.
  static const double _loadMoreThreshold = 240;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      controller.loadMore();
    }
  }

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
                if (controller.isLoading.value) {
                  return const ServiceRequestShimmerList();
                }

                if (controller.hasActiveFilter &&
                    controller.isFilterLoading.value) {
                  return const ServiceRequestShimmerList();
                }

                final requests = controller.filteredInventoryRequests;

                if (requests.isEmpty) {
                  final failed = controller.hasActiveFilter
                      ? controller.filterHasError.value
                      : controller.hasError.value;
                  if (failed) {
                    return _InventoryRequestErrorState(
                      onRetry: controller.hasActiveFilter
                          ? controller.retryFilter
                          : controller.reload,
                    );
                  }
                  return const ServiceRequestEmptyState();
                }

                // Infinite scroll only drives the base (unfiltered) list —
                // a trailing spinner only makes sense while it's active.
                final showLoadMoreSpinner = controller.isLoadingMore.value &&
                    !controller.hasActiveFilter;
                final itemCount =
                    requests.length + (showLoadMoreSpinner ? 1 : 0);

                return RefreshIndicator(
                  onRefresh: controller.hasActiveFilter
                      ? controller.retryFilter
                      : controller.reload,
                  color: AppColors.primary,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: itemCount,
                    itemBuilder: (context, index) {
                      if (index >= requests.length) {
                        return const _LoadMoreSpinner();
                      }
                      final request = requests[index];
                      return InventoryRequestCard(
                        request: request,
                        onTap: () => Get.to(
                          () => const InventoryRequestDetailPage(),
                          binding: InventoryRequestDetailBinding(request),
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

/// Small centered spinner appended below the last card while the next
/// page is being fetched.
class _LoadMoreSpinner extends StatelessWidget {
  const _LoadMoreSpinner();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child:
              CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
        ),
      ),
    );
  }
}

/// Full-screen state shown when the list fails to load — matches the
/// empty-state layout with a retry action instead of the filter tip.
class _InventoryRequestErrorState extends StatelessWidget {
  const _InventoryRequestErrorState({required this.onRetry});

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
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('retry'.tr),
            ),
          ],
        ),
      ),
    );
  }
}
