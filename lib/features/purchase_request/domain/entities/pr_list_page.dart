import 'package:iungo/features/purchase_request/domain/entities/pr_filter_options.dart';
import 'package:iungo/features/purchase_request/domain/entities/purchase_request.dart';

/// One page of the Purchase Request list API (`data` of the response):
/// the records plus everything the dashboard needs around them —
/// pagination info, the three tab counts, the Add-button flag and the
/// filter options.
class PrListPage {
  const PrListPage({
    required this.records,
    required this.pageNumber,
    required this.pageLimit,
    required this.totalRecords,
    required this.totalPages,
    this.startRecord,
    this.endRecord,
    this.addPurchaseRequest,
    this.createdStatusCount,
    this.completedStatusCount,
    this.rejectedStatusCount,
    this.filterOptions = PrFilterOptions.empty,
  });

  final List<PurchaseRequest> records;
  final int pageNumber;
  final int pageLimit;
  final int totalRecords;
  final int totalPages;
  final int? startRecord;
  final int? endRecord;

  /// `add_purchase_request == 1`; null when the response didn't say.
  final bool? addPurchaseRequest;

  /// `created_status_count` — the Submitted (requestor) / Action
  /// Required (approver) tile.
  final int? createdStatusCount;
  final int? completedStatusCount;
  final int? rejectedStatusCount;

  final PrFilterOptions filterOptions;
}
