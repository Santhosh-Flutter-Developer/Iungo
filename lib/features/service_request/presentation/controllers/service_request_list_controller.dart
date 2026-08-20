import 'package:get/get.dart';
import 'package:iungo/features/service_request/data/service_request_repository.dart';
import 'package:iungo/features/service_request/domain/entities/service_request.dart';
import 'package:iungo/features/service_request/domain/entities/service_request_filter.dart';

class ServiceRequestListController extends GetxController {
  ServiceRequestListController(this._repository);

  final ServiceRequestRepository _repository;

  static const int _perPage = 10;

  /// True only while the very first page is loading (drives the shimmer).
  final RxBool isLoading = true.obs;

  /// True while a subsequent page is being fetched (drives the small
  /// spinner at the bottom of the list during infinite scroll).
  final RxBool isLoadingMore = false.obs;

  /// True when the first-page load failed outright (drives the
  /// full-screen error/retry state).
  final RxBool hasError = false.obs;

  /// False once a page comes back with fewer than [_perPage] items —
  /// i.e. there's nothing further to fetch.
  final RxBool hasMore = true.obs;

  final Rx<ServiceRequestFilter> filter = const ServiceRequestFilter().obs;

  /// Ticket id typed on the "Find Ticket" tab, once "Find Ticket" is
  /// pressed. Cleared whenever the Filter tab's own filters change.
  final Rxn<int> findTicketId = Rxn<int>();

  int _page = 1;

  @override
  void onInit() {
    super.onInit();
    _loadFirstPage();
  }

  Future<void> _loadFirstPage() async {
    isLoading.value = true;
    hasError.value = false;
    _page = 1;
    try {
      final result = await _repository.fetchPage(
        page: _page,
        perPage: _perPage,
      );
      _repository.replaceWithPage(result.tickets);
      hasMore.value = result.rawCount >= _perPage;
    } catch (_) {
      hasError.value = true;
      hasMore.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Called when the list is scrolled near its end. Fetches the next
  /// page of 10 and appends it — a no-op while already loading, once a
  /// page comes back short, or while a ticket-id/filter narrows the view
  /// (pagination only drives the base, unfiltered list).
  Future<void> loadMore() async {
    if (isLoading.value || isLoadingMore.value || !hasMore.value) return;
    if (hasActiveFilter) return;

    isLoadingMore.value = true;
    try {
      final nextPage = _page + 1;
      final result = await _repository.fetchPage(
        page: nextPage,
        perPage: _perPage,
      );
      _repository.appendPage(result.tickets);
      _page = nextPage;
      hasMore.value = result.rawCount >= _perPage;
    } catch (_) {
      // Silently keep [hasMore] as-is so the user can retry by scrolling
      // again; a persistent bottom spinner would be misleading here.
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> reload() => _loadFirstPage();

  List<ServiceRequest> get filteredTickets {
    final all = _repository.tickets;
    final ticketId = findTicketId.value;
    if (ticketId != null) {
      return all.where((t) => t.id == ticketId).toList();
    }

    final f = filter.value;
    return all.where((t) {
      if (f.type != null && t.type != f.type) return false;
      if (f.status != null && t.status != f.status) return false;
      if (f.priority != null && t.priority != f.priority) return false;
      if (f.dueDateStart != null && t.dueDate.isBefore(f.dueDateStart!)) {
        return false;
      }
      if (f.dueDateEnd != null &&
          t.dueDate.isAfter(f.dueDateEnd!.add(const Duration(days: 1)))) {
        return false;
      }
      return true;
    }).toList();
  }

  void applyFilter(ServiceRequestFilter newFilter) {
    findTicketId.value = null;
    filter.value = newFilter;
  }

  void clearFilter() {
    findTicketId.value = null;
    filter.value = const ServiceRequestFilter();
  }

  void findTicket(int id) {
    findTicketId.value = id;
  }

  bool get hasActiveFilter => !filter.value.isEmpty || findTicketId.value != null;
}
