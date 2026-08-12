import 'package:flutter/material.dart';

/// One tappable tile on the dashboard grid.
enum DashboardAction {
  createServiceRequest,
  myServiceRequests,
  scanQr,
  myWorkOrders,
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
    }
  }
}
