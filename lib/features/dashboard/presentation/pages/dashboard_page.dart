import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/core/widgets/app_drawer.dart';
import 'package:iungo/features/dashboard/domain/entities/dashboard_action.dart';
import 'package:iungo/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:iungo/features/dashboard/presentation/widgets/dashboard_card.dart';
import 'package:iungo/features/service_request/presentation/widgets/create_service_request_sheet.dart';

class DashboardPage extends GetView<DashboardController> {
  const DashboardPage({super.key});

  // Every navigable side-menu item (mirrors AppDrawer) except Dashboard
  // itself and Sign Out.
  static const _actions = [
    DashboardAction.createServiceRequest,
    DashboardAction.myServiceRequests,
    DashboardAction.scanQr,
    DashboardAction.myWorkOrders,
    DashboardAction.awaitingPauseApproval,
    DashboardAction.awaitingClosureApproval,
    DashboardAction.inventoryRequestAwaitingClientApproval,
    DashboardAction.prDashboard,
    DashboardAction.grnDashboard,
    DashboardAction.invoiceDashboard,
    DashboardAction.profile,
  ];

  static const _crossAxisCount = 2;
  static const _spacing = 8.0;
  static const _gridPadding = 10.0;
  // Fixed tile shape so cards keep a comfortable, consistent size no
  // matter how many there are — once they no longer fit one screen,
  // the grid simply scrolls instead of shrinking every tile down.
  static const _tileAspectRatio = 1.1;

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
          'dashboard'.tr,
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
        ],
      ),
      drawer: const AppDrawer(selected: DrawerMenuItem.dashboard),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(_gridPadding),
          child: GridView.count(
            physics: const AlwaysScrollableScrollPhysics(),
            crossAxisCount: _crossAxisCount,
            mainAxisSpacing: _spacing,
            crossAxisSpacing: _spacing,
            childAspectRatio: _tileAspectRatio,
            children: _actions
                .map(
                  (action) => DashboardCard(
                    icon: action.icon,
                    label: action.labelKey.tr,
                    onTap: () =>
                        action == DashboardAction.createServiceRequest
                            ? CreateServiceRequestSheet.show(context)
                            : controller.onActionTap(action),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}