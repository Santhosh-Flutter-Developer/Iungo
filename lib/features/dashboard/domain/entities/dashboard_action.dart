import 'package:flutter/material.dart';

/// One tappable tile on the dashboard grid — mirrors every navigable
/// item in [AppDrawer] (aside from Dashboard itself, since we're already
/// on it, and Sign Out, which isn't a navigation destination) so the
/// dashboard surfaces the full side menu as tiles.
enum DashboardAction {
  createServiceRequest,
  myServiceRequests,
  scanQr,
  myWorkOrders,
  awaitingPauseApproval,
  awaitingClosureApproval,
  inventoryRequestAwaitingClientApproval,
  prDashboard,
  grnDashboard,
  invoiceDashboard,
  profile,
}

extension DashboardActionX on DashboardAction {
  IconData get icon {
    switch (this) {
      case DashboardAction.createServiceRequest:
        return Icons.add;
      case DashboardAction.myServiceRequests:
        return Icons.assignment_turned_in_outlined;
      case DashboardAction.scanQr:
        return Icons.qr_code_scanner_outlined;
      case DashboardAction.myWorkOrders:
        return Icons.playlist_add_check_outlined;
      case DashboardAction.awaitingPauseApproval:
        return Icons.pause_circle_outline;
      case DashboardAction.awaitingClosureApproval:
        return Icons.task_alt_outlined;
      case DashboardAction.inventoryRequestAwaitingClientApproval:
        return Icons.inventory_2_outlined;
      case DashboardAction.prDashboard:
        return Icons.dashboard_outlined;
      case DashboardAction.grnDashboard:
        return Icons.local_shipping_outlined;
      case DashboardAction.invoiceDashboard:
        return Icons.receipt_long_outlined;
      case DashboardAction.profile:
        return Icons.person_outline;
    }
  }

  String get labelKey {
    switch (this) {
      case DashboardAction.createServiceRequest:
        return 'create_service_request';
      case DashboardAction.myServiceRequests:
        return 'my_service_requests';
      case DashboardAction.scanQr:
        return 'scan_qr';
      case DashboardAction.myWorkOrders:
        return 'my_work_orders';
      case DashboardAction.awaitingPauseApproval:
        return 'awaiting_pause_approval';
      case DashboardAction.awaitingClosureApproval:
        return 'awaiting_approval_closure';
      case DashboardAction.inventoryRequestAwaitingClientApproval:
        return 'awaiting_client_approval';
      case DashboardAction.prDashboard:
        return 'pr_dashboard';
      case DashboardAction.grnDashboard:
        return 'grn_dashboard';
      case DashboardAction.invoiceDashboard:
        return 'invoice_dashboard';
      case DashboardAction.profile:
        return 'profile';
    }
  }
}