import 'package:get/get.dart';
import 'package:iungo/features/service_request/domain/entities/service_request_priority.dart';
import 'package:iungo/features/work_order/domain/entities/work_order_filter.dart';
import 'package:iungo/features/work_order/domain/entities/work_order_status.dart';

/// The subset of [WorkOrderListController] that [WorkOrderFilterPage]
/// actually needs. Implemented by both the real, API-backed list
/// controller and the static, locally-seeded one so the exact same
/// Filter screen UI can drive either.
abstract class WorkOrderFilterControllerLike {
  Rx<WorkOrderFilter> get filter;
  Rxn<int> get findTicketId;
  RxList<WorkOrderStatus> get statusFilterOptions;
  RxList<ServiceRequestPriority> get priorityFilterOptions;

  Future<void> ensureFilterOptionsLoaded();
  void applyFilter(WorkOrderFilter newFilter);
  void clearFilter();
  void findTicket(int serialNumber);
}
