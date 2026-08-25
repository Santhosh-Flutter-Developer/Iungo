import 'package:get/get.dart';
import 'package:iungo/features/asset/presentation/controllers/scan_qr_controller.dart';

class ScanQrBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ScanQrController>(() => ScanQrController());
  }
}