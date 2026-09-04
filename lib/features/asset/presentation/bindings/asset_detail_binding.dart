import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:iungo/core/services/session_service.dart';
import 'package:iungo/features/asset/data/asset_repository.dart';
import 'package:iungo/features/asset/data/datasources/asset_remote_data_source.dart';
import 'package:iungo/features/asset/presentation/controllers/asset_detail_controller.dart';
import 'package:iungo/features/service_request/presentation/bindings/service_request_list_binding.dart';

class AssetDetailBinding extends Bindings {
  AssetDetailBinding({required this.scannedValue});

  final String scannedValue;

  @override
  void dependencies() {
    // Reuses the app's shared Dio client + SessionService (registered
    // here if nothing else has yet) — same pattern the service_request
    // feature uses for itself. The asset module API this binding now
    // calls is otherwise unrelated to service_request's own endpoints.
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
        () => AssetRepository(Get.find<AssetRemoteDataSource>()),
        fenix: true,
      );
    }

    Get.put(
      AssetDetailController(Get.find<AssetRepository>(), scannedValue),
    );
  }
}