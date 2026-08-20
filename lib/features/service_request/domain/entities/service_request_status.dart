import 'package:flutter/material.dart';
import 'package:iungo/core/constants/app_colors.dart';

/// Status a service request ticket can be in — drives the colored pill on
/// each list card, and populates the "Select Status" filter dropdown.
enum ServiceRequestStatus {
  acknowledged,
  awaitingApproval,
  closed,
  convertedAsWorkorder,
  onHold,
  open,
  rejected,
}

extension ServiceRequestStatusX on ServiceRequestStatus {
  String get labelKey {
    switch (this) {
      case ServiceRequestStatus.acknowledged:
        return 'status_acknowledged';
      case ServiceRequestStatus.awaitingApproval:
        return 'status_awaiting_approval';
      case ServiceRequestStatus.closed:
        return 'status_closed';
      case ServiceRequestStatus.convertedAsWorkorder:
        return 'status_converted_as_workorder';
      case ServiceRequestStatus.onHold:
        return 'status_on_hold';
      case ServiceRequestStatus.open:
        return 'status_open';
      case ServiceRequestStatus.rejected:
        return 'status_rejected';
    }
  }

  /// Background color of the status pill on the list card.
  Color get color {
    switch (this) {
      case ServiceRequestStatus.acknowledged:
        return const Color(0xFF2E7D32);
      case ServiceRequestStatus.awaitingApproval:
        return const Color(0xFF7B1E3A);
      case ServiceRequestStatus.closed:
        return const Color(0xFF4C8C2B);
      case ServiceRequestStatus.convertedAsWorkorder:
        return const Color(0xFF808A1E);
      case ServiceRequestStatus.onHold:
        return const Color(0xFFB07B14);
      case ServiceRequestStatus.open:
        return AppColors.primary;
      case ServiceRequestStatus.rejected:
        return const Color(0xFFB3261E);
    }
  }

  /// Statuses offered in the filter dropdown, alphabetically — matches the
  /// reference screenshot ordering exactly. Used as a fallback if the
  /// live `pickList/.../moduleState` fetch fails.
  static const List<ServiceRequestStatus> filterOptions = [
    ServiceRequestStatus.acknowledged,
    ServiceRequestStatus.awaitingApproval,
    ServiceRequestStatus.closed,
    ServiceRequestStatus.convertedAsWorkorder,
    ServiceRequestStatus.onHold,
    ServiceRequestStatus.open,
    ServiceRequestStatus.rejected,
  ];

  /// Maps a label as returned by the server (either the ticket's expanded
  /// `moduleState.status`/`displayName`, or a `pickList/.../moduleState`
  /// option's `label`) onto the fixed enum. Unknown/blank labels fall
  /// back to [open].
  static ServiceRequestStatus fromApiLabel(String? label) {
    final normalized =
        (label ?? '').toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    switch (normalized) {
      case 'acknowledged':
        return ServiceRequestStatus.acknowledged;
      case 'awaitingapproval':
        return ServiceRequestStatus.awaitingApproval;
      case 'closed':
        return ServiceRequestStatus.closed;
      case 'convertedasworkorder':
        return ServiceRequestStatus.convertedAsWorkorder;
      case 'onhold':
        return ServiceRequestStatus.onHold;
      case 'open':
        return ServiceRequestStatus.open;
      case 'rejected':
        return ServiceRequestStatus.rejected;
      default:
        return ServiceRequestStatus.open;
    }
  }
}