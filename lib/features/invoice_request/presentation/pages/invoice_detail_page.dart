import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/features/invoice_request/presentation/controllers/invoice_detail_controller.dart';
import 'package:iungo/features/invoice_request/presentation/widgets/invoice_approval_action_bar.dart';
import 'package:iungo/features/invoice_request/presentation/widgets/invoice_grn_tab.dart';
import 'package:iungo/features/invoice_request/presentation/widgets/invoice_invoice_tab.dart';
import 'package:iungo/features/invoice_request/presentation/widgets/invoice_summary_tab.dart';
import 'package:iungo/features/invoice_request/presentation/widgets/invoice_supply_items_tab.dart';
import 'package:iungo/features/purchase_request/presentation/widgets/purchase_request_status_badge.dart';

/// Detail View for one Invoice Request — "Summary" / "Requested Supply
/// Items" / "GRN" / "Invoice" tabs, matching the reference screenshots
/// exactly. Mirrors `GrnDetailPage`'s chrome, with the extra "Invoice"
/// tab (invoice attachment) appended after "GRN". The Approve/Reject
/// bar (only visible to the Approver role, see
/// [InvoiceApprovalActionBar]) sits as the bottom navigation bar, same
/// as the GRN/PR Detail Views.
class InvoiceDetailPage extends GetView<InvoiceDetailController> {
  const InvoiceDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
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
              controller.invoice.number,
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
                  () => PurchaseRequestStatusBadge(
                    status: controller.invoice.status,
                  ),
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
              Tab(text: 'pr_invoice'.tr.toUpperCase()),
            ],
          ),
        ),
        body: Obx(
          () => TabBarView(
            children: [
              InvoiceSummaryTab(request: controller.invoice),
              InvoiceSupplyItemsTab(request: controller.invoice),
              InvoiceGrnTab(request: controller.invoice),
              InvoiceInvoiceTab(request: controller.invoice),
            ],
          ),
        ),
        bottomNavigationBar: const InvoiceApprovalActionBar(),
      ),
    );
  }
}
