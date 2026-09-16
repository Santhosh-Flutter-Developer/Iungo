import 'package:iungo/features/purchase_request/domain/entities/purchase_request_item.dart';
import 'package:iungo/features/purchase_request/domain/entities/purchase_request_status.dart';

/// A single GRN (Goods Received Note) Dashboard record.
///
/// A GRN only ever exists for a Purchase Request that has already been
/// approved, so this reuses [PurchaseRequestStatus]/[PurchaseRequestItem]
/// from the Purchase Request feature directly — the Summary and
/// Requested Supply Items tabs show exactly the same fields the
/// originating PR carried. [status] here reflects the *GRN* dashboard's
/// own three tiles (Submitted/Completed/Rejected — see
/// `GrnDashboardController`), which can lag behind the parent PR: e.g.
/// a request can be `approved` at the PR stage while its GRN is still
/// `pending` goods receipt confirmation.
class GrnRequest {
  const GrnRequest({
    required this.id,
    required this.number,
    required this.requestDate,
    required this.contract,
    required this.location,
    required this.workOrderNo,
    required this.requestDescription,
    required this.deliveryDate,
    required this.category,
    required this.purpose,
    required this.createdBy,
    required this.status,
    this.nextApprovalName,
    required this.currentStage,
    required this.totalStages,
    this.administrativeExpensesPercent = 0,
    required this.items,
    this.quotationFileNames = const [],
    this.deliveryNoteFileNames = const [],
    this.invoiceFileNames = const [],
    this.invoicePending = false,
  });

  final int id;

  /// e.g. "DIR-26-0028" — same numbering series as its originating PR.
  final String number;
  final DateTime requestDate;

  /// e.g. "Diriyah - DIR".
  final String contract;
  final String location;
  final String workOrderNo;
  final String requestDescription;
  final DateTime deliveryDate;
  final String category;
  final String purpose;
  final String createdBy;

  final PurchaseRequestStatus status;

  /// Name of the person this GRN is currently waiting on — null once
  /// approved/rejected, matches the list's "Next Approval" column.
  final String? nextApprovalName;

  final int currentStage;
  final int totalStages;

  final double administrativeExpensesPercent;
  final List<PurchaseRequestItem> items;

  /// Quotation attachments carried over from the originating Purchase
  /// Request stage — shown on the Summary tab and the Purchase Request
  /// section of the Approval Pipeline sheet.
  final List<String> quotationFileNames;

  /// Delivery note attachments filed at the GRN stage itself — shown on
  /// the Detail View's "GRN" tab and the GRN section of the Approval
  /// Pipeline sheet.
  final List<String> deliveryNoteFileNames;

  /// Invoice attachments for the downstream Invoice stage — only
  /// relevant to the Approval Pipeline sheet's Invoice section.
  final List<String> invoiceFileNames;

  /// Whether the downstream Invoice stage still has a step waiting
  /// (shown as the last orange dot in the list's Stage column) even
  /// though this GRN itself is fully approved.
  final bool invoicePending;

  double get totalLines => items.fold(0.0, (sum, item) => sum + item.total);

  double get administrativeExpensesAmount =>
      totalLines * administrativeExpensesPercent / 100;

  double get totalBeforeVat => totalLines + administrativeExpensesAmount;

  /// Fixed 15% Saudi VAT rate, matching every total shown in the
  /// reference video.
  double get vatAmount => totalBeforeVat * 0.15;

  double get totalAmount => totalBeforeVat + vatAmount;

  bool get isPendingApproval => status == PurchaseRequestStatus.pending;

  GrnRequest copyWith({
    PurchaseRequestStatus? status,
    String? nextApprovalName,
    bool clearNextApprovalName = false,
    int? currentStage,
  }) {
    return GrnRequest(
      id: id,
      number: number,
      requestDate: requestDate,
      contract: contract,
      location: location,
      workOrderNo: workOrderNo,
      requestDescription: requestDescription,
      deliveryDate: deliveryDate,
      category: category,
      purpose: purpose,
      createdBy: createdBy,
      status: status ?? this.status,
      nextApprovalName: clearNextApprovalName
          ? null
          : (nextApprovalName ?? this.nextApprovalName),
      currentStage: currentStage ?? this.currentStage,
      totalStages: totalStages,
      administrativeExpensesPercent: administrativeExpensesPercent,
      items: items,
      quotationFileNames: quotationFileNames,
      deliveryNoteFileNames: deliveryNoteFileNames,
      invoiceFileNames: invoiceFileNames,
      invoicePending: invoicePending,
    );
  }
}
