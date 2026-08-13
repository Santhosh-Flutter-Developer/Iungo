import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/core/widgets/app_drawer.dart';
import 'package:iungo/features/service_request/presentation/controllers/service_request_list_controller.dart';
import 'package:iungo/features/service_request/presentation/pages/service_request_filter_page.dart';
import 'package:iungo/features/service_request/presentation/widgets/create_service_request_sheet.dart';
import 'package:iungo/features/service_request/presentation/widgets/filter_pill_button.dart';
import 'package:iungo/features/service_request/presentation/widgets/service_request_card.dart';
import 'package:iungo/features/service_request/presentation/widgets/service_request_empty_state.dart';
import 'package:iungo/features/service_request/presentation/widgets/service_request_shimmer.dart';

class ServiceRequestListPage extends GetView<ServiceRequestListController> {
  const ServiceRequestListPage({super.key});

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
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      drawer: const AppDrawer(selected: DrawerMenuItem.myServiceRequests),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                final tickets = controller.filteredTickets;
                if (tickets.isEmpty) {
                  return const ServiceRequestEmptyState();
                }
                return RefreshIndicator(
                  onRefresh: controller.reload,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: tickets.length,
                    itemBuilder: (context, index) =>
                        ServiceRequestCard(request: tickets[index]),
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
