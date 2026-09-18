import 'package:iungo/features/invoice_request/data/invoice_request_seed_data.dart';
import 'package:iungo/features/invoice_request/domain/entities/invoice_request.dart';
import 'package:iungo/features/purchase_request/domain/entities/purchase_request_status.dart';

/// Local, in-memory stand-in for the future Invoice API.
///
/// UI-only for now: every method already has the async shape (`Future`,
/// simulated network delay) the real implementation will need, so
/// swapping the body for a live Dio call later shouldn't require
/// touching any controller/page that depends on this class. Registered
/// as a single permanent instance (see `InvoiceDashboardBinding`) so
/// the list, detail, search, and filter screens all read/write the
/// same in-memory data set. Mirrors `GrnRequestRepository` shape for
/// shape.
class InvoiceRequestRepository {
  InvoiceRequestRepository() : _requests = buildInvoiceRequestSeed();

  final List<InvoiceRequest> _requests;

  /// Contract picklist — mirrors the GRN/PR Dashboards' "Select
  /// Contract" filter.
  static const List<String> contracts = [
    'Diriyah - DIR',
    'Riyadh - RYD',
    'Jeddah - JED',
    'Dammam - DMM',
  ];

  Future<List<InvoiceRequest>> fetchAll() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.unmodifiable(_requests);
  }

  /// Approves/rejects [id]'s current pending Invoice stage. `remarks`
  /// is required by the reject flow (enforced by the Reject dialog
  /// before this is ever called); approve doesn't collect one.
  Future<InvoiceRequest> submitDecision({
    required int id,
    required bool approve,
    String? remarks,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final index = _requests.indexWhere((r) => r.id == id);
    if (index == -1) {
      throw StateError('Invoice Request $id not found');
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
