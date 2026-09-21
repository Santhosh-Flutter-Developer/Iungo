import 'package:get/get.dart';
import 'package:iungo/core/services/session_service.dart';
import 'package:iungo/features/purchase_request/domain/entities/pr_view_role.dart';

/// Which UI the logged-in user gets on the PR, GRN and Invoice
/// dashboards (and their detail screens): Requestor or Approver.
///
/// The role is not chosen in the UI — it comes from the login
/// response's `add_purchase_request` flag, kept in [SessionService]:
///
///   * `1` -> [PrViewRole.requestor] (sees "Add", no approve/reject)
///   * `0` -> [PrViewRole.approver]  (sees approve/reject, no "Add")
///
/// If the flag is unknown (a session saved before it was stored, or the
/// API omitted it) the user is treated as a requestor, as before. Every
/// getter reads the session's reactive value, so an `Obx` using them
/// rebuilds when the session changes (e.g. signing in as someone else).
///
/// Registered once, permanently, in `PrDashboardBinding` and shared by
/// all three dashboards.
class PrRoleController extends GetxService {
  PrRoleController(this._session);

  final SessionService _session;

  PrViewRole get role => _session.canAddPurchaseRequest.value == false
      ? PrViewRole.approver
      : PrViewRole.requestor;

  bool get isApprover => role == PrViewRole.approver;
  bool get isRequestor => role == PrViewRole.requestor;
}
