import 'package:iungo/features/inventory_request/domain/entities/inventory_line_item.dart';
import 'package:iungo/features/inventory_request/domain/entities/inventory_reservation_status.dart';

/// A single "Inventory Request" record — backs both the "Awaiting Client
/// Approval" list card and the Detail View's Overview tab. Field names
/// mirror the reference admin-panel screenshots (ID, Name, Created Time,
/// Status, Reservation Status, Work Order, Requested For/By, Is Spare
/// Part Request or Not, Created By, plus the Line Items table).
class InventoryRequest {
  const InventoryRequest({
    required this.id,
    required this.name,
    required this.description,
    required this.createdTime,
    required this.requestedTime,
    required this.requiredTime,
    this.status,
    required this.reservationStatus,
    required this.workOrderTitle,
    required this.requestedFor,
    required this.requestedBy,
    required this.isSparePartRequest,
    required this.createdBy,
    required this.clientApprovalAuthorities,
    required this.serviceLine,
    required this.lineItems,
  });

  /// The ticket number shown on every card/Detail View (e.g. "# 1666").
  final int id;

  /// Short request name/title, e.g. "Water leakage was observed from the
  /// angle valve at plot 18 store".
  final String name;

  /// Fuller description shown on the Overview tab.
  final String description;
  final DateTime createdTime;
  final DateTime requestedTime;
  final DateTime requiredTime;

  /// Raw ticket status — null/blank renders as "--" (matches the
  /// reference, which leaves this column empty for most rows).
  final String? status;

  final InventoryReservationStatus reservationStatus;

  /// Title of the linked Work Order, e.g. "Angle Valve Water Leakage".
  final String workOrderTitle;
  final String requestedFor;
  final String requestedBy;
  final bool isSparePartRequest;
  final String createdBy;

  /// Names of the people who can approve this request on the client
  /// side, e.g. ["Khalid Aladwani", "Muhanad AlRubiaan"].
  final List<String> clientApprovalAuthorities;

  /// e.g. "MECHANICAL".
  final String serviceLine;
  final List<InventoryLineItem> lineItems;

  /// Whether this request is currently sitting in the "Awaiting Client
  /// Approval" state — the only state the Detail View's Approve/Reject
  /// actions should be shown for. Falls back to `true` when [status] is
  /// blank, matching [InventoryRequestStatusBadge]'s own fallback: every
  /// record reachable from this screen belongs to that queue, so an
  /// unresolved/blank status is still treated as awaiting approval
  /// rather than hiding the actions.
  bool get isAwaitingClientApproval {
    final trimmed = status?.trim().toLowerCase() ?? '';
    return trimmed.isEmpty || trimmed == 'awaiting client approval';
  }

  /// Returns a copy with [status] replaced — used once the raw
  /// moduleState value parsed off the API has been resolved to its
  /// human-readable label (see
  /// `InventoryRequestRepository.resolveStatusLabel`).
  InventoryRequest copyWith({String? status}) {
    return InventoryRequest(
      id: id,
      name: name,
      description: description,
      createdTime: createdTime,
      requestedTime: requestedTime,
      requiredTime: requiredTime,
      status: status ?? this.status,
      reservationStatus: reservationStatus,
      workOrderTitle: workOrderTitle,
      requestedFor: requestedFor,
      requestedBy: requestedBy,
      isSparePartRequest: isSparePartRequest,
      createdBy: createdBy,
      clientApprovalAuthorities: clientApprovalAuthorities,
      serviceLine: serviceLine,
      lineItems: lineItems,
    );
  }
}