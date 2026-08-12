import 'package:get/get.dart';
import 'package:iungo/features/dashboard/domain/entities/dashboard_action.dart';
import 'package:iungo/features/dashboard/presentation/widgets/create_service_request_sheet.dart';

class DashboardController extends GetxController {
  void onActionTap(DashboardAction action) {
    switch (action) {
      case DashboardAction.createServiceRequest:
        CreateServiceRequestSheet.show();
        break;
      case DashboardAction.myServiceRequests:
        
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
