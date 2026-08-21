import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/core/widgets/app_drawer.dart';
import 'package:iungo/features/service_request/presentation/bindings/ticket_search_binding.dart';
import 'package:iungo/features/service_request/presentation/controllers/service_request_list_controller.dart';
import 'package:iungo/features/service_request/presentation/pages/service_request_filter_page.dart';
import 'package:iungo/features/service_request/presentation/pages/ticket_search_page.dart';
import 'package:iungo/features/service_request/presentation/widgets/create_service_request_sheet.dart';
import 'package:iungo/features/service_request/presentation/widgets/filter_pill_button.dart';
import 'package:iungo/features/service_request/presentation/widgets/service_request_card.dart';
import 'package:iungo/features/service_request/presentation/widgets/service_request_empty_state.dart';
import 'package:iungo/features/service_request/presentation/widgets/service_request_shimmer.dart';

class ServiceRequestListPage extends StatefulWidget {
  const ServiceRequestListPage({super.key});

  @override
  State<ServiceRequestListPage> createState() =>
      _ServiceRequestListPageState();
}

class _ServiceRequestListPageState extends State<ServiceRequestListPage> {
  final ServiceRequestListController controller =
      Get.find<ServiceRequestListController>();

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
          'my_service_requests'.tr,
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
              () => const TicketSearchPage(),
              binding: TicketSearchBinding(),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(selected: DrawerMenuItem.myServiceRequests),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onPressed: () {
          CreateServiceRequestSheet.show(context);
          //   Get.to(
          //   () => const NewServiceRequestPage(),
          //   binding: NewServiceRequestBinding(),
          // );
        },
        child: const Icon(Icons.add, color: AppColors.white),
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
                    onTap: () => ServiceRequestFilterPage.show(
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

                final tickets = controller.filteredTickets;

                if (tickets.isEmpty) {
                  final failed = controller.hasActiveFilter
                      ? controller.filterHasError.value
                      : controller.hasError.value;
                  if (failed) {
                    return _ServiceRequestErrorState(
                      onRetry: controller.hasActiveFilter
                          ? controller.retryFilter
                          : controller.reload,
                    );
                  }
                  return const ServiceRequestEmptyState();
                }

                // Infinite scroll only drives the base (unfiltered) list —
                // a trailing spinner only makes sense while it's active.
                final showLoadMoreSpinner =
                    controller.isLoadingMore.value &&
                    !controller.hasActiveFilter;
                final itemCount = tickets.length + (showLoadMoreSpinner ? 1 : 0);

                return RefreshIndicator(
                  onRefresh: controller.hasActiveFilter
                      ? controller.retryFilter
                      : controller.reload,
                  color: AppColors.primary,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: itemCount,
                    itemBuilder: (context, index) {
                      if (index >= tickets.length) {
                        return const _LoadMoreSpinner();
                      }
                      return ServiceRequestCard(request: tickets[index]);
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
/// page of 10 is being fetched.
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
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

/// Full-screen state shown when the first page fails to load — matches
/// the empty-state layout with a retry action instead of the filter tip.
class _ServiceRequestErrorState extends StatelessWidget {
  const _ServiceRequestErrorState({required this.onRetry});

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