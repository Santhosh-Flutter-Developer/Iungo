import 'package:get/get.dart';
import 'package:iungo/features/asset/presentation/bindings/scan_qr_binding.dart';
import 'package:iungo/features/asset/presentation/pages/scan_qr_page.dart';
import 'package:iungo/features/auth/presentation/bindings/login_binding.dart';
import 'package:iungo/features/auth/presentation/pages/login_page.dart';
import 'package:iungo/features/dashboard/presentation/bindings/dashboard_binding.dart';
import 'package:iungo/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:iungo/features/legal/presentation/pages/privacy_policy_page.dart';
import 'package:iungo/features/notification/presentation/bindings/notification_binding.dart';
import 'package:iungo/features/notification/presentation/pages/notification_page.dart';
import 'package:iungo/features/onboarding/presentation/bindings/onboarding_binding.dart';
import 'package:iungo/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:iungo/features/profile/presentation/bindings/profile_binding.dart';
import 'package:iungo/features/profile/presentation/pages/profile_page.dart';
import 'package:iungo/features/service_request/presentation/bindings/service_request_list_binding.dart';
import 'package:iungo/features/service_request/presentation/pages/service_request_list_page.dart';
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
    GetPage(
      name: AppRoutes.privacyPolicy,
      page: () => const PrivacyPolicyPage(),
      transition: Transition.downToUp,
    ),
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardPage(),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: AppRoutes.serviceRequestList,
      page: () => const ServiceRequestListPage(),
      binding: ServiceRequestListBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfilePage(),
      binding: ProfileBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.notifications,
      page: () => const NotificationPage(),
      binding: NotificationBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.scanQr,
      page: () => const ScanQrPage(),
      binding: ScanQrBinding(),
      transition: Transition.rightToLeft,
    ),
  ];
}