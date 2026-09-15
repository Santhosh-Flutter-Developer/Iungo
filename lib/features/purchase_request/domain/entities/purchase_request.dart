import 'package:iungo/features/purchase_request/domain/entities/purchase_request_item.dart';
import 'package:iungo/features/purchase_request/domain/entities/purchase_request_status.dart';

/// A single Purchase Request record — backs the PR Dashboard list card,
/// the Detail View's Summary/Requested Supply Items tabs, and is what
/// the "Add Purchase Request" form builds on submit. Field names mirror
/// the reference video (PR Number, Request Date, Contract, Total,
/// Status, Next Approval/Stage, General Specification fields, and the
/// VAT/administrative-expenses breakdown).
class PurchaseRequest {
  const PurchaseRequest({
    required this.id,
    required this.prNumber,
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
  });

  final int id;

  /// e.g. "DIR-26-0029" — contract prefix + 2-digit year + sequence.
  final String prNumber;
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

  /// Name of the person this PR is currently waiting on — null once
  /// approved/rejected, matches the list's "Next Approval" column.
  final String? nextApprovalName;

  /// e.g. stage 1 of 3 in the approval pipeline.
  final int currentStage;
  final int totalStages;

  final double administrativeExpensesPercent;
  final List<PurchaseRequestItem> items;

  /// File names of every uploaded quotation attachment — multiple are
  /// allowed, matching the "Add Purchase Request" form.
  final List<String> quotationFileNames;

  double get totalLines => items.fold(0.0, (sum, item) => sum + item.total);

  double get administrativeExpensesAmount =>
      totalLines * administrativeExpensesPercent / 100;

  double get totalBeforeVat => totalLines + administrativeExpensesAmount;

  /// Fixed 15% Saudi VAT rate, matching every total shown in the
  /// reference video.
  double get vatAmount => totalBeforeVat * 0.15;

  double get totalAmount => totalBeforeVat + vatAmount;

  bool get isPendingApproval => status == PurchaseRequestStatus.pending;

  PurchaseRequest copyWith({
    PurchaseRequestStatus? status,
    String? nextApprovalName,
    bool clearNextApprovalName = false,
    int? currentStage,
  }) {
    return PurchaseRequest(
      id: id,
      prNumber: prNumber,
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
    );
  }
}