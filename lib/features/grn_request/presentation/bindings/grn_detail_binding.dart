import 'package:get/get.dart';
import 'package:iungo/features/grn_request/data/grn_request_repository.dart';
import 'package:iungo/features/grn_request/domain/entities/grn_request.dart';
import 'package:iungo/features/grn_request/presentation/bindings/grn_dashboard_binding.dart';
import 'package:iungo/features/grn_request/presentation/controllers/grn_detail_controller.dart';

/// Registers the [GrnDetailController] for one GRN Request's Detail
/// View. Mirrors `PrDetailBinding`.
class GrnDetailBinding extends Bindings {
  GrnDetailBinding(this.request);

  final GrnRequest request;

  @override
  void dependencies() {
    GrnDashboardBinding.ensureRepositoryRegistered();
    Get.put(
      GrnDetailController(Get.find<GrnRequestRepository>(), request),
    );
  }
}
