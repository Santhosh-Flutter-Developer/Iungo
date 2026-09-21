import 'package:iungo/features/purchase_request/domain/entities/pr_summary.dart';
import 'package:iungo/features/purchase_request/domain/entities/purchase_request_item.dart';

/// Body of `POST purchase_request.php` with `action: save_purchase_request`.
/// Field names/shape follow the API spec exactly.
class PrSaveRequestModel {
  const PrSaveRequestModel({
    required this.userId,
    required this.creatorName,
    required this.prDate,
    required this.contractId,
    required this.expectDate,
    required this.location,
    required this.workOrderNo,
    required this.purpose,
    required this.category,
    required this.requestDescription,
    required this.totalBeforeVat,
    required this.vatAmount,
    required this.totalAmount,
    required this.margin,
    required this.items,
    required this.attachments,
  });

  /// Logged-in user's `user_id` and `username` (creator name), taken
  /// from the login session.
  final String userId;
  final String creatorName;

  /// `dd-MM-yyyy`.
  final String prDate;
  final String contractId;

  /// `dd-MM-yyyy`.
  final String expectDate;
  final String location;
  final String workOrderNo;
  final String purpose;
  final String category;
  final String requestDescription;
  final double totalBeforeVat;
  final double vatAmount;
  final double totalAmount;

  /// Selected contract's administrative-expense percentage.
  final double margin;
  final List<PurchaseRequestItem> items;

  /// Filenames returned by `file_uploads.php` (`saved_name`).
  final List<String> attachments;

  Map<String, dynamic> toJson() {
    return {
      'action': 'save_purchase_request',
      'user_id': userId,
      'creator_name': creatorName,
      'pr_id': '',
      'pr_date': prDate,
      'contract_id': contractId,
      'expect_date': expectDate,
      'location': location,
      'work_order_no': workOrderNo,
      'p_val': purpose,
      'category': category,
      'total_before_vat': totalBeforeVat,
      'request_description': requestDescription,
      'vat_amount': vatAmount,
      'total_amount': totalAmount,
      'margin': _num(margin),
      'items': [
        for (var i = 0; i < items.length; i++) _itemJson(i + 1, items[i]),
      ],
      'attachments': attachments,
    };
  }

  static Map<String, dynamic> _itemJson(int sno, PurchaseRequestItem item) {
    final isInventory = item.type == PurchaseRequestItemType.inventory;
    return {
      'id': '',
      'sno': sno,
      'material_type': isInventory ? 'Inventory' : 'Non Inventory',
      // Inventory → the material's `name`; Non Inventory → "-".
      'material_code': isInventory ? (item.materialCode ?? '') : '-',
      'material_desc': item.materialDescription,
      'quantity': _num(item.quantity),
      'unit_price': _num(item.unitPrice),
      'total': PrSummary.round2(item.total),
      'remarks': item.remarks,
      // Facilio record id for Inventory rows; empty string otherwise.
      'ids': isInventory ? (item.materialId ?? '') : '',
    };
  }

  /// Whole numbers are sent as ints (`15`, not `15.0`) like the sample.
  static num _num(double value) =>
      value == value.truncateToDouble() ? value.toInt() : value;
}
