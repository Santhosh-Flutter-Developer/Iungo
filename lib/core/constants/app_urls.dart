class AppUrls {
  AppUrls._();

  /// Facilio/CITGroup portal host — attachment `previewUrl`/`downloadUrl`
  /// values come back host-relative (Portal API Guide §4.3) and must be
  /// resolved against this before use.
  static const String portalHost = 'https://citgroup.facilioclients.com';

  /// Iungo backend (PHP) used by the Purchase Request flows.
  static const String iungoHost = 'https://iungo.citgroupltd.com';
  static const String iungoApiBase = '$iungoHost/api';

  /// Folder the Purchase Request attachments (quotations, delivery
  /// notes, invoices) are served from — every attachment URL in the
  /// API guide lives here.
  static const String iungoUploadBase = '$iungoHost/include/images/upload';

  /// Purchase Request list, approve/reject, contract-code lookup
  /// (`fetch_contract_code`) and PR save (`save_purchase_request`) — all
  /// on this one endpoint.
  static const String purchaseRequestApi = '$iungoApiBase/purchase_request.php';

  /// Multipart attachment upload used before saving a PR (and, with a
  /// different `field`, before approving a GRN's delivery note).
  static const String fileUploadApi = '$iungoApiBase/file_uploads.php';

  /// GRN list and approve/reject.
  static const String grnRequestApi = '$iungoApiBase/grn_request.php';

  /// Invoice list and approve/reject.
  static const String invoiceRequestApi = '$iungoApiBase/invoice_request.php';

  /// Facilio inventory list — source of the Inventory "Material Code"
  /// dropdown on the Create PR form (Bearer-authenticated).
  static const String inventoryMaterialsApi =
      '$portalHost/client/api/v3/modules/inventoryrequest/view/allinventoryrequests';

  /// Resolves a possibly host-relative URL against [portalHost]. A URL
  /// that's already absolute is returned unchanged.
  static String resolve(String hostRelativeOrAbsoluteUrl) {
    if (hostRelativeOrAbsoluteUrl.startsWith('http://') ||
        hostRelativeOrAbsoluteUrl.startsWith('https://')) {
      return hostRelativeOrAbsoluteUrl;
    }
    return '$portalHost$hostRelativeOrAbsoluteUrl';
  }
}
