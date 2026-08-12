import 'package:get/get.dart';
import 'package:iungo/features/auth/presentation/controllers/login_controller.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoginController>(() => LoginController());
  }
}