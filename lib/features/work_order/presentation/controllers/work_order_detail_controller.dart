import 'dart:async';

import 'package:get/get.dart';
import 'package:iungo/features/work_order/data/datasources/work_order_exceptions.dart';
import 'package:iungo/features/work_order/data/work_order_repository.dart';
import 'package:iungo/features/work_order/domain/entities/work_order.dart';
import 'package:iungo/features/work_order/domain/entities/work_order_attachment.dart';
import 'package:iungo/features/work_order/domain/entities/work_order_comment.dart';
import 'package:iungo/features/work_order/domain/entities/work_order_task.dart';

/// Holds the tab state for one Detail View screen.
///
/// [workOrder] starts out as whatever summary card was tapped (from the
/// list), then a fresh fetch by id replaces it with the richer Detail
/// View record (description, assigned technician/requester, category,
/// etc. — fields the list API doesn't return inline).
///
/// Tasks, Comments and Attachments are each backed by their own API call
/// with their own loading/error state, fetched in parallel with the
/// overview detail on [onInit] so a slow overview fetch doesn't block
/// the other three tabs.
class WorkOrderDetailController extends GetxController {
  WorkOrderDetailController(this._repository, WorkOrder initial)
      : workOrder = initial.obs;

  final WorkOrderRepository _repository;

  /// Convenience accessor — most callers only ever want the current
  /// work order, not the fact that it's reactive.
  WorkOrder get order => workOrder.value;

  final Rx<WorkOrder> workOrder;
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;

  /// Live "Due: HH:MM:SS" (or "-HH:MM:SS" once overdue) — matches the
  /// ticking countdown pill on the Overview tab.
  final RxString dueCountdown = ''.obs;

  Timer? _ticker;

  // ---- Tasks -------------------------------------------------------

  final RxList<WorkOrderTask> tasks = <WorkOrderTask>[].obs;
  final RxInt tasksCompleted = 0.obs;
  final RxInt tasksTotal = 0.obs;
  final RxBool isLoadingTasks = true.obs;
  final RxString tasksError = ''.obs;

  // ---- Comments --------------------------------------------------------

  final RxList<WorkOrderComment> comments = <WorkOrderComment>[].obs;
  final RxBool isLoadingComments = true.obs;
  final RxString commentsError = ''.obs;

  // ---- Attachments -------------------------------------------------------

  final RxList<WorkOrderAttachment> attachments = <WorkOrderAttachment>[].obs;
  final RxBool isLoadingAttachments = true.obs;
  final RxString attachmentsError = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _updateCountdown();
    _ticker =
        Timer.periodic(const Duration(seconds: 1), (_) => _updateCountdown());
    _loadDetail();
    _loadTasks();
    _loadComments();
    _loadAttachments();
  }

  void _updateCountdown() {
    final now = DateTime.now();
    var remaining = workOrder.value.dueDate.difference(now);
    final overdue = remaining.isNegative;
    if (overdue) remaining = -remaining;

    final totalHours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    final seconds = remaining.inSeconds.remainder(60);

    String two(int n) => n.toString().padLeft(2, '0');
    dueCountdown.value =
        '${overdue ? '-' : ''}${two(totalHours)}:${two(minutes)}:${two(seconds)}';
  }

  Future<void> _loadDetail() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final fresh = await _repository.fetchWorkOrderDetail(workOrder.value.id);
      workOrder.value = fresh;
      _updateCountdown();
    } on WorkOrderException catch (e) {
      errorMessage.value =
          e.message.trim().isNotEmpty ? e.message : 'something_went_wrong'.tr;
    } catch (_) {
      errorMessage.value = 'something_went_wrong'.tr;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> retry() => _loadDetail();

  // ---- Tasks -------------------------------------------------------

  Future<void> _loadTasks() async {
    isLoadingTasks.value = true;
    tasksError.value = '';
    try {
      final result = await _repository.fetchTasks(workOrder.value.id);
      tasks.assignAll(result.tasks);
      tasksCompleted.value = result.completed;
      tasksTotal.value = result.total;
    } on WorkOrderException catch (e) {
      tasksError.value =
          e.message.trim().isNotEmpty ? e.message : 'something_went_wrong'.tr;
    } catch (_) {
      tasksError.value = 'something_went_wrong'.tr;
    } finally {
      isLoadingTasks.value = false;
    }
  }

  Future<void> retryTasks() => _loadTasks();

  // ---- Comments --------------------------------------------------------

  Future<void> _loadComments() async {
    isLoadingComments.value = true;
    commentsError.value = '';
    try {
      final fetched = await _repository.fetchComments(workOrder.value.id);
      comments.assignAll(fetched);
    } on WorkOrderException catch (e) {
      commentsError.value =
          e.message.trim().isNotEmpty ? e.message : 'something_went_wrong'.tr;
    } catch (_) {
      commentsError.value = 'something_went_wrong'.tr;
    } finally {
      isLoadingComments.value = false;
    }
  }

  Future<void> retryComments() => _loadComments();

  // ---- Attachments -------------------------------------------------------

  Future<void> _loadAttachments() async {
    isLoadingAttachments.value = true;
    attachmentsError.value = '';
    try {
      final fetched = await _repository.fetchAttachments(workOrder.value.id);
      attachments.assignAll(fetched);
    } on WorkOrderException catch (e) {
      attachmentsError.value =
          e.message.trim().isNotEmpty ? e.message : 'something_went_wrong'.tr;
    } catch (_) {
      attachmentsError.value = 'something_went_wrong'.tr;
    } finally {
      isLoadingAttachments.value = false;
    }
  }

  Future<void> retryAttachments() => _loadAttachments();

  @override
  void onClose() {
    _ticker?.cancel();
    super.onClose();
  }
}
