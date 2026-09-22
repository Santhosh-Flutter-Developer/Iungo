import 'package:iungo/features/grn_request/data/datasources/grn_remote_data_source.dart';
import 'package:iungo/features/grn_request/data/models/grn_decision_request.dart';
import 'package:iungo/features/purchase_request/data/datasources/pr_create_remote_data_source.dart';
import 'package:iungo/features/purchase_request/data/models/pr_list_query.dart';
import 'package:iungo/features/purchase_request/domain/entities/contract_option.dart';
import 'package:iungo/features/purchase_request/domain/entities/pr_list_page.dart';
import 'package:iungo/features/service_request/domain/entities/attachment_file.dart';

/// Everything the GRN Dashboard / Detail / Search screens need from the
/// GRN API — the paginated list, the contract picklist (reusing the
/// same `fetch_contract_code` call the PR feature already makes),
/// delivery-note upload, and the approve/reject actions. Registered as
/// a single permanent instance (see `GrnDashboardBinding`). Mirrors
/// `PurchaseRequestRepository` shape for shape.
class GrnRequestRepository {
  GrnRequestRepository(this._remote, this._createRemote);

  final GrnRemoteDataSource _remote;

  /// Reused for `fetch_contract_code` (same contracts as the PR
  /// Dashboard) and the generic multipart uploader.
  final PrCreateRemoteDataSource _createRemote;

  Future<PrListPage> fetchGrnRequests(PrListQuery query) =>
      _remote.fetchGrnRequests(query);

  Future<List<ContractOption>> fetchContracts({required String userId}) =>
      _createRemote.fetchContracts(userId: userId);

  /// Uploads one delivery-note file and returns its stored filename —
  /// the same multipart endpoint the PR "Add Purchase Request" flow
  /// uses for quotation attachments, with `field: 'delivery_notes'` so
  /// the server files it under the GRN stage.
  Future<String> uploadDeliveryNote(AttachmentFile file) {
    return _createRemote.uploadAttachment(file, field: 'delivery_notes');
  }

  /// Approves [grnId] with the delivery note filenames attached so far
  /// (at least one — enforced by [GrnDecisionValidator] before this is
  /// ever called).
  Future<String?> approveGrnRequest({
    required int grnId,
    required String userId,
    required List<String> deliveryNoteFileNames,
  }) {
    return _remote.submitDecision(
      GrnDecisionRequest.approve(
        grnId: grnId,
        userId: userId,
        deliveryNoteFileNames: deliveryNoteFileNames,
      ),
    );
  }

  /// Rejects [grnId] with mandatory [remarks].
  Future<String?> rejectGrnRequest({
    required int grnId,
    required String userId,
    required String remarks,
  }) {
    return _remote.submitDecision(
      GrnDecisionRequest.reject(
        grnId: grnId,
        userId: userId,
        remarks: remarks,
      ),
    );
  }
}
