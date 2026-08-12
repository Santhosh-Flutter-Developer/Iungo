import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../controllers/login_controller.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<Dio>()) {
      Get.put<Dio>(
        Dio(BaseOptions(baseUrl: 'https://api.iungo.example.com')),
        permanent: true,
      );
    }

    Get.lazyPut<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(Get.find<Dio>()),
    );
    Get.lazyPut<AuthRepository>(
      () => AuthRepositoryImpl(Get.find<AuthRemoteDataSource>()),
    );
    Get.lazyPut<LoginUseCase>(() => LoginUseCase(Get.find<AuthRepository>()));
    Get.lazyPut<LoginController>(
      () => LoginController(Get.find<LoginUseCase>()),
    );
  }
}