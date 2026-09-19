import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:iungo/core/network/dev_certificate_override.dart';
import 'package:iungo/core/services/session_service.dart';
import 'package:iungo/features/auth/data/datasources/auth_api_remote_data_source.dart';
import 'package:iungo/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:iungo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:iungo/features/auth/domain/repositories/auth_repository.dart';
import 'package:iungo/features/auth/domain/usecases/login_usecase.dart';
import 'package:iungo/features/auth/presentation/controllers/login_controller.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<Dio>(
      () {
        final dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 20),
            // No sendTimeout: it makes Dio attach a send-progress
            // listener, which forces a CORS preflight on web even for an
            // otherwise-"simple" request.
          ),
        );
        // TEMPORARY debug-only SSL workaround for iungo.citgroupltd.com
        // (see dev_certificate_override_io.dart). Remove once the server's
        // certificate chain is fixed.
        applyDevCertificateOverride(dio);
        return dio;
      },
      fenix: true,
    );
    Get.lazyPut<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(Get.find<Dio>()),
      fenix: true,
    );
    Get.lazyPut<AuthApiRemoteDataSource>(
      () => AuthApiRemoteDataSourceImpl(Get.find<Dio>()),
      fenix: true,
    );
    Get.lazyPut<AuthRepository>(
      () => AuthRepositoryImpl(
        Get.find<AuthRemoteDataSource>(),
        Get.find<AuthApiRemoteDataSource>(),
      ),
      fenix: true,
    );
    Get.lazyPut<LoginUseCase>(
      () => LoginUseCase(Get.find<AuthRepository>()),
      fenix: true,
    );
    Get.lazyPut<LoginController>(
      () => LoginController(Get.find<LoginUseCase>(), Get.find<SessionService>()),
    );
  }
}
