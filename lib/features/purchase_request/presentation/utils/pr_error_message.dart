import 'package:get/get.dart';
import 'package:iungo/features/purchase_request/data/datasources/pr_create_exceptions.dart';

/// A translated, user-facing message for a failed Purchase Request API
/// call. The server's own message wins for API-level refusals (e.g.
/// "Please enter remarks before rejecting the purchase request.") and
/// server errors that carry one; connectivity, timeout and session
/// problems always use the app's translated text; anything else falls
/// back to [fallbackKey].
String prErrorMessage(Object error, {required String fallbackKey}) {
  if (error is! PrCreateException) return fallbackKey.tr;

  switch (error.type) {
    case PrCreateFailure.noInternet:
      return 'pr_err_no_internet'.tr;
    case PrCreateFailure.timeout:
      return 'pr_err_timeout'.tr;
    case PrCreateFailure.unauthorized:
      return 'pr_err_session_expired'.tr;
    case PrCreateFailure.forbidden:
      return 'pr_err_forbidden'.tr;
    case PrCreateFailure.invalidResponse:
      return 'pr_err_invalid_response'.tr;
    case PrCreateFailure.server:
    case PrCreateFailure.rejected:
      final message = error.message;
      if (message != null && message.isNotEmpty) return message;
      return error.type == PrCreateFailure.server
          ? 'pr_err_server'.tr
          : fallbackKey.tr;
    case PrCreateFailure.cancelled:
    case PrCreateFailure.unknown:
      return fallbackKey.tr;
  }
}
