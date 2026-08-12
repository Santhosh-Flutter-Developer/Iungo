import 'package:get/get.dart';
import 'package:iungo/features/service_request/presentation/controllers/new_service_request_controller.dart';

class NewServiceRequestBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NewServiceRequestController>(
      () => NewServiceRequestController(),
      fenix: true,
    );
  }
}
