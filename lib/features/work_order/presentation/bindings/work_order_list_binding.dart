import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:iungo/core/services/session_service.dart';
import 'package:iungo/features/work_order/data/datasources/work_order_detail_remote_data_source.dart';
import 'package:iungo/features/work_order/data/datasources/work_order_picklist_remote_data_source.dart';
import 'package:iungo/features/work_order/data/datasources/work_order_remote_data_source.dart';
import 'package:iungo/features/work_order/data/work_order_repository.dart';
import 'package:iungo/features/work_order/presentation/controllers/work_order_list_controller.dart';

class WorkOrderListBinding extends Bindings {
  @override
  void dependencies() {
    ensureRepositoryRegistered();

    Get.lazyPut<WorkOrderListController>(
      () => WorkOrderListController(Get.find<WorkOrderRepository>()),
      fenix: true,
    );
  }

  /// Registers the Dio client, remote data sources, and the shared
  /// [WorkOrderRepository] if they aren't already — shared by any entry
  /// point that needs the repository (list page, search) regardless of
  /// which one runs first.
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

    if (!Get.isRegistered<WorkOrderRemoteDataSource>()) {
      Get.lazyPut<WorkOrderRemoteDataSource>(
        () => WorkOrderRemoteDataSourceImpl(
          Get.find<Dio>(),
          Get.find<SessionService>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<WorkOrderPickListRemoteDataSource>()) {
      Get.lazyPut<WorkOrderPickListRemoteDataSource>(
        () => WorkOrderPickListRemoteDataSourceImpl(
          Get.find<Dio>(),
          Get.find<SessionService>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<WorkOrderDetailRemoteDataSource>()) {
      Get.lazyPut<WorkOrderDetailRemoteDataSource>(
        () => WorkOrderDetailRemoteDataSourceImpl(
          Get.find<Dio>(),
          Get.find<SessionService>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<WorkOrderRepository>()) {
      Get.put(
        WorkOrderRepository(
          Get.find<WorkOrderRemoteDataSource>(),
          Get.find<WorkOrderPickListRemoteDataSource>(),
          Get.find<WorkOrderDetailRemoteDataSource>(),
        ),
        permanent: true,
      );
    }
  }
}