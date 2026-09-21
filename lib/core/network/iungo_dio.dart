import 'package:dio/dio.dart';
import 'package:iungo/core/network/dev_certificate_override.dart';

/// A single, always-available [Dio] for the Iungo host
/// (`iungo.citgroupltd.com`), with the debug-only certificate
/// workaround applied.
///
/// Kept independent of GetX registration: the Purchase Request list/
/// approve/reject API, the "Add Purchase Request" flow, and downloading
/// a Purchase Request's attachments or print PDF all talk to this host,
/// and none of them should depend on *whether* or *when* some other
/// feature's binding happened to register a `Dio` for a different host
/// under GetX's ambient `Dio` type (relying on that is what caused
/// attachment/PDF downloads to silently use a Dio without this host's
/// certificate override, and fail).
class IungoDio {
  IungoDio._();

  static Dio? _instance;

  static Dio get instance {
    final existing = _instance;
    if (existing != null) return existing;
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
    applyDevCertificateOverride(dio);
    return _instance = dio;
  }
}
