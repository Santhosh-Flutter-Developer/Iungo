import 'package:get/get.dart';
import 'package:iungo/core/network/iungo_dio.dart';
import 'package:iungo/core/services/session_service.dart';
import 'package:iungo/features/purchase_request/data/datasources/pr_create_remote_data_source.dart';
import 'package:iungo/features/purchase_request/data/datasources/pr_material_remote_data_source.dart';
import 'package:iungo/features/purchase_request/data/pr_create_repository.dart';
import 'package:iungo/features/purchase_request/presentation/controllers/pr_create_controller.dart';

/// Registers the [PrCreateController] backing the "Add Purchase
/// Request" form (requestor view only), wired to the real APIs.
///
/// It uses [IungoDio.instance] rather than borrowing whatever `Dio`
/// GetX has registered ambiently: that instance is shared with the rest
/// of the Purchase Request feature and carries the Iungo host's
/// debug-only certificate workaround. Auth is not baked into the
/// client — the Facilio call adds the session's Bearer token per
/// request and the Iungo calls send the stored `user_id`.
class PrCreateBinding extends Bindings {
  @override
  void dependencies() {
    final dio = IungoDio.instance;

    final repository = PrCreateRepository(
      PrCreateRemoteDataSourceImpl(dio),
      PrMaterialRemoteDataSourceImpl(dio, Get.find<SessionService>()),
    );

    Get.put(PrCreateController(repository, Get.find<SessionService>()));
  }
}
