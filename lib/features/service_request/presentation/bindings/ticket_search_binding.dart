import 'package:get/get.dart';
import 'package:iungo/features/service_request/data/service_request_repository.dart';
import 'package:iungo/features/service_request/presentation/controllers/ticket_search_controller.dart';

class TicketSearchBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ServiceRequestRepository>()) {
      Get.put(ServiceRequestRepository(), permanent: true);
    }
    Get.put(TicketSearchController(Get.find<ServiceRequestRepository>()));
  }
}
