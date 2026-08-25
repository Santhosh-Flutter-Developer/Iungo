/// One asset record as shown on the "Asset Detail" screen — reached by
/// scanning an asset's QR code from the Dashboard. Mirrors the fields
/// the Facilio Asset module surfaces for a single asset (matching the
/// reference "Asset Detail" screenshots: Name, Asset Id, Asset Code,
/// Description, Category, Location, Open/Closed PPM Count).
class Asset {
  const Asset({
    required this.id,
    required this.name,
    required this.assetCode,
    required this.description,
    required this.category,
    required this.location,
    required this.openPpmCount,
    required this.closedPpmCount,
    required this.siteId,
    required this.siteName,
  });

  /// Facilio's numeric asset id (shown as "Asset Id" on screen, and sent
  /// as the "New Service Request" form's `resource.id` when raising a
  /// request straight from this asset).
  final int id;

  /// Asset name, e.g. "6DC/GF/ELEC/MV/1".
  final String name;

  /// Asset code, e.g. "facilio_112229".
  final String assetCode;

  final String description;
  final String category;
  final String location;
  final int openPpmCount;
  final int closedPpmCount;

  /// Needed to prefill the "New Service Request" form's Site field when
  /// raising a request straight from this asset — the Asset Detail API
  /// only carries a `siteId`, so [siteName] is resolved separately
  /// against the Site pick-list (same pattern used for Service Request
  /// Detail's site name).
  final int siteId;
  final String siteName;
}