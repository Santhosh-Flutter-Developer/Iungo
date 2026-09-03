class AppUrls {
  AppUrls._();

  /// Facilio/CITGroup portal host — attachment `previewUrl`/`downloadUrl`
  /// values come back host-relative (Portal API Guide §4.3) and must be
  /// resolved against this before use.
  static const String portalHost = 'https://citgroup.facilioclients.com';

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
