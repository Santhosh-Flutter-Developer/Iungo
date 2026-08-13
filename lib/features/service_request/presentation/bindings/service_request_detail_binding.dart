import 'package:get/get.dart';
import 'package:iungo/features/service_request/domain/entities/service_request.dart';
import 'package:iungo/features/service_request/presentation/controllers/service_request_detail_controller.dart';

class ServiceRequestDetailBinding extends Bindings {
  ServiceRequestDetailBinding(this.request);

  final ServiceRequest request;

  @override
  void dependencies() {
    Get.put(ServiceRequestDetailController(request));
  }
}
