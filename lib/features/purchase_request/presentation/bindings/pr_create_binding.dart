import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:iungo/core/network/dev_certificate_override.dart';
import 'package:iungo/core/services/session_service.dart';
import 'package:iungo/features/purchase_request/data/datasources/pr_create_remote_data_source.dart';
import 'package:iungo/features/purchase_request/data/datasources/pr_material_remote_data_source.dart';
import 'package:iungo/features/purchase_request/data/pr_create_repository.dart';
import 'package:iungo/features/purchase_request/presentation/controllers/pr_create_controller.dart';

/// Registers the [PrCreateController] backing the "Add Purchase
/// Request" form (requestor view only), wired to the real APIs.
///
/// It builds its own [Dio] rather than borrowing the app-wide one: the
/// Iungo host needs the project's existing debug-only certificate
/// workaround (`applyDevCertificateOverride`, same as the login
/// binding), and this flow needs its own timeouts. Auth is not baked
/// into the client — the Facilio call adds the session's Bearer token
/// per request and the Iungo calls send the stored `user_id`.
class PrCreateBinding extends Bindings {
  @override
  void dependencies() {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 30),
        // No default sendTimeout: uploads set their own per request, and
        // a client-wide one would force a CORS preflight on web.
      ),
    );
    applyDevCertificateOverride(dio);

    final repository = PrCreateRepository(
      PrCreateRemoteDataSourceImpl(dio),
      PrMaterialRemoteDataSourceImpl(dio, Get.find<SessionService>()),
    );

    Get.put(PrCreateController(repository, Get.find<SessionService>()));
  }
}
