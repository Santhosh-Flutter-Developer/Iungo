import 'package:get/get.dart';
import 'package:iungo/core/services/session_service.dart';
import 'package:iungo/features/service_request/data/service_request_repository.dart';
import 'package:iungo/features/service_request/presentation/bindings/service_request_list_binding.dart';
import 'package:iungo/features/service_request/presentation/controllers/new_service_request_controller.dart';

class NewServiceRequestBinding extends Bindings {
  /// [prefillSiteId]/[prefillSiteName]/[prefillAssetId]/
  /// [prefillAssetLabel] are set when this form is opened from Asset
  /// Detail's "create service request for this asset" action (the Scan
  /// QR flow) — left null for every other entry point (dashboard's
  /// "Create Service Request" tile), which starts the form blank as
  /// before.
  NewServiceRequestBinding({
    this.prefillSiteId,
    this.prefillSiteName,
    this.prefillAssetId,
    this.prefillAssetLabel,
  });

  final int? prefillSiteId;
  final String? prefillSiteName;
  final int? prefillAssetId;
  final String? prefillAssetLabel;

  @override
  void dependencies() {
    ServiceRequestListBinding.ensureRepositoryRegistered();

    Get.lazyPut<NewServiceRequestController>(
      () => NewServiceRequestController(
        Get.find<ServiceRequestRepository>(),
        Get.find<SessionService>(),
        prefillSiteId: prefillSiteId,
        prefillSiteName: prefillSiteName,
        prefillAssetId: prefillAssetId,
        prefillAssetLabel: prefillAssetLabel,
      ),
      fenix: true,
    );
  }
}