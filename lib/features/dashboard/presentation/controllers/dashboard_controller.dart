import 'package:get/get.dart';
import 'package:iungo/core/routes/app_routes.dart';
import 'package:iungo/features/dashboard/domain/entities/dashboard_action.dart';

class DashboardController extends GetxController {
  void onActionTap(DashboardAction action) {
    switch (action) {
      case DashboardAction.createServiceRequest:
       
        break;
      case DashboardAction.myServiceRequests:
        Get.toNamed(AppRoutes.serviceRequestList);
        break;
      case DashboardAction.scanQr:
       
        break;
      case DashboardAction.myWorkOrders:
        
        break;
    }
  }

  void onNotificationsTap() {
  }
}
