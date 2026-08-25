import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:iungo/core/services/session_service.dart';
import 'package:iungo/features/service_request/data/datasources/service_request_create_remote_data_source.dart';
import 'package:iungo/features/service_request/data/datasources/service_request_detail_remote_data_source.dart';
import 'package:iungo/features/service_request/data/datasources/service_request_picklist_remote_data_source.dart';
import 'package:iungo/features/service_request/data/datasources/service_request_remote_data_source.dart';
import 'package:iungo/features/service_request/data/service_request_repository.dart';
import 'package:iungo/features/service_request/presentation/controllers/service_request_list_controller.dart';

class ServiceRequestListBinding extends Bindings {
  @override
  void dependencies() {
    ensureRepositoryRegistered();

    Get.lazyPut<ServiceRequestListController>(
      () => ServiceRequestListController(Get.find<ServiceRequestRepository>()),
      fenix: true,
    );
  }

  /// Registers the Dio client, remote data sources, and the shared
  /// [ServiceRequestRepository] if they aren't already — shared by any
  /// entry point that needs the repository (list page, ticket search,
  /// "New Service Request" submission) regardless of which one runs
  /// first.
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

    if (!Get.isRegistered<ServiceRequestRemoteDataSource>()) {
      Get.lazyPut<ServiceRequestRemoteDataSource>(
        () => ServiceRequestRemoteDataSourceImpl(
          Get.find<Dio>(),
          Get.find<SessionService>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<ServiceRequestPickListRemoteDataSource>()) {
      Get.lazyPut<ServiceRequestPickListRemoteDataSource>(
        () => ServiceRequestPickListRemoteDataSourceImpl(
          Get.find<Dio>(),
          Get.find<SessionService>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<ServiceRequestCreateRemoteDataSource>()) {
      Get.lazyPut<ServiceRequestCreateRemoteDataSource>(
        () => ServiceRequestCreateRemoteDataSourceImpl(
          Get.find<Dio>(),
          Get.find<SessionService>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<ServiceRequestDetailRemoteDataSource>()) {
      Get.lazyPut<ServiceRequestDetailRemoteDataSource>(
        () => ServiceRequestDetailRemoteDataSourceImpl(
          Get.find<Dio>(),
          Get.find<SessionService>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<ServiceRequestRepository>()) {
      Get.put(
        ServiceRequestRepository(
          Get.find<ServiceRequestRemoteDataSource>(),
          Get.find<ServiceRequestPickListRemoteDataSource>(),
          Get.find<ServiceRequestCreateRemoteDataSource>(),
          Get.find<ServiceRequestDetailRemoteDataSource>(),
        ),
        permanent: true,
      );
    }
  }
}