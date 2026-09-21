import 'package:iungo/features/purchase_request/domain/entities/contract_option.dart';

/// Everything selected on the PR Dashboard's Filter screen. Immutable —
/// the controller swaps in a new instance whenever a value changes.
/// Mirrors `InventoryRequestFilter`'s shape, with Contract in place of
/// Reservation Status.
class PurchaseRequestFilter {
  const PurchaseRequestFilter({
    this.contract,
    this.createdDateStart,
    this.createdDateEnd,
  });

  /// The contract picked from the `fetch_contract_code` list.
  final ContractOption? contract;
  final DateTime? createdDateStart;
  final DateTime? createdDateEnd;

  bool get isEmpty =>
      contract == null && createdDateStart == null && createdDateEnd == null;

  /// `search_data.contract_search` — the selected contract's NAME
  /// (e.g. `Diriyah`), or an empty list when none is selected.
  List<String> get contractSearch {
    final name = contract?.contractName.trim() ?? '';
    return name.isEmpty ? const [] : [name];
  }

  /// `search_data.pr_date` — `YYYY-MM-DD - YYYY-MM-DD`, or an empty
  /// string when no date range is selected.
  String get apiDateRange {
    final start = createdDateStart;
    final end = createdDateEnd;
    if (start == null || end == null) return '';
    return '${_ymd(start)} - ${_ymd(end)}';
  }

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  PurchaseRequestFilter copyWith({
    ContractOption? contract,
    bool clearContract = false,
    DateTime? createdDateStart,
    DateTime? createdDateEnd,
    bool clearCreatedDate = false,
  }) {
    return PurchaseRequestFilter(
      contract: clearContract ? null : (contract ?? this.contract),
      createdDateStart:
          clearCreatedDate ? null : (createdDateStart ?? this.createdDateStart),
      createdDateEnd:
          clearCreatedDate ? null : (createdDateEnd ?? this.createdDateEnd),
    );
  }
}
