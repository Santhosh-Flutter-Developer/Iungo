import 'package:get/get.dart';
import 'package:iungo/features/asset/data/asset_repository.dart';
import 'package:iungo/features/asset/presentation/controllers/asset_detail_controller.dart';
import 'package:iungo/features/service_request/data/datasources/service_request_picklist_remote_data_source.dart';
import 'package:iungo/features/service_request/presentation/bindings/service_request_list_binding.dart';

class AssetDetailBinding extends Bindings {
  AssetDetailBinding({required this.scannedValue});

  final String scannedValue;

  @override
  void dependencies() {
    // Registers the shared Dio client + Site/Building/Asset pick-list
    // data source (the same confirmed endpoint this binding resolves
    // asset lookups against) if they aren't already — same shared-Dio
    // pattern the service_request feature uses for itself.
    ServiceRequestListBinding.ensureRepositoryRegistered();

    if (!Get.isRegistered<AssetRepository>()) {
      Get.lazyPut<AssetRepository>(
        () => AssetRepository(
          Get.find<ServiceRequestPickListRemoteDataSource>(),
        ),
        fenix: true,
      );
    }

    Get.put(
      AssetDetailController(Get.find<AssetRepository>(), scannedValue),
    );
  }
}