/// Thrown by the asset data layer on a failed lookup (network error,
/// non-zero API response code, or "no asset found for this QR code") —
/// mirrors [ServiceRequestException]'s role in the service_request
/// feature so [AssetDetailController] can show the server's own message
/// when it has one, and a generic fallback otherwise.
class AssetException implements Exception {
  const AssetException(this.message);

  final String message;

  @override
  String toString() => message;
}