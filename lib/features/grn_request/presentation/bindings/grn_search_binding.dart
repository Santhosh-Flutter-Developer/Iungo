import 'package:get/get.dart';
import 'package:iungo/features/grn_request/data/grn_request_repository.dart';
import 'package:iungo/features/grn_request/presentation/bindings/grn_dashboard_binding.dart';
import 'package:iungo/features/grn_request/presentation/controllers/grn_search_controller.dart';

/// Registers the [GrnSearchController] backing the GRN Dashboard search
/// screen. Mirrors `PrSearchBinding`.
class GrnSearchBinding extends Bindings {
  @override
  void dependencies() {
    GrnDashboardBinding.ensureRepositoryRegistered();
    Get.put(GrnSearchController(Get.find<GrnRequestRepository>()));
  }
}
