import 'package:get/get.dart';
import 'package:iungo/features/auth/presentation/bindings/login_binding.dart';
import 'package:iungo/features/auth/presentation/pages/login_page.dart';
import 'package:iungo/features/onboarding/presentation/bindings/onboarding_binding.dart';
import 'package:iungo/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:iungo/features/splash/presentation/bindings/splash_binding.dart';
import 'package:iungo/features/splash/presentation/pages/splash_page.dart';

import 'app_routes.dart';

class AppPages {
  AppPages._();

  static final pages = <GetPage>[
    GetPage(
      name: AppRoutes.splash,
      page: () => SplashPage(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.onboarding,
      page: () =>  OnboardingPage(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginPage(),
      binding: LoginBinding(),
      transition: Transition.rightToLeft,
    ),
    // GetPage(
    //   name: AppRoutes.privacyPolicy,
    //   page: () => const PrivacyPolicyPage(),
    //   transition: Transition.downToUp,
    // ),
  ];
}
