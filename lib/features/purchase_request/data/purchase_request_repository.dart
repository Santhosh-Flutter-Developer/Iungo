import 'package:iungo/features/purchase_request/data/purchase_request_seed_data.dart';
import 'package:iungo/features/purchase_request/domain/entities/purchase_request.dart';
import 'package:iungo/features/purchase_request/domain/entities/purchase_request_item.dart';
import 'package:iungo/features/purchase_request/domain/entities/purchase_request_status.dart';

/// Local, in-memory stand-in for the future Purchase Request API.
///
/// UI-only for now, per the current task: every method already has the
/// async shape (`Future`, simulated network delay) the real
/// implementation will need, so swapping the body for a live Dio call
/// later shouldn't require touching any controller/page that depends on
/// this class. Registered as a single permanent instance (see
/// `PrDashboardBinding`) so the list, detail, search, filter, and create
/// screens all read/write the same in-memory data set.
class PurchaseRequestRepository {
  PurchaseRequestRepository() : _requests = buildPurchaseRequestSeed();

  final List<PurchaseRequest> _requests;

  /// Contract picklist — mirrors the "Contract Code" dropdown on the
  /// reference "Add Purchase Request" form / the list's "Select
  /// Contract" filter.
  static const List<String> contracts = [
    'Diriyah - DIR',
    'Riyadh - RYD',
    'Jeddah - JED',
    'Dammam - DMM',
  ];

  Future<List<PurchaseRequest>> fetchAll() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.unmodifiable(_requests);
  }

  /// Approves/rejects [id]'s current pending stage. `remarks` is
  /// required by the reject flow (enforced by the Reject dialog before
  /// this is ever called); approve doesn't collect one.
  Future<PurchaseRequest> submitDecision({
    required int id,
    required bool approve,
    String? remarks,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final index = _requests.indexWhere((r) => r.id == id);
    if (index == -1) {
      throw StateError('Purchase Request $id not found');
    }
    final updated = _requests[index].copyWith(
      status: approve
          ? PurchaseRequestStatus.approved
          : PurchaseRequestStatus.rejected,
      clearNextApprovalName: true,
    );
    _requests[index] = updated;
    return updated;
  }

  /// Inserts a newly-created Purchase Request (the "Add Purchase
  /// Request" form's Submit action) and assigns it a sequential id/PR
  /// number in the same "<ContractPrefix>-<YY>-<seq>" shape as the seed
  /// data.
  Future<PurchaseRequest> addPurchaseRequest({
    required String contract,
    required String location,
    required String workOrderNo,
    required String requestDescription,
    required DateTime deliveryDate,
    required String category,
    required String purpose,
    required List<PurchaseRequestItem> items,
    List<String> quotationFileNames = const [],
  }) async {
    await Future.delayed(const Duration(milliseconds: 700));

    final nextId =
        _requests.fold<int>(0, (max, r) => r.id > max ? r.id : max) + 1;
    final now = DateTime.now();
    final prefix = contract.split('-').last.trim();
    final year = (now.year % 100).toString().padLeft(2, '0');
    final sequence = nextId.toString().padLeft(4, '0');

    final created = PurchaseRequest(
      id: nextId,
      prNumber: '$prefix-$year-$sequence',
      requestDate: now,
      contract: contract,
      location: location,
      workOrderNo: workOrderNo,
      requestDescription: requestDescription,
      deliveryDate: deliveryDate,
      category: category,
      purpose: purpose,
      createdBy: 'You',
      status: PurchaseRequestStatus.pending,
      nextApprovalName: 'Pending assignment',
      currentStage: 1,
      totalStages: 1,
      items: items,
      quotationFileNames: quotationFileNames,
    );

    _requests.insert(0, created);
    return created;
  }
}