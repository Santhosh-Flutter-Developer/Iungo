import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/features/purchase_request/presentation/controllers/pr_detail_controller.dart';
import 'package:iungo/features/purchase_request/presentation/widgets/pr_approval_action_bar.dart';
import 'package:iungo/features/purchase_request/presentation/widgets/pr_summary_tab.dart';
import 'package:iungo/features/purchase_request/presentation/widgets/pr_supply_items_tab.dart';
import 'package:iungo/features/purchase_request/presentation/widgets/purchase_request_status_badge.dart';

/// Detail View for one Purchase Request — "Summary" / "Requested Supply
/// Items" tabs, matching the reference video exactly. Same AppBar/TabBar
/// chrome as `InventoryRequestDetailPage`. The Approve/Reject bar (only
/// visible to the Approver role, see [PrApprovalActionBar]) sits as the
/// bottom navigation bar, same as Inventory Request's Detail View.
class PrDetailPage extends GetView<PrDetailController> {
  const PrDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.arrow_forward
                  : Icons.arrow_back,
              color: AppColors.white,
            ),
            onPressed: () => Get.back(),
          ),
          title: Obx(
            () => Text(
              controller.pr.prNumber,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Obx(
                  () => PurchaseRequestStatusBadge(status: controller.pr.status),
                ),
              ),
            ),
          ],
          bottom: TabBar(
            indicatorColor: AppColors.white,
            indicatorWeight: 3,
            isScrollable: true,
            labelColor: AppColors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
            tabs: [
              Tab(text: 'pr_summary'.tr.toUpperCase()),
              Tab(text: 'pr_requested_supply_items'.tr.toUpperCase()),
            ],
          ),
        ),
        body: Obx(
          () => TabBarView(
            children: [
              PrSummaryTab(request: controller.pr),
              PrSupplyItemsTab(request: controller.pr),
            ],
          ),
        ),
        bottomNavigationBar: const PrApprovalActionBar(),
      ),
    );
  }
}
