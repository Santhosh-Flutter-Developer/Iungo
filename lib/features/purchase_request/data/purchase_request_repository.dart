import 'package:iungo/features/purchase_request/data/datasources/pr_create_remote_data_source.dart';
import 'package:iungo/features/purchase_request/data/datasources/pr_remote_data_source.dart';
import 'package:iungo/features/purchase_request/data/models/pr_decision_request.dart';
import 'package:iungo/features/purchase_request/data/models/pr_list_query.dart';
import 'package:iungo/features/purchase_request/domain/entities/contract_option.dart';
import 'package:iungo/features/purchase_request/domain/entities/pr_list_page.dart';

/// Everything the PR Dashboard / Detail / Search screens need from the
/// Purchase Request API — the paginated list, the contract picklist and
/// the approve/reject actions. Registered as a single permanent instance
/// (see `PrDashboardBinding`). It holds no per-user state: the logged-in
/// user's id is always passed in by the caller from the session.
///
/// The record returned by the list API already carries the full detail
/// (items, attachments, pipeline...), so there is deliberately no
/// separate "fetch details" call — the API guide documents none.
class PurchaseRequestRepository {
  PurchaseRequestRepository(this._remote, this._createRemote);

  final PrRemoteDataSource _remote;

  /// Reused for `fetch_contract_code`, which the Add Purchase Request
  /// form already calls.
  final PrCreateRemoteDataSource _createRemote;

  Future<PrListPage> fetchPurchaseRequests(PrListQuery query) =>
      _remote.fetchPurchaseRequests(query);

  Future<List<ContractOption>> fetchContracts({required String userId}) =>
      _createRemote.fetchContracts(userId: userId);

  /// Approves [prId] with exactly one selected attachment
  /// ([attachmentFileName]). Returns the server's message.
  Future<String?> approvePurchaseRequest({
    required int prId,
    required String userId,
    required String attachmentFileName,
  }) {
    return _remote.submitDecision(
      PrDecisionRequest.approve(
        prId: prId,
        userId: userId,
        attachmentFileName: attachmentFileName,
      ),
    );
  }

  /// Rejects [prId] with mandatory [remarks].
  Future<String?> rejectPurchaseRequest({
    required int prId,
    required String userId,
    required String remarks,
  }) {
    return _remote.submitDecision(
      PrDecisionRequest.reject(
        prId: prId,
        userId: userId,
        remarks: remarks,
      ),
    );
  }
}
