import 'package:iungo/core/services/session_service.dart';
import 'package:iungo/features/purchase_request/data/datasources/pr_create_exceptions.dart';

/// The logged-in user's id for the Purchase Request API (`user_id`),
/// read from the session at call time — never hard-coded or cached. An
/// unusable session is reported as an "unauthorized" failure so the UI
/// asks the user to sign in again.
String requirePrUserId(SessionService session) {
  final userId = session.authUserId.value;
  if (userId == null || userId.trim().isEmpty) {
    throw const PrCreateException(PrCreateFailure.unauthorized);
  }
  return userId.trim();
}
