import 'package:get/get.dart';
import 'package:iungo/features/dashboard/presentation/controllers/dashboard_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DashboardController>(() => DashboardController());
  }
}
