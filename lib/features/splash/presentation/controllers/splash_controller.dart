import 'package:get/get.dart';
import 'package:iungo/core/routes/app_routes.dart';
import 'package:iungo/core/services/session_service.dart';

class SplashController extends GetxController {
  @override
  void onReady() {
    super.onReady();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    await Future.delayed(const Duration(seconds: 2));

    final isLoggedIn = Get.find<SessionService>().isLoggedIn.value;
    Get.offAllNamed(isLoggedIn ? AppRoutes.dashboard : AppRoutes.onboarding);
  }
}
