abstract class AppRoutes {
  AppRoutes._();

  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const privacyPolicy = '/privacy-policy';
  static const dashboard = '/dashboard';
  static const serviceRequestList = '/service-requests';
  static const notifications = '/notifications';
  static const profile = '/profile';
  static const scanQr = '/scan-qr';
  static const workOrderList = '/work-orders';
  static const workOrderPauseApprovalList = '/work-orders/pause-approval';
  static const workOrderClosureApprovalList = '/work-orders/closure-approval';
  static const inventoryRequestAwaitingClientApproval =
      '/inventory-requests/awaiting-client-approval';
}