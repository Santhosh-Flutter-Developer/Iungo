import 'package:get/get.dart';
import 'package:iungo/features/service_request/data/service_request_repository.dart';
import 'package:iungo/features/service_request/domain/entities/service_request.dart';
import 'package:iungo/features/service_request/presentation/bindings/service_request_list_binding.dart';
import 'package:iungo/features/service_request/presentation/controllers/service_request_detail_controller.dart';

class ServiceRequestDetailBinding extends Bindings {
  ServiceRequestDetailBinding(this.request);

  final ServiceRequest request;

  @override
  void dependencies() {
    ServiceRequestListBinding.ensureRepositoryRegistered();
    Get.put(
      ServiceRequestDetailController(
        Get.find<ServiceRequestRepository>(),
        request,
      ),
    );
  }
}