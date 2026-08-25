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

  static const _actions = [
    DashboardAction.createServiceRequest,
    DashboardAction.myServiceRequests,
    DashboardAction.scanQr,
    DashboardAction.myWorkOrders,
  ];

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
        child: GridView.count(
          padding: const EdgeInsets.all(10),
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.92,
          children: _actions
              .map(
                (action) => DashboardCard(
                  icon: action.icon,
                  label: action.labelKey.tr,
                  onTap: () => action == DashboardAction.createServiceRequest
                      ? CreateServiceRequestSheet.show(context)
                      : controller.onActionTap(action),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
