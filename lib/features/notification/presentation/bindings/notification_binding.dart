import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:iungo/core/services/session_service.dart';
import 'package:iungo/features/notification/data/datasources/notification_remote_data_source.dart';
import 'package:iungo/features/notification/data/notification_repository.dart';
import 'package:iungo/features/notification/presentation/controllers/notification_controller.dart';

class NotificationBinding extends Bindings {
  @override
  void dependencies() {
    ensureRepositoryRegistered();

    Get.lazyPut<NotificationController>(
      () => NotificationController(Get.find<NotificationRepository>()),
    );
  }

  /// Registers the Dio client, remote data source, and the shared
  /// [NotificationRepository] if they aren't already — mirrors
  /// [ServiceRequestListBinding.ensureRepositoryRegistered] so both
  /// features can share the same Dio instance regardless of which one
  /// initializes it first.
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

    if (!Get.isRegistered<NotificationRemoteDataSource>()) {
      Get.lazyPut<NotificationRemoteDataSource>(
        () => NotificationRemoteDataSourceImpl(
          Get.find<Dio>(),
          Get.find<SessionService>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<NotificationRepository>()) {
      Get.put(
        NotificationRepository(Get.find<NotificationRemoteDataSource>()),
        permanent: true,
      );
    }
  }
}
