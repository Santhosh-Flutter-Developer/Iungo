import 'package:iungo/features/grn_request/data/grn_request_seed_data.dart';
import 'package:iungo/features/grn_request/domain/entities/grn_request.dart';
import 'package:iungo/features/purchase_request/domain/entities/purchase_request_status.dart';

/// Local, in-memory stand-in for the future GRN API.
///
/// UI-only for now: every method already has the async shape (`Future`,
/// simulated network delay) the real implementation will need, so
/// swapping the body for a live Dio call later shouldn't require
/// touching any controller/page that depends on this class. Registered
/// as a single permanent instance (see `GrnDashboardBinding`) so the
/// list, detail, search, and filter screens all read/write the same
/// in-memory data set. Mirrors `PurchaseRequestRepository` shape for
/// shape.
class GrnRequestRepository {
  GrnRequestRepository() : _requests = buildGrnRequestSeed();

  final List<GrnRequest> _requests;

  /// Contract picklist — mirrors the PR Dashboard's "Select Contract"
  /// filter.
  static const List<String> contracts = [
    'Diriyah - DIR',
    'Riyadh - RYD',
    'Jeddah - JED',
    'Dammam - DMM',
  ];

  Future<List<GrnRequest>> fetchAll() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.unmodifiable(_requests);
  }

  /// Approves/rejects [id]'s current pending GRN stage. `remarks` is
  /// required by the reject flow (enforced by the Reject dialog before
  /// this is ever called); approve doesn't collect one.
  Future<GrnRequest> submitDecision({
    required int id,
    required bool approve,
    String? remarks,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final index = _requests.indexWhere((r) => r.id == id);
    if (index == -1) {
      throw StateError('GRN Request $id not found');
    }
    final updated = _requests[index].copyWith(
      status: approve
          ? PurchaseRequestStatus.approved
          : PurchaseRequestStatus.rejected,
      clearNextApprovalName: true,
      currentStage: approve ? _requests[index].totalStages : null,
    );
    _requests[index] = updated;
    return updated;
  }
}
