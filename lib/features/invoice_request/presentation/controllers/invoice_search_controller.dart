import 'dart:async';

import 'package:get/get.dart';
import 'package:iungo/core/services/session_service.dart';
import 'package:iungo/core/widgets/app_snackbar.dart';
import 'package:iungo/features/invoice_request/data/invoice_request_repository.dart';
import 'package:iungo/features/invoice_request/domain/entities/invoice_request.dart';
import 'package:iungo/features/invoice_request/domain/entities/invoice_search_scope.dart';
import 'package:iungo/features/invoice_request/presentation/controllers/invoice_dashboard_controller.dart';
import 'package:iungo/features/purchase_request/data/models/pr_list_query.dart';
import 'package:iungo/features/purchase_request/domain/entities/pr_list_page.dart';
import 'package:iungo/features/purchase_request/presentation/utils/pr_error_message.dart';
import 'package:iungo/features/purchase_request/presentation/utils/pr_session.dart';

/// Search screen controller for the Invoice Dashboard. Searches the
/// SERVER on the dashboard's current tab, mirroring `GrnSearchController`
/// exactly: Number goes in `search_data.pr_number`, Contract in
/// `search_data.contract_search`, "All Fields" runs and merges both.
class InvoiceSearchController extends GetxController {
  InvoiceSearchController(this._repository, this._session, this._dashboard);

  final InvoiceRequestRepository _repository;
  final SessionService _session;
  final InvoiceDashboardController _dashboard;

  static const _debounceDuration = Duration(milliseconds: 400);
  static const int _resultLimit = 50;

  final RxString query = ''.obs;
  final Rx<InvoiceSearchScope> scope = InvoiceSearchScope.allFields.obs;
  final RxBool isSearching = false.obs;
  final RxBool hasSearched = false.obs;
  final RxList<InvoiceRequest> results = <InvoiceRequest>[].obs;

  Timer? _debounce;
  int _searchToken = 0;

  bool get canDecide => _dashboard.isActionRequiredTab;

  void onQueryChanged(String value) {
    query.value = value;
    _debounce?.cancel();

    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      _searchToken++;
      isSearching.value = false;
      hasSearched.value = false;
      results.clear();
      return;
    }

    isSearching.value = true;
    _debounce = Timer(_debounceDuration, () => _runSearch(trimmed));
  }

  void onScopeChanged(InvoiceSearchScope newScope) {
    scope.value = newScope;
    final trimmed = query.value.trim();
    if (trimmed.isEmpty) return;
    _debounce?.cancel();
    isSearching.value = true;
    _runSearch(trimmed);
  }

  void onQuerySubmitted(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    _debounce?.cancel();
    isSearching.value = true;
    _runSearch(trimmed);
  }

  Future<void> refreshResults() async {
    _dashboard.reload();
    final trimmed = query.value.trim();
    if (trimmed.isEmpty) return;
    await _runSearch(trimmed);
  }

  Future<void> _runSearch(String trimmed) async {
    final token = ++_searchToken;
    try {
      final userId = requirePrUserId(_session);
      final type = _dashboard.currentType;
      final pageLogin = _dashboard.currentPageLogin;

      Future<PrListPage> fetch({
        String prNumber = '',
        List<String> contracts = const [],
      }) {
        return _repository.fetchInvoiceRequests(
          PrListQuery(
            userId: userId,
            types: type,
            pageLogin: pageLogin,
            pageNumber: 1,
            pageLimit: _resultLimit,
            prNumber: prNumber,
            contractSearch: contracts,
          ),
        );
      }

      final pages = switch (scope.value) {
        InvoiceSearchScope.number => [await fetch(prNumber: trimmed)],
        InvoiceSearchScope.contract => [await fetch(contracts: [trimmed])],
        InvoiceSearchScope.allFields => await Future.wait([
            fetch(prNumber: trimmed),
            fetch(contracts: [trimmed]),
          ]),
      };
      if (token != _searchToken) return;

      final seen = <int>{};
      final merged = <InvoiceRequest>[];
      for (final page in pages) {
        for (final record in page.records) {
          if (seen.add(record.id)) merged.add(record);
        }
      }
      results.assignAll(merged);
    } catch (e) {
      if (token != _searchToken) return;
      results.clear();
      AppSnackbar.showError(
        prErrorMessage(e, fallbackKey: 'invoice_load_failed'),
      );
    } finally {
      if (token == _searchToken) {
        isSearching.value = false;
        hasSearched.value = true;
      }
    }
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
}
