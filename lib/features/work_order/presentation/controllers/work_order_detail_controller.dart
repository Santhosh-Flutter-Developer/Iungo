import 'dart:async';

import 'package:get/get.dart';
import 'package:iungo/core/widgets/app_snackbar.dart';
import 'package:iungo/features/work_order/data/datasources/work_order_exceptions.dart';
import 'package:iungo/features/work_order/data/work_order_repository.dart';
import 'package:iungo/features/work_order/domain/entities/work_order.dart';
import 'package:iungo/features/work_order/domain/entities/work_order_attachment.dart';
import 'package:iungo/features/work_order/domain/entities/work_order_comment.dart';
import 'package:iungo/features/work_order/domain/entities/work_order_status.dart';
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
  WorkOrderDetailController(
    this._repository,
    WorkOrder initial, {
    this.staticMode = false,
  }) : workOrder = initial.obs;

  final WorkOrderRepository _repository;

  /// When true, this Detail View is one of the static "Awaiting for
  /// Pause/Closure Approval" placeholder lists — the overview shows the
  /// [initial] work order as-is (no re-fetch by id) and Tasks/Comments/
  /// Attachments simply render their existing empty states, since there
  /// is no backing API to call yet.
  final bool staticMode;

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

  // ---- Approve / Reject (Awaiting Closure Approval from Client) ----

  /// True while an approve/reject submission is in flight — lets the
  /// Detail View disable the action buttons and show a spinner so a
  /// double-tap can't fire the request twice once the API is wired up.
  final RxBool isSubmittingApproval = false.obs;

  @override
  void onInit() {
    super.onInit();
    _updateCountdown();
    _ticker =
        Timer.periodic(const Duration(seconds: 1), (_) => _updateCountdown());

    if (staticMode) {
      // No backing API yet — show the seeded work order as-is and leave
      // Tasks/Comments/Attachments at their empty state.
      isLoading.value = false;
      isLoadingTasks.value = false;
      isLoadingComments.value = false;
      isLoadingAttachments.value = false;
      return;
    }

    _loadDetail();
    _loadTasks();
    _loadComments();
    _loadAttachments();
  }

  void _updateCountdown() {
    final dueDate = workOrder.value.dueDate;
    if (dueDate == null) {
      // No due date from the API — the Overview tab hides the
      // countdown pill entirely in this case, so this value is unused,
      // but keep it well-defined rather than leaving the last stale
      // countdown (e.g. right after a re-fetch drops the due date).
      dueCountdown.value = '';
      return;
    }

    final now = DateTime.now();
    var remaining = dueDate.difference(now);
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
    if (staticMode) return;
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
    if (staticMode) return;
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
    if (staticMode) return;
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
    if (staticMode) return;
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

  // ---- Approve / Reject ---------------------------------------------

  /// Approves the work order's current "Awaiting Pause/Closure Approval
  /// from Client" state via the Portal API's transition endpoint (see
  /// [WorkOrderRepository.submitTransition]). The `stateTransitionId`
  /// sent is looked up from the order's *current* status (
  /// [WorkOrderStatusX.approveTransitionId]) so the same method works
  /// for both Pause and Closure approval — a no-op if the order isn't
  /// actually in one of those statuses (shouldn't happen, since
  /// [WorkOrderApprovalActionBar] only shows the buttons then).
  ///
  /// No remarks field is offered for Approve, so an empty comment is
  /// sent — [WorkOrderApprovalActionBar] already guards this behind a
  /// confirmation dialog and disables itself while
  /// [isSubmittingApproval] is true.
  Future<void> approveRequest() async {
    final transitionId = order.status.approveTransitionId;
    if (transitionId == null) return;

    isSubmittingApproval.value = true;
    try {
      await _repository.submitTransition(
        workOrderId: order.id,
        stateTransitionId: transitionId,
        comment: '',
      );
      AppSnackbar.showSuccess('approve_success'.tr);
      await _loadDetail();
    } on WorkOrderException catch (e) {
      AppSnackbar.showError(
        e.message.trim().isNotEmpty ? e.message : 'something_went_wrong'.tr,
      );
    } catch (_) {
      AppSnackbar.showError('something_went_wrong'.tr);
    } finally {
      isSubmittingApproval.value = false;
    }
  }

  /// Rejects the work order's current "Awaiting Pause/Closure Approval
  /// from Client" state with a mandatory [remarks] explanation — the
  /// Reject dialog already enforces non-empty remarks before this is
  /// called. Same [WorkOrderStatusX.rejectTransitionId] lookup as
  /// [approveRequest].
  Future<void> rejectRequest(String remarks) async {
    final transitionId = order.status.rejectTransitionId;
    if (transitionId == null) return;

    isSubmittingApproval.value = true;
    try {
      await _repository.submitTransition(
        workOrderId: order.id,
        stateTransitionId: transitionId,
        comment: remarks,
      );
      AppSnackbar.showSuccess('reject_success'.tr);
      await _loadDetail();
    } on WorkOrderException catch (e) {
      AppSnackbar.showError(
        e.message.trim().isNotEmpty ? e.message : 'something_went_wrong'.tr,
      );
    } catch (_) {
      AppSnackbar.showError('something_went_wrong'.tr);
    } finally {
      isSubmittingApproval.value = false;
    }
  }

  @override
  void onClose() {
    _ticker?.cancel();
    super.onClose();
  }
}