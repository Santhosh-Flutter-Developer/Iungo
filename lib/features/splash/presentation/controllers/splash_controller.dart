import 'package:get/get.dart';
import 'package:iungo/core/routes/app_routes.dart';

class SplashController extends GetxController {
  @override
  void onReady() {
    super.onReady();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    await Future.delayed(const Duration(seconds: 2));
    Get.offAllNamed(AppRoutes.onboarding);
  }
}
