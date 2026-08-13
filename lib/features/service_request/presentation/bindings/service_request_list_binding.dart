import 'package:get/get.dart';
import 'package:iungo/features/service_request/data/service_request_repository.dart';
import 'package:iungo/features/service_request/presentation/controllers/service_request_list_controller.dart';

class ServiceRequestListBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ServiceRequestRepository>()) {
      Get.put(ServiceRequestRepository(), permanent: true);
    }
    Get.lazyPut<ServiceRequestListController>(
      () => ServiceRequestListController(Get.find<ServiceRequestRepository>()),
      fenix: true,
    );
  }
}
