import 'package:iungo/features/invoice_request/data/datasources/invoice_remote_data_source.dart';
import 'package:iungo/features/invoice_request/data/models/invoice_decision_request.dart';
import 'package:iungo/features/purchase_request/data/datasources/pr_create_remote_data_source.dart';
import 'package:iungo/features/purchase_request/data/models/pr_list_query.dart';
import 'package:iungo/features/purchase_request/domain/entities/contract_option.dart';
import 'package:iungo/features/purchase_request/domain/entities/pr_list_page.dart';
import 'package:iungo/features/service_request/domain/entities/attachment_file.dart';

/// Everything the Invoice Dashboard / Detail / Search screens need from
/// the Invoice API — the paginated list, the contract picklist (reusing
/// the same `fetch_contract_code` call the PR/GRN features already
/// make), invoice-attachment upload, and the approve/reject actions.
/// Registered as a single permanent instance (see
/// `InvoiceDashboardBinding`). Mirrors `GrnRequestRepository` shape for
/// shape.
class InvoiceRequestRepository {
  InvoiceRequestRepository(this._remote, this._createRemote);

  final InvoiceRemoteDataSource _remote;

  /// Reused for `fetch_contract_code` (same contracts as the PR/GRN
  /// Dashboards) and the generic multipart uploader.
  final PrCreateRemoteDataSource _createRemote;

  Future<PrListPage> fetchInvoiceRequests(PrListQuery query) =>
      _remote.fetchInvoiceRequests(query);

  Future<List<ContractOption>> fetchContracts({required String userId}) =>
      _createRemote.fetchContracts(userId: userId);

  /// Uploads one invoice attachment and returns its stored filename —
  /// the same multipart endpoint the PR "Add Purchase Request" flow uses
  /// for quotation attachments, with `field: 'invoices'` so the server
  /// files it under the Invoice stage.
  Future<String> uploadInvoiceAttachment(AttachmentFile file) {
    return _createRemote.uploadAttachment(file, field: 'invoices');
  }

  /// Approves [invoiceId] with the invoice attachment filenames attached
  /// so far (may be empty — the API guide's own approve example sends
  /// none).
  Future<String?> approveInvoiceRequest({
    required int invoiceId,
    required String userId,
    required List<String> invoiceFileNames,
  }) {
    return _remote.submitDecision(
      InvoiceDecisionRequest.approve(
        invoiceId: invoiceId,
        userId: userId,
        invoiceFileNames: invoiceFileNames,
      ),
    );
  }

  /// Rejects [invoiceId] with mandatory [remarks].
  Future<String?> rejectInvoiceRequest({
    required int invoiceId,
    required String userId,
    required String remarks,
  }) {
    return _remote.submitDecision(
      InvoiceDecisionRequest.reject(
        invoiceId: invoiceId,
        userId: userId,
        remarks: remarks,
      ),
    );
  }
}
