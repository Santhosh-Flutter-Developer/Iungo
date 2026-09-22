import 'package:iungo/features/purchase_request/domain/entities/purchase_request_filter.dart';

export 'package:iungo/features/purchase_request/domain/entities/purchase_request_filter.dart'
    show PurchaseRequestFilter;

/// The GRN Filter screen's Contract/Created-date criteria are sent the
/// same way the PR Dashboard's are (`search_data.contract_search` /
/// `search_data.pr_date`), so this reuses [PurchaseRequestFilter]
/// directly instead of a byte-for-byte GRN copy.
typedef GrnRequestFilter = PurchaseRequestFilter;
