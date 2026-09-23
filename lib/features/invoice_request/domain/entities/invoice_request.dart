import 'package:iungo/features/purchase_request/domain/entities/purchase_request.dart';

export 'package:iungo/features/purchase_request/domain/entities/purchase_request.dart'
    show PurchaseRequest;

/// An Invoice Dashboard record IS a Purchase Request record — the
/// `invoice_request.php` API returns exactly the same record shape as
/// `purchase_request.php`/`grn_request.php` (see `PrApiMapper`), just
/// scoped to the Invoice stage's own status/tabs/pipeline position.
/// Rather than duplicate [PurchaseRequest] field-for-field, the Invoice
/// feature works with the same type directly under this name, so every
/// existing Invoice controller/widget that already says `InvoiceRequest`
/// keeps compiling unchanged. Mirrors `GrnRequest`.
typedef InvoiceRequest = PurchaseRequest;
