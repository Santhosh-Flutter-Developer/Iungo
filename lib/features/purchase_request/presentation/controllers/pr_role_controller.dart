import 'package:get/get.dart';
import 'package:iungo/features/purchase_request/domain/entities/pr_view_role.dart';

/// Holds which PR Dashboard UI (Requestor/Approver) is currently being
/// previewed. See [PrViewRole] for why this exists and why it's
/// dev-only: it will be replaced by a real value resolved from the
/// logged-in user's session once the API is wired up. Registered once,
/// permanently, in `PrDashboardBinding.ensureRepositoryRegistered` so
/// the dashboard, detail, and create screens all read the same value.
class PrRoleController extends GetxService {
  final Rx<PrViewRole> role = PrViewRole.requestor.obs;

  bool get isApprover => role.value == PrViewRole.approver;
  bool get isRequestor => role.value == PrViewRole.requestor;

  void setRole(PrViewRole value) => role.value = value;
}
