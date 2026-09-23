import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/routes/app_routes.dart';
import 'package:iungo/core/services/session_service.dart';
import 'package:iungo/core/widgets/app_snackbar.dart';
import 'package:iungo/core/widgets/approval_dialogs.dart';
import 'package:iungo/features/invoice_request/data/invoice_excel_exporter.dart';
import 'package:iungo/features/invoice_request/data/invoice_request_repository.dart';
import 'package:iungo/features/invoice_request/domain/entities/invoice_request.dart';
import 'package:iungo/features/invoice_request/domain/validators/invoice_decision_validator.dart';
import 'package:iungo/features/purchase_request/data/models/pr_list_query.dart';
import 'package:iungo/features/purchase_request/domain/entities/contract_option.dart';
import 'package:iungo/features/purchase_request/domain/entities/pr_list_page.dart';
import 'package:iungo/features/purchase_request/domain/entities/pr_list_type.dart';
import 'package:iungo/features/purchase_request/domain/entities/purchase_request_filter.dart';
import 'package:iungo/features/purchase_request/presentation/controllers/pr_filter_controller_like.dart';
import 'package:iungo/features/purchase_request/presentation/controllers/pr_role_controller.dart';
import 'package:iungo/features/purchase_request/presentation/utils/pr_error_message.dart';
import 'package:iungo/features/purchase_request/presentation/utils/pr_session.dart';

/// Drives the Invoice Dashboard list screen. Mirrors
/// `GrnDashboardController` exactly (pagination, tabs, tile counts,
/// Contract/date filter, PR-number search, inline card approve/reject)
/// except: there is never an "Add" button on the Invoice Dashboard, and
/// approving here does not require a pre-attached invoice file (the API
/// guide's own approve example sends an empty `invoices` list).
class InvoiceDashboardController extends GetxController
    implements PrFilterControllerLike {
  InvoiceDashboardController(
    this._repository,
    this._session,
    this._roleController,
  );

  final InvoiceRequestRepository _repository;
  final SessionService _session;
  final PrRoleController _roleController;

  static const int pageLimit = 20;

  final RxBool isLoading = true.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool loadMoreFailed = false.obs;

  final RxBool hasMore = false.obs;
  final RxInt currentPage = 0.obs;
  final RxInt totalPages = 0.obs;
  final RxInt totalRecords = 0.obs;

  final RxList<InvoiceRequest> records = <InvoiceRequest>[].obs;

  /// 0 = Submitted (requestor) / Action Required (approver), 1 =
  /// Completed, 2 = Rejected.
  final RxInt selectedTab = 0.obs;

  final RxInt pendingCount = 0.obs;
  final RxInt completedCount = 0.obs;
  final RxInt rejectedCount = 0.obs;

  final RxBool isExporting = false.obs;

  final RxSet<int> _submittingIds = <int>{}.obs;

  bool isSubmitting(int id) => _submittingIds.contains(id);

  @override
  final Rx<PurchaseRequestFilter> filter = const PurchaseRequestFilter().obs;

  @override
  final Rxn<String> findPrNumber = Rxn<String>();

  @override
  final RxList<ContractOption> contractOptions = <ContractOption>[].obs;

  @override
  final RxBool isLoadingContracts = false.obs;

  @override
  final Rxn<String> contractsError = Rxn<String>();

  int _requestToken = 0;

  String get currentType =>
      PrListType.forTab(_roleController.role, selectedTab.value);

  String get currentPageLogin => PrListType.pageLoginFor(_roleController.role);

  bool get isActionRequiredTab =>
      PrListType.isActionRequired(_roleController.role, currentType);

  bool get hasActiveFilter =>
      !filter.value.isEmpty || findPrNumber.value != null;

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  Future<void> reload() => _loadFirstPage(showLoader: true);

  Future<void> refreshList() => _loadFirstPage(showLoader: false);

  void selectTab(int index) {
    if (index == selectedTab.value) return;
    selectedTab.value = index;
    reload();
  }

  PrListQuery _buildQuery({required int page}) {
    return PrListQuery(
      userId: requirePrUserId(_session),
      types: currentType,
      pageLogin: currentPageLogin,
      pageNumber: page,
      pageLimit: pageLimit,
      prNumber: findPrNumber.value?.trim() ?? '',
      prDate: filter.value.apiDateRange,
      contractSearch: filter.value.contractSearch,
    );
  }

  Future<void> _loadFirstPage({required bool showLoader}) async {
    final token = ++_requestToken;

    isLoadingMore.value = false;
    loadMoreFailed.value = false;
    hasError.value = false;
    errorMessage.value = '';

    if (showLoader) {
      records.clear();
      hasMore.value = false;
      currentPage.value = 0;
      totalPages.value = 0;
      totalRecords.value = 0;
      isLoading.value = true;
    }

    try {
      final page =
          await _repository.fetchInvoiceRequests(_buildQuery(page: 1));
      if (token != _requestToken) return;

      final unique = _unique(page.records);
      records.assignAll(unique);
      currentPage.value = 1;
      _applyPageMeta(page);
      hasMore.value = _computeHasMore(
        page: 1,
        pageRecordCount: page.records.length,
        addedCount: unique.length,
      );
    } catch (e) {
      if (token != _requestToken) return;
      final message = prErrorMessage(e, fallbackKey: 'invoice_load_failed');
      if (showLoader || records.isEmpty) {
        records.clear();
        hasMore.value = false;
        hasError.value = true;
        errorMessage.value = message;
      } else {
        AppSnackbar.showError(message);
      }
    } finally {
      if (token == _requestToken) isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoading.value ||
        isLoadingMore.value ||
        !hasMore.value ||
        loadMoreFailed.value) {
      return;
    }

    final token = _requestToken;
    final nextPage = currentPage.value + 1;
    isLoadingMore.value = true;

    try {
      final page = await _repository
          .fetchInvoiceRequests(_buildQuery(page: nextPage));
      if (token != _requestToken) return;

      final known = records.map((r) => r.id).toSet();
      final fresh = _unique(page.records).where((r) => !known.contains(r.id));
      final added = fresh.toList();
      records.addAll(added);

      currentPage.value = nextPage;
      _applyPageMeta(page);
      hasMore.value = _computeHasMore(
        page: nextPage,
        pageRecordCount: page.records.length,
        addedCount: added.length,
      );
    } catch (e) {
      if (token != _requestToken) return;
      loadMoreFailed.value = true;
      AppSnackbar.showError(
        prErrorMessage(e, fallbackKey: 'invoice_load_failed'),
      );
    } finally {
      if (token == _requestToken) isLoadingMore.value = false;
    }
  }

  Future<void> retryLoadMore() {
    loadMoreFailed.value = false;
    return loadMore();
  }

  bool _computeHasMore({
    required int page,
    required int pageRecordCount,
    required int addedCount,
  }) {
    return pageRecordCount > 0 &&
        addedCount > 0 &&
        page < totalPages.value &&
        records.length < totalRecords.value;
  }

  void _applyPageMeta(PrListPage page) {
    totalPages.value = page.totalPages;
    totalRecords.value = page.totalRecords;

    final tab = selectedTab.value;
    pendingCount.value = page.createdStatusCount ??
        (tab == 0 ? page.totalRecords : pendingCount.value);
    completedCount.value = page.completedStatusCount ??
        (tab == 1 ? page.totalRecords : completedCount.value);
    rejectedCount.value = page.rejectedStatusCount ??
        (tab == 2 ? page.totalRecords : rejectedCount.value);
  }

  List<InvoiceRequest> _unique(Iterable<InvoiceRequest> items) {
    final seen = <int>{};
    return [
      for (final item in items)
        if (seen.add(item.id)) item,
    ];
  }

  @override
  Future<void> ensureContractsLoaded() async {
    if (contractOptions.isNotEmpty || isLoadingContracts.value) return;
    await reloadContracts();
  }

  @override
  Future<void> reloadContracts() async {
    if (isLoadingContracts.value) return;
    isLoadingContracts.value = true;
    contractsError.value = null;
    try {
      final result = await _repository.fetchContracts(
        userId: requirePrUserId(_session),
      );
      contractOptions.assignAll(result);
    } catch (e) {
      contractsError.value =
          prErrorMessage(e, fallbackKey: 'pr_contract_load_failed');
    } finally {
      isLoadingContracts.value = false;
    }
  }

  @override
  void applyFilter(PurchaseRequestFilter newFilter) {
    filter.value = newFilter;
    reload();
  }

  @override
  void clearFilter() {
    findPrNumber.value = null;
    filter.value = const PurchaseRequestFilter();
    reload();
  }

  @override
  void findTicket(String prNumber) {
    final trimmed = prNumber.trim();
    final next = trimmed.isEmpty ? null : trimmed;
    if (next == null && findPrNumber.value == null) return;
    findPrNumber.value = next;
    reload();
  }

  void onNotificationsTap() {
    Get.toNamed(AppRoutes.notifications);
  }

  Future<void> exportToExcel() async {
    final rows = records.toList();
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

  /// Approve from a card (approver role, pending tab only). Unlike GRN,
  /// no attachment is required to already be present, so this just
  /// confirms and sends whatever invoice attachments the record already
  /// carries.
  Future<void> approveFromList(
    BuildContext context,
    InvoiceRequest request,
  ) async {
    if (isSubmitting(request.id)) return;

    final confirmed = await showApproveRequestDialog(context);
    if (confirmed != true) return;

    final existingNames = [for (final a in request.invoices) a.name];
    await _submitApprove(request, existingNames);
  }

  Future<void> rejectFromList(
    BuildContext context,
    InvoiceRequest request,
  ) async {
    if (isSubmitting(request.id)) return;

    final remarks = await showRejectRequestDialog(context);
    if (remarks == null) return;

    final errorKey = InvoiceDecisionValidator.rejectRemarksErrorKey(remarks);
    if (errorKey != null) {
      AppSnackbar.showError(errorKey.tr);
      return;
    }

    await _submitReject(request, remarks.trim());
  }

  Future<void> _submitApprove(
    InvoiceRequest request,
    List<String> invoiceFileNames,
  ) async {
    _submittingIds.add(request.id);
    try {
      await _repository.approveInvoiceRequest(
        invoiceId: request.id,
        userId: requirePrUserId(_session),
        invoiceFileNames: invoiceFileNames,
      );
      AppSnackbar.showSuccess('approve_success'.tr);
      await reload();
    } catch (e) {
      AppSnackbar.showError(
        prErrorMessage(e, fallbackKey: 'invoice_approve_failed'),
      );
    } finally {
      _submittingIds.remove(request.id);
    }
  }

  Future<void> _submitReject(InvoiceRequest request, String remarks) async {
    _submittingIds.add(request.id);
    try {
      await _repository.rejectInvoiceRequest(
        invoiceId: request.id,
        userId: requirePrUserId(_session),
        remarks: remarks,
      );
      AppSnackbar.showSuccess('reject_success'.tr);
      await reload();
    } catch (e) {
      AppSnackbar.showError(
        prErrorMessage(e, fallbackKey: 'invoice_reject_failed'),
      );
    } finally {
      _submittingIds.remove(request.id);
    }
  }
}
