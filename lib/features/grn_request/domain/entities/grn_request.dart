import 'package:iungo/features/purchase_request/domain/entities/purchase_request.dart';

export 'package:iungo/features/purchase_request/domain/entities/purchase_request.dart'
    show PurchaseRequest;

/// A GRN Dashboard record IS a Purchase Request record — the
/// `grn_request.php` API returns exactly the same record shape as
/// `purchase_request.php` (see `PrApiMapper`), just scoped to the GRN
/// stage's own status/tabs/pipeline position. Rather than duplicate
/// [PurchaseRequest] field-for-field, the GRN feature works with the
/// same type directly under this name, so every existing GRN
/// controller/widget that already says `GrnRequest` keeps compiling
/// unchanged.
typedef GrnRequest = PurchaseRequest;
