import 'package:flutter/material.dart';

/// Status a work order can be in — drives the colored pill/banner on
/// each list card, and populates the "Select Status" filter dropdown.
/// Order matches the reference "Select Status" dropdown exactly (not
/// alphabetical).
enum WorkOrderStatus {
  submitted,
  assigned,
  workInProgress,
  incomplete,
  preOpen,
  requested,
  rejected,
  reOpened,
  awaitingApproval,
  awaitingPauseApprovalFromClient,
  inventoryRequestRaised,
  materialIssued,
  awaitingQcTeamApproval,
  awaitingClosureApprovalFromClient,
  closed,
}

extension WorkOrderStatusX on WorkOrderStatus {
  String get labelKey {
    switch (this) {
      case WorkOrderStatus.submitted:
        return 'wo_status_submitted';
      case WorkOrderStatus.assigned:
        return 'wo_status_assigned';
      case WorkOrderStatus.workInProgress:
        return 'wo_status_work_in_progress';
      case WorkOrderStatus.incomplete:
        return 'wo_status_incomplete';
      case WorkOrderStatus.preOpen:
        return 'wo_status_pre_open';
      case WorkOrderStatus.requested:
        return 'wo_status_requested';
      case WorkOrderStatus.rejected:
        return 'wo_status_rejected';
      case WorkOrderStatus.reOpened:
        return 'wo_status_re_opened';
      case WorkOrderStatus.awaitingApproval:
        return 'wo_status_awaiting_approval';
      case WorkOrderStatus.awaitingPauseApprovalFromClient:
        return 'wo_status_awaiting_pause_approval_from_client';
      case WorkOrderStatus.inventoryRequestRaised:
        return 'wo_status_inventory_request_raised';
      case WorkOrderStatus.materialIssued:
        return 'wo_status_material_issued';
      case WorkOrderStatus.awaitingQcTeamApproval:
        return 'wo_status_awaiting_qc_team_approval';
      case WorkOrderStatus.awaitingClosureApprovalFromClient:
        return 'wo_status_awaiting_closure_approval_from_client';
      case WorkOrderStatus.closed:
        return 'wo_status_closed';
    }
  }

  /// Background color of the status pill/banner on the list card and
  /// Detail View — sampled from the reference screenshots.
  Color get color {
    switch (this) {
      case WorkOrderStatus.submitted:
        return const Color(0xFF6C7A89);
      case WorkOrderStatus.assigned:
        return const Color(0xFF4079AE);
      case WorkOrderStatus.workInProgress:
        return const Color(0xFFC7C14F);
      case WorkOrderStatus.incomplete:
        return const Color(0xFFB3261E);
      case WorkOrderStatus.preOpen:
        return const Color(0xFF8A8F98);
      case WorkOrderStatus.requested:
        return const Color(0xFF2E7D9E);
      case WorkOrderStatus.rejected:
        return const Color(0xFFB3261E);
      case WorkOrderStatus.reOpened:
        return const Color(0xFFC77A1E);
      case WorkOrderStatus.awaitingApproval:
        return const Color(0xFF7B1E3A);
      case WorkOrderStatus.awaitingPauseApprovalFromClient:
        return const Color(0xFF8B2B57);
      case WorkOrderStatus.inventoryRequestRaised:
        return const Color(0xFF3F6FA8);
      case WorkOrderStatus.materialIssued:
        return const Color(0xFF2E8B74);
      case WorkOrderStatus.awaitingQcTeamApproval:
        return const Color(0xFF6B3FA0);
      case WorkOrderStatus.awaitingClosureApprovalFromClient:
        return const Color(0xFF973265);
      case WorkOrderStatus.closed:
        return const Color(0xFF3D8B4E);
    }
  }

  /// True for the handful of long status labels that don't fit next to
  /// the id chip on a single row — those render as a full-width banner
  /// on the row below instead (matches the reference screenshots, e.g.
  /// "Awaiting Closure Approval from Client").
  bool get isLongLabel {
    switch (this) {
      case WorkOrderStatus.awaitingPauseApprovalFromClient:
      case WorkOrderStatus.awaitingQcTeamApproval:
      case WorkOrderStatus.awaitingClosureApprovalFromClient:
      case WorkOrderStatus.inventoryRequestRaised:
        return true;
      default:
        return false;
    }
  }

  /// Options offered in the filter dropdown — exact order from the
  /// reference "Select Status" screenshot.
  static const List<WorkOrderStatus> filterOptions = WorkOrderStatus.values;

  /// Maps a label as returned by the server (either the ticket's expanded
  /// `moduleState.status`/`displayName`, or a
  /// `pickList/.../moduleState` option's `label`) onto the fixed enum.
  /// Unknown/blank labels fall back to [assigned].
  static WorkOrderStatus fromApiLabel(String? label) {
    final normalized =
        (label ?? '').toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    switch (normalized) {
      case 'submitted':
        return WorkOrderStatus.submitted;
      case 'assigned':
        return WorkOrderStatus.assigned;
      case 'workinprogress':
        return WorkOrderStatus.workInProgress;
      case 'incomplete':
        return WorkOrderStatus.incomplete;
      case 'preopen':
        return WorkOrderStatus.preOpen;
      case 'requested':
        return WorkOrderStatus.requested;
      case 'rejected':
        return WorkOrderStatus.rejected;
      case 'reopened':
        return WorkOrderStatus.reOpened;
      case 'awaitingapproval':
        return WorkOrderStatus.awaitingApproval;
      case 'awaitingpauseapprovalfromclient':
        return WorkOrderStatus.awaitingPauseApprovalFromClient;
      case 'inventoryrequestraised':
        return WorkOrderStatus.inventoryRequestRaised;
      case 'materialissued':
        return WorkOrderStatus.materialIssued;
      case 'awaitingqcteamapproval':
        return WorkOrderStatus.awaitingQcTeamApproval;
      case 'awaitingclosureapprovalfromclient':
        return WorkOrderStatus.awaitingClosureApprovalFromClient;
      case 'closed':
        return WorkOrderStatus.closed;
      default:
        return WorkOrderStatus.assigned;
    }
  }
}