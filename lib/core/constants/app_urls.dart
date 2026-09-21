class AppUrls {
  AppUrls._();

  /// Facilio/CITGroup portal host — attachment `previewUrl`/`downloadUrl`
  /// values come back host-relative (Portal API Guide §4.3) and must be
  /// resolved against this before use.
  static const String portalHost = 'https://citgroup.facilioclients.com';

  /// Iungo backend (PHP) used by the Create Purchase Request flow.
  static const String iungoApiBase = 'https://iungo.citgroupltd.com/api';

  /// Contract-code lookup (`fetch_contract_code`) and PR save
  /// (`save_purchase_request`) — both are actions on this one endpoint.
  static const String purchaseRequestApi = '$iungoApiBase/purchase_request.php';

  /// Multipart attachment upload used before saving a PR.
  static const String fileUploadApi = '$iungoApiBase/file_uploads.php';

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
