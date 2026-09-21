import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/routes/app_routes.dart';
import 'package:iungo/core/services/session_service.dart';
import 'package:iungo/core/widgets/app_snackbar.dart';
import 'package:iungo/core/widgets/approval_dialogs.dart';
import 'package:iungo/features/purchase_request/data/models/pr_list_query.dart';
import 'package:iungo/features/purchase_request/data/pr_excel_exporter.dart';
import 'package:iungo/features/purchase_request/data/purchase_request_repository.dart';
import 'package:iungo/features/purchase_request/domain/entities/contract_option.dart';
import 'package:iungo/features/purchase_request/domain/entities/pr_attachment.dart';
import 'package:iungo/features/purchase_request/domain/entities/pr_list_page.dart';
import 'package:iungo/features/purchase_request/domain/entities/pr_list_type.dart';
import 'package:iungo/features/purchase_request/domain/entities/purchase_request.dart';
import 'package:iungo/features/purchase_request/domain/entities/purchase_request_filter.dart';
import 'package:iungo/features/purchase_request/domain/validators/pr_decision_validator.dart';
import 'package:iungo/features/purchase_request/presentation/controllers/pr_filter_controller_like.dart';
import 'package:iungo/features/purchase_request/presentation/controllers/pr_role_controller.dart';
import 'package:iungo/features/purchase_request/presentation/utils/pr_error_message.dart';
import 'package:iungo/features/purchase_request/presentation/utils/pr_session.dart';
import 'package:iungo/features/purchase_request/presentation/widgets/pr_attachment_select_sheet.dart';

/// Drives the PR Dashboard list screen — the three status tiles
/// (Submitted / Action Required, Completed, Rejected) that double as tab
/// selectors, the Contract / Created-date filter, the PR-number search,
/// lazy-loading pagination and the inline Approve/Reject on cards — all
/// backed by the live Purchase Request API.
///
/// One list is shown at a time. Switching tab, applying/clearing a
/// filter or search, or pulling to refresh all RESET it to page 1; every
/// reset bumps [_requestToken], so a response that arrives after the
/// list has been reset (a slow page 2 of the previous tab, say) is
/// discarded instead of being appended to the wrong list.
class PrDashboardController extends GetxController
    implements PrFilterControllerLike {
  PrDashboardController(
    this._repository,
    this._session,
    this._roleController,
  );

  final PurchaseRequestRepository _repository;
  final SessionService _session;
  final PrRoleController _roleController;

  /// `page_limit` sent with every list request.
  static const int pageLimit = 20;

  // ---- list state ------------------------------------------------------

  /// True while the first page (or a reset) is loading — drives the
  /// full-list shimmer.
  final RxBool isLoading = true.obs;

  /// True while the next page is loading — drives the bottom spinner.
  final RxBool isLoadingMore = false.obs;

  /// The first page failed outright (drives the full-screen error).
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;

  /// The last "load more" failed; auto-loading pauses until the user
  /// taps Retry so a flaky connection can't fire a request per scroll
  /// tick.
  final RxBool loadMoreFailed = false.obs;

  final RxBool hasMore = false.obs;
  final RxInt currentPage = 0.obs;
  final RxInt totalPages = 0.obs;
  final RxInt totalRecords = 0.obs;

  /// The records loaded so far for the selected tab (pages appended in
  /// order).
  final RxList<PurchaseRequest> records = <PurchaseRequest>[].obs;

  /// 0 = Submitted (requestor) / Action Required (approver),
  /// 1 = Completed, 2 = Rejected.
  final RxInt selectedTab = 0.obs;

  // ---- tile counts (straight from the API) -----------------------------

  final RxInt pendingCount = 0.obs;
  final RxInt completedCount = 0.obs;
  final RxInt rejectedCount = 0.obs;

  /// `add_purchase_request == 1` from the list response.
  final RxBool canAddPurchaseRequest = false.obs;

  final RxBool isExporting = false.obs;

  /// Ids currently mid approve/reject submission from the list's inline
  /// buttons — lets each card disable/spin independently.
  final RxSet<int> _submittingIds = <int>{}.obs;

  bool isSubmitting(int id) => _submittingIds.contains(id);

  // ---- filter / search state -------------------------------------------

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

  // ---- derived ---------------------------------------------------------

  /// The `types` / `page_login` value of the selected tab for the
  /// logged-in user's role.
  String get currentType =>
      PrListType.forTab(_roleController.role, selectedTab.value);

  /// The `page_login` value for the logged-in role (`Created` for a
  /// requestor, `O` for an approver) — the same on every tab.
  String get currentPageLogin => PrListType.pageLoginFor(_roleController.role);

  /// Whether the selected tab is the approver's Action Required list.
  bool get isActionRequiredTab =>
      PrListType.isActionRequired(_roleController.role, currentType);

  bool get hasActiveFilter =>
      !filter.value.isEmpty || findPrNumber.value != null;

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  // ---- loading ---------------------------------------------------------

  /// Clears the list and loads page 1 with the full-list loader.
  Future<void> reload() => _loadFirstPage(showLoader: true);

  /// Pull-to-refresh: reloads page 1 under the refresh spinner. The old
  /// records are replaced (never appended to) once page 1 arrives; if the
  /// refresh fails the list on screen is kept and an error is shown.
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
          await _repository.fetchPurchaseRequests(_buildQuery(page: 1));
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
      final message = prErrorMessage(e, fallbackKey: 'pr_load_failed');
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

  /// Fetches the next page (same tab, same search/filter) and APPENDS it.
  /// A no-op while a load is running (prevents duplicate requests when
  /// the user keeps scrolling at the bottom), once everything is loaded,
  /// or while a previous "load more" failure awaits a Retry.
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
      final page =
          await _repository.fetchPurchaseRequests(_buildQuery(page: nextPage));
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
      AppSnackbar.showError(prErrorMessage(e, fallbackKey: 'pr_load_failed'));
    } finally {
      if (token == _requestToken) isLoadingMore.value = false;
    }
  }

  /// The Retry action shown at the bottom of the list after a failed
  /// "load more".
  Future<void> retryLoadMore() {
    loadMoreFailed.value = false;
    return loadMore();
  }

  /// More pages exist only while: this page returned something new, we
  /// haven't reached the last page, and fewer records are loaded than
  /// the API says exist.
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

    // Tile counts come from the API. Only if a count is missing from the
    // response is the selected tab's own count approximated with the
    // page's total.
    final tab = selectedTab.value;
    pendingCount.value = page.createdStatusCount ??
        (tab == 0 ? page.totalRecords : pendingCount.value);
    completedCount.value = page.completedStatusCount ??
        (tab == 1 ? page.totalRecords : completedCount.value);
    rejectedCount.value = page.rejectedStatusCount ??
        (tab == 2 ? page.totalRecords : rejectedCount.value);

    canAddPurchaseRequest.value = page.addPurchaseRequest == true;
  }

  List<PurchaseRequest> _unique(Iterable<PurchaseRequest> items) {
    final seen = <int>{};
    return [
      for (final item in items)
        if (seen.add(item.id)) item,
    ];
  }

  // ---- contracts (Filter screen dropdown) ------------------------------

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

  // ---- filter / search -------------------------------------------------

  /// Applies the Contract / Created-date filter: back to page 1 with the
  /// old records cleared, then a fresh server request.
  @override
  void applyFilter(PurchaseRequestFilter newFilter) {
    filter.value = newFilter;
    reload();
  }

  /// Clears the contract, date and PR number, then reloads the current
  /// tab from page 1.
  @override
  void clearFilter() {
    findPrNumber.value = null;
    filter.value = const PurchaseRequestFilter();
    reload();
  }

  /// Server-side PR-number search (`search_data.pr_number`) on the
  /// current tab, combined with whatever filter is active. An empty
  /// number clears the search.
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

  // ---- export ----------------------------------------------------------

  /// Exports the records loaded so far for the selected tab to an
  /// `.xlsx` file and opens it — mirrors the export icon above the table
  /// in the reference web app.
  Future<void> exportToExcel() async {
    final rows = records.toList();
    if (rows.isEmpty) {
      AppSnackbar.showError('export_excel_empty'.tr);
      return;
    }

    isExporting.value = true;
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await PrExcelExporter.exportAndOpen(
        requests: rows,
        sheetName: 'Purchase Requests',
        fileName: 'purchase_requests_$timestamp.xlsx',
      );
      AppSnackbar.showSuccess('export_excel_success'.tr);
    } catch (_) {
      AppSnackbar.showError('export_excel_failed'.tr);
    } finally {
      isExporting.value = false;
    }
  }

  // ---- approve / reject from the list card -----------------------------

  /// Approve from a card (approver, Action Required tab only). An
  /// approval needs exactly one attachment, so the approver picks it in a
  /// small sheet first, then confirms, then the API is called.
  Future<void> approveFromList(
    BuildContext context,
    PurchaseRequest request,
  ) async {
    if (isSubmitting(request.id)) return;

    // No attachment on the request means nothing can be selected, so it
    // can't be approved (the API needs exactly one).
    if (request.attachments.isEmpty) {
      AppSnackbar.showError('pr_select_one_attachment'.tr);
      return;
    }

    final attachment =
        await showPrAttachmentSelectSheet(context, request.attachments);
    if (attachment == null) return;
    if (!context.mounted) return;

    final confirmed = await showApproveRequestDialog(context);
    if (confirmed != true) return;

    await _submitApprove(request, attachment);
  }

  /// Reject from a card: the Reject dialog collects the mandatory
  /// remarks, then the API is called.
  Future<void> rejectFromList(
    BuildContext context,
    PurchaseRequest request,
  ) async {
    if (isSubmitting(request.id)) return;

    final remarks = await showRejectRequestDialog(context);
    if (remarks == null) return;

    final errorKey = PrDecisionValidator.rejectRemarksErrorKey(remarks);
    if (errorKey != null) {
      AppSnackbar.showError(errorKey.tr);
      return;
    }

    await _submitReject(request, remarks.trim());
  }

  Future<void> _submitApprove(
    PurchaseRequest request,
    PrAttachment attachment,
  ) async {
    // Same rule as the Detail View, checked again right before the call.
    final errorKey = PrDecisionValidator.approveSelectionErrorKey(
      [attachment.apiFileName],
    );
    if (errorKey != null) {
      AppSnackbar.showError(errorKey.tr);
      return;
    }

    _submittingIds.add(request.id);
    try {
      await _repository.approvePurchaseRequest(
        prId: request.id,
        userId: requirePrUserId(_session),
        attachmentFileName: attachment.apiFileName,
      );
      AppSnackbar.showSuccess('approve_success'.tr);
      // The server decides where the request goes next (Completed, ...) —
      // reload the list and the tile counts from it.
      await reload();
    } catch (e) {
      AppSnackbar.showError(prErrorMessage(e, fallbackKey: 'pr_approve_failed'));
    } finally {
      _submittingIds.remove(request.id);
    }
  }

  Future<void> _submitReject(PurchaseRequest request, String remarks) async {
    _submittingIds.add(request.id);
    try {
      await _repository.rejectPurchaseRequest(
        prId: request.id,
        userId: requirePrUserId(_session),
        remarks: remarks,
      );
      AppSnackbar.showSuccess('reject_success'.tr);
      await reload();
    } catch (e) {
      AppSnackbar.showError(prErrorMessage(e, fallbackKey: 'pr_reject_failed'));
    } finally {
      _submittingIds.remove(request.id);
    }
  }
}
