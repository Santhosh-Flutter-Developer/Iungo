import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:iungo/core/services/session_service.dart';
import 'package:iungo/features/work_order/data/datasources/work_order_pause_approval_remote_data_source.dart';
import 'package:iungo/features/work_order/data/datasources/work_order_picklist_remote_data_source.dart';
import 'package:iungo/features/work_order/data/work_order_pause_approval_repository.dart';
import 'package:iungo/features/work_order/presentation/bindings/work_order_list_binding.dart';
import 'package:iungo/features/work_order/presentation/controllers/work_order_pause_approval_list_controller.dart';

/// Registers the "Awaiting for Pause Approval" data source/repository
/// and its list controller. Mirrors [WorkOrderClosureApprovalListBinding]
/// exactly, reusing the shared Dio client and pick-list data source that
/// [WorkOrderListBinding.ensureRepositoryRegistered] already registers
/// (those aren't view-specific) rather than duplicating them.
class WorkOrderPauseApprovalListBinding extends Bindings {
  @override
  void dependencies() {
    // Shared Dio client + pick-list data source (used by "All Work
    // Orders" too) + the "All Work Orders" repository, which Detail
    // View navigation reuses regardless of which list a ticket was
    // opened from.
    WorkOrderListBinding.ensureRepositoryRegistered();

    ensurePauseApprovalRepositoryRegistered();

    Get.lazyPut<WorkOrderPauseApprovalListController>(
      () => WorkOrderPauseApprovalListController(
        Get.find<WorkOrderPauseApprovalRepository>(),
      ),
      fenix: true,
    );
  }

  /// Registers the pause-approval-specific remote data source and
  /// repository if they aren't already — shared by any entry point that
  /// needs them (list page, search) regardless of which one runs first.
  static void ensurePauseApprovalRepositoryRegistered() {
    if (!Get.isRegistered<WorkOrderPauseApprovalRemoteDataSource>()) {
      Get.lazyPut<WorkOrderPauseApprovalRemoteDataSource>(
        () => WorkOrderPauseApprovalRemoteDataSourceImpl(
          Get.find<Dio>(),
          Get.find<SessionService>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<WorkOrderPauseApprovalRepository>()) {
      Get.put(
        WorkOrderPauseApprovalRepository(
          Get.find<WorkOrderPauseApprovalRemoteDataSource>(),
          Get.find<WorkOrderPickListRemoteDataSource>(),
        ),
        permanent: true,
      );
    }
  }
}
