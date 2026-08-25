import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:iungo/core/services/session_service.dart';
import 'package:iungo/features/asset/data/asset_repository.dart';
import 'package:iungo/features/asset/data/datasources/asset_remote_data_source.dart';
import 'package:iungo/features/asset/presentation/controllers/asset_detail_controller.dart';
import 'package:iungo/features/service_request/data/datasources/service_request_picklist_remote_data_source.dart';
import 'package:iungo/features/service_request/presentation/bindings/service_request_list_binding.dart';

class AssetDetailBinding extends Bindings {
  AssetDetailBinding({required this.scannedValue});

  final String scannedValue;

  @override
  void dependencies() {
    // Registers the shared Dio client + Site/Building/Asset pick-list
    // data source (used here to resolve the asset's site name) if they
    // aren't already — same shared-Dio pattern the service_request
    // feature uses for itself.
    ServiceRequestListBinding.ensureRepositoryRegistered();

    if (!Get.isRegistered<AssetRemoteDataSource>()) {
      Get.lazyPut<AssetRemoteDataSource>(
        () => AssetRemoteDataSourceImpl(
          Get.find<Dio>(),
          Get.find<SessionService>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<AssetRepository>()) {
      Get.lazyPut<AssetRepository>(
        () => AssetRepository(
          Get.find<AssetRemoteDataSource>(),
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