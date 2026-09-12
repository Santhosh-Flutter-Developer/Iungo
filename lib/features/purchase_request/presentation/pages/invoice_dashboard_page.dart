import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/core/widgets/app_drawer.dart';
import 'package:iungo/features/purchase_request/presentation/widgets/purchase_request_placeholder_body.dart';

/// Empty placeholder for the "Invoice Dashboard" menu item — real UI to
/// follow once shared.
class InvoiceDashboardPage extends StatelessWidget {
  const InvoiceDashboardPage({super.key});

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
          'invoice_dashboard'.tr,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      drawer: const AppDrawer(selected: DrawerMenuItem.invoiceDashboard),
      body: const SafeArea(
        child: PurchaseRequestPlaceholderBody(
          icon: Icons.receipt_long_outlined,
        ),
      ),
    );
  }
}
