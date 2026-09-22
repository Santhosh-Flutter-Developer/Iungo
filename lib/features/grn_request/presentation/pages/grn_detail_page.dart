import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/features/grn_request/presentation/controllers/grn_detail_controller.dart';
import 'package:iungo/features/grn_request/presentation/widgets/grn_approval_action_bar.dart';
import 'package:iungo/features/grn_request/presentation/widgets/grn_delivery_notes_tab.dart';
import 'package:iungo/features/grn_request/presentation/widgets/grn_summary_tab.dart';
import 'package:iungo/features/grn_request/presentation/widgets/grn_supply_items_tab.dart';
import 'package:iungo/features/purchase_request/presentation/widgets/purchase_request_status_badge.dart';

/// Detail View for one GRN Request — "Summary" / "Requested Supply
/// Items" / "GRN" tabs, matching the reference screenshots exactly.
/// Mirrors `PrDetailPage`'s chrome, with the extra "GRN" tab (delivery
/// notes) appended. The Approve/Reject bar (only visible to the
/// Approver role, see [GrnApprovalActionBar]) sits as the bottom
/// navigation bar, same as the PR Detail View.
class GrnDetailPage extends GetView<GrnDetailController> {
  const GrnDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
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
              controller.grn.prNumber,
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
                  () =>
                      PurchaseRequestStatusBadge(status: controller.grn.status),
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
              Tab(text: 'pr_grn'.tr.toUpperCase()),
            ],
          ),
        ),
        body: Obx(
          () => TabBarView(
            children: [
              GrnSummaryTab(request: controller.grn),
              GrnSupplyItemsTab(request: controller.grn),
              GrnDeliveryNotesTab(request: controller.grn),
            ],
          ),
        ),
        bottomNavigationBar: const GrnApprovalActionBar(),
      ),
    );
  }
}
