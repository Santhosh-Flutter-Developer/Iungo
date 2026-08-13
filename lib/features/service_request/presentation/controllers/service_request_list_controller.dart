import 'package:get/get.dart';
import 'package:iungo/features/service_request/data/service_request_repository.dart';
import 'package:iungo/features/service_request/domain/entities/service_request.dart';
import 'package:iungo/features/service_request/domain/entities/service_request_filter.dart';

class ServiceRequestListController extends GetxController {
  ServiceRequestListController(this._repository);

  final ServiceRequestRepository _repository;

  final RxBool isLoading = true.obs;
  final Rx<ServiceRequestFilter> filter = const ServiceRequestFilter().obs;

  /// Ticket id typed on the "Find Ticket" tab, once "Find Ticket" is
  /// pressed. Cleared whenever the Filter tab's own filters change.
  final Rxn<int> findTicketId = Rxn<int>();

  @override
  void onInit() {
    super.onInit();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    isLoading.value = true;
    // Brief, deliberate delay so the shimmer loading state (matching the
    // reference video) is visible instead of flashing instantly.
    await Future.delayed(const Duration(milliseconds: 700));
    isLoading.value = false;
  }

  Future<void> reload() => _loadTickets();

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
