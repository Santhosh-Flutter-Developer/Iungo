import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:iungo/core/services/session_service.dart';
import 'package:iungo/features/inventory_request/data/datasources/inventory_request_detail_remote_data_source.dart';
import 'package:iungo/features/inventory_request/data/datasources/inventory_request_picklist_remote_data_source.dart';
import 'package:iungo/features/inventory_request/data/datasources/inventory_request_remote_data_source.dart';
import 'package:iungo/features/inventory_request/data/inventory_request_repository.dart';
import 'package:iungo/features/inventory_request/presentation/controllers/inventory_request_list_controller.dart';

/// Registers the Dio client, remote data sources, the shared
/// [InventoryRequestRepository], and the [InventoryRequestListController]
/// backing the "Awaiting Client Approval" screen. Mirrors
/// [WorkOrderListBinding] exactly.
class InventoryRequestListBinding extends Bindings {
  @override
  void dependencies() {
    ensureRepositoryRegistered();

    Get.lazyPut<InventoryRequestListController>(
      () => InventoryRequestListController(
        Get.find<InventoryRequestRepository>(),
      ),
      fenix: true,
    );
  }

  /// Registers the Dio client, remote data sources, and the shared
  /// [InventoryRequestRepository] if they aren't already — shared by any
  /// entry point that needs the repository (list page, search, detail)
  /// regardless of which one runs first.
  static void ensureRepositoryRegistered() {
    if (!Get.isRegistered<Dio>()) {
      Get.lazyPut<Dio>(
        () => Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 20),
          ),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<InventoryRequestRemoteDataSource>()) {
      Get.lazyPut<InventoryRequestRemoteDataSource>(
        () => InventoryRequestRemoteDataSourceImpl(
          Get.find<Dio>(),
          Get.find<SessionService>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<InventoryRequestPickListRemoteDataSource>()) {
      Get.lazyPut<InventoryRequestPickListRemoteDataSource>(
        () => InventoryRequestPickListRemoteDataSourceImpl(
          Get.find<Dio>(),
          Get.find<SessionService>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<InventoryRequestDetailRemoteDataSource>()) {
      Get.lazyPut<InventoryRequestDetailRemoteDataSource>(
        () => InventoryRequestDetailRemoteDataSourceImpl(
          Get.find<Dio>(),
          Get.find<SessionService>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<InventoryRequestRepository>()) {
      Get.put(
        InventoryRequestRepository(
          Get.find<InventoryRequestRemoteDataSource>(),
          Get.find<InventoryRequestPickListRemoteDataSource>(),
          Get.find<InventoryRequestDetailRemoteDataSource>(),
        ),
        permanent: true,
      );
    }
  }
}
