import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/routes/app_routes.dart';
import 'package:iungo/core/widgets/app_snackbar.dart';
import 'package:iungo/core/widgets/approval_dialogs.dart';
import 'package:iungo/features/invoice_request/data/invoice_excel_exporter.dart';
import 'package:iungo/features/invoice_request/data/invoice_request_repository.dart';
import 'package:iungo/features/invoice_request/domain/entities/invoice_request.dart';
import 'package:iungo/features/invoice_request/domain/entities/invoice_request_filter.dart';
import 'package:iungo/features/invoice_request/presentation/controllers/invoice_filter_controller_like.dart';
import 'package:iungo/features/purchase_request/domain/entities/purchase_request_status.dart';

/// Drives the Invoice Dashboard list screen — the three status tiles
/// (Action required/Submitted, Completed, Rejected) that double as tab
/// selectors, the Contract/Created-date filter, and the underlying
/// [InvoiceRequestRepository] fetch. Mirrors `GrnDashboardController`
/// shape for shape.
class InvoiceDashboardController extends GetxController
    implements InvoiceFilterControllerLike {
  InvoiceDashboardController(this._repository);

  final InvoiceRequestRepository _repository;

  final RxBool isLoading = true.obs;
  final RxBool hasError = false.obs;

  final RxList<InvoiceRequest> _allRequests = <InvoiceRequest>[].obs;

  /// 0 = Pending ("Action required" / "Submitted" depending on role),
  /// 1 = Completed (Approved), 2 = Rejected.
  final RxInt selectedTab = 0.obs;

  final RxBool isExporting = false.obs;

  /// Ids currently mid approve/reject submission from the list's inline
  /// buttons — lets each card disable/spin independently.
  final RxSet<int> _submittingIds = <int>{}.obs;

  bool isSubmitting(int id) => _submittingIds.contains(id);

  @override
  final Rx<InvoiceRequestFilter> filter = const InvoiceRequestFilter().obs;

  @override
  final Rxn<String> findNumber = Rxn<String>();

  @override
  List<String> get contractOptions => InvoiceRequestRepository.contracts;

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  Future<void> reload() async {
    isLoading.value = true;
    hasError.value = false;
    try {
      final requests = await _repository.fetchAll();
      _allRequests.assignAll(requests);
    } catch (_) {
      hasError.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  void selectTab(int index) => selectedTab.value = index;

  List<InvoiceRequest> get _dateAndContractFiltered {
    var results = _allRequests.toList();

    final contract = filter.value.contract;
    if (contract != null) {
      results = results.where((r) => r.contract == contract).toList();
    }

    final start = filter.value.createdDateStart;
    final end = filter.value.createdDateEnd;
    if (start != null && end != null) {
      final startOfDay = DateTime(start.year, start.month, start.day);
      final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);
      results = results
          .where((r) =>
              !r.requestDate.isBefore(startOfDay) &&
              !r.requestDate.isAfter(endOfDay))
          .toList();
    }

    final numberQuery = findNumber.value;
    if (numberQuery != null && numberQuery.isNotEmpty) {
      final lower = numberQuery.toLowerCase();
      results =
          results.where((r) => r.number.toLowerCase().contains(lower)).toList();
    }

    return results;
  }

  /// The list the currently-selected tab should show, after the
  /// Contract/Created-date filter is applied.
  List<InvoiceRequest> get visibleRequests {
    final status = switch (selectedTab.value) {
      1 => PurchaseRequestStatus.approved,
      2 => PurchaseRequestStatus.rejected,
      _ => PurchaseRequestStatus.pending,
    };
    return _dateAndContractFiltered.where((r) => r.status == status).toList()
      ..sort((a, b) => b.requestDate.compareTo(a.requestDate));
  }

  int get pendingCount => _dateAndContractFiltered
      .where((r) => r.status == PurchaseRequestStatus.pending)
      .length;

  int get completedCount => _dateAndContractFiltered
      .where((r) => r.status == PurchaseRequestStatus.approved)
      .length;

  int get rejectedCount => _dateAndContractFiltered
      .where((r) => r.status == PurchaseRequestStatus.rejected)
      .length;

  bool get hasActiveFilter =>
      !filter.value.isEmpty || findNumber.value != null;

  @override
  void applyFilter(InvoiceRequestFilter newFilter) {
    filter.value = newFilter;
  }

  @override
  void clearFilter() {
    findNumber.value = null;
    filter.value = const InvoiceRequestFilter();
  }

  @override
  void findTicket(String number) {
    final trimmed = number.trim();
    findNumber.value = trimmed.isEmpty ? null : trimmed;
  }

  void onNotificationsTap() {
    Get.toNamed(AppRoutes.notifications);
  }

  /// Exports the currently-visible (tab + filter applied) list to an
  /// `.xlsx` file and opens it — mirrors the export icon above the
  /// table in the reference web app.
  Future<void> exportToExcel() async {
    final rows = visibleRequests;
    if (rows.isEmpty) {
      AppSnackbar.showError('export_excel_empty'.tr);
      return;
    }

    isExporting.value = true;
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await InvoiceExcelExporter.exportAndOpen(
        requests: rows,
        sheetName: 'Invoice Requests',
        fileName: 'invoice_requests_$timestamp.xlsx',
      );
      AppSnackbar.showSuccess('export_excel_success'.tr);
    } catch (_) {
      AppSnackbar.showError('export_excel_failed'.tr);
    } finally {
      isExporting.value = false;
    }
  }

  /// Confirms then approves [request] directly from the list card
  /// (approver role, pending tab only).
  Future<void> approveFromList(
      BuildContext context, InvoiceRequest request) async {
    final confirmed = await showApproveRequestDialog(context);
    if (confirmed != true) return;
    await _submitDecision(id: request.id, approve: true);
  }

  /// Confirms (with mandatory remarks) then rejects [request] directly
  /// from the list card.
  Future<void> rejectFromList(
      BuildContext context, InvoiceRequest request) async {
    final remarks = await showRejectRequestDialog(context);
    if (remarks == null || remarks.trim().isEmpty) return;
    await _submitDecision(id: request.id, approve: false, remarks: remarks.trim());
  }

  Future<void> _submitDecision({
    required int id,
    required bool approve,
    String? remarks,
  }) async {
    _submittingIds.add(id);
    try {
      final updated = await _repository.submitDecision(
        id: id,
        approve: approve,
        remarks: remarks,
      );
      final index = _allRequests.indexWhere((r) => r.id == id);
      if (index != -1) _allRequests[index] = updated;
      AppSnackbar.showSuccess(
        approve ? 'approve_success'.tr : 'reject_success'.tr,
      );
    } catch (_) {
      AppSnackbar.showError('something_went_wrong'.tr);
    } finally {
      _submittingIds.remove(id);
    }
  }
}
