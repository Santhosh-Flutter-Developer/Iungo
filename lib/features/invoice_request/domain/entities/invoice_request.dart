import 'package:iungo/features/purchase_request/domain/entities/purchase_request_item.dart';
import 'package:iungo/features/purchase_request/domain/entities/purchase_request_status.dart';

/// A single Invoice Dashboard record.
///
/// An Invoice only ever exists for a Purchase Request whose GRN stage
/// has already been completed, so — same reasoning as
/// `GrnRequest` — this reuses [PurchaseRequestStatus]/
/// [PurchaseRequestItem] from the Purchase Request feature directly.
/// [status] here reflects the *Invoice* dashboard's own three tiles
/// (Submitted/Completed/Rejected), independently of the parent PR/GRN
/// status: e.g. a request can be `approved` at both the PR and GRN
/// stages while its Invoice is still `pending` final sign-off — exactly
/// the DIR-26-0028 example in the reference screenshots (Approved in
/// the GRN Dashboard, Pending in the Invoice Dashboard).
class InvoiceRequest {
  const InvoiceRequest({
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

  /// Name of the person this Invoice is currently waiting on — null
  /// once approved/rejected, matches the list's "Next Approval" column.
  final String? nextApprovalName;

  final int currentStage;
  final int totalStages;

  final double administrativeExpensesPercent;
  final List<PurchaseRequestItem> items;

  /// Quotation attachments carried over from the originating Purchase
  /// Request stage — shown on the Summary tab and the Purchase Request
  /// section of the Approval Pipeline sheet.
  final List<String> quotationFileNames;

  /// Delivery note attachments carried over from the GRN stage — shown
  /// on the Detail View's "GRN" tab and the GRN section of the
  /// Approval Pipeline sheet.
  final List<String> deliveryNoteFileNames;

  /// Invoice attachments filed at this stage itself — shown on the
  /// Detail View's "Invoice" tab and the Invoice section of the
  /// Approval Pipeline sheet.
  final List<String> invoiceFileNames;

  double get totalLines => items.fold(0.0, (sum, item) => sum + item.total);

  double get administrativeExpensesAmount =>
      totalLines * administrativeExpensesPercent / 100;

  double get totalBeforeVat => totalLines + administrativeExpensesAmount;

  /// Fixed 15% Saudi VAT rate, matching every total shown in the
  /// reference video.
  double get vatAmount => totalBeforeVat * 0.15;

  double get totalAmount => totalBeforeVat + vatAmount;

  bool get isPendingApproval => status == PurchaseRequestStatus.pending;

  InvoiceRequest copyWith({
    PurchaseRequestStatus? status,
    String? nextApprovalName,
    bool clearNextApprovalName = false,
    int? currentStage,
  }) {
    return InvoiceRequest(
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
    );
  }
}
