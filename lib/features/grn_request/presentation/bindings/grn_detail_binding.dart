import 'package:get/get.dart';
import 'package:iungo/core/services/session_service.dart';
import 'package:iungo/features/grn_request/data/grn_request_repository.dart';
import 'package:iungo/features/grn_request/domain/entities/grn_request.dart';
import 'package:iungo/features/grn_request/presentation/bindings/grn_dashboard_binding.dart';
import 'package:iungo/features/grn_request/presentation/controllers/grn_detail_controller.dart';

/// Registers the [GrnDetailController] for one GRN's Detail View.
/// Mirrors `PrDetailBinding`.
///
/// [canDecide] says whether the request was opened from the approver's
/// Action Required list — the only place Approve/Reject may show.
class GrnDetailBinding extends Bindings {
  GrnDetailBinding(this.request, {this.canDecide = false});

  final GrnRequest request;
  final bool canDecide;

  @override
  void dependencies() {
    GrnDashboardBinding.ensureRepositoryRegistered();
    Get.put(
      GrnDetailController(
        Get.find<GrnRequestRepository>(),
        Get.find<SessionService>(),
        request,
        canDecide: canDecide,
      ),
    );
  }
}
