import 'package:get/get.dart';
import 'package:iungo/features/service_request/data/service_request_repository.dart';
import 'package:iungo/features/service_request/presentation/bindings/service_request_list_binding.dart';
import 'package:iungo/features/service_request/presentation/controllers/ticket_search_controller.dart';

class TicketSearchBinding extends Bindings {
  @override
  void dependencies() {
    ServiceRequestListBinding.ensureRepositoryRegistered();
    Get.put(TicketSearchController(Get.find<ServiceRequestRepository>()));
  }
}
