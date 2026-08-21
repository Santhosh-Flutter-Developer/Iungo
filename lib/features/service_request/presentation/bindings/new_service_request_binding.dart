import 'package:get/get.dart';
import 'package:iungo/core/services/session_service.dart';
import 'package:iungo/features/service_request/data/service_request_repository.dart';
import 'package:iungo/features/service_request/presentation/bindings/service_request_list_binding.dart';
import 'package:iungo/features/service_request/presentation/controllers/new_service_request_controller.dart';

class NewServiceRequestBinding extends Bindings {
  @override
  void dependencies() {
    ServiceRequestListBinding.ensureRepositoryRegistered();

    Get.lazyPut<NewServiceRequestController>(
      () => NewServiceRequestController(
        Get.find<ServiceRequestRepository>(),
        Get.find<SessionService>(),
      ),
      fenix: true,
    );
  }
}