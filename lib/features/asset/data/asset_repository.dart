import 'package:flutter/foundation.dart';

import 'datasources/asset_exceptions.dart';
import 'datasources/asset_remote_data_source.dart';
import 'models/asset_mapper.dart';
import 'package:iungo/features/asset/domain/entities/asset.dart';

/// Resolves whatever a scanned asset QR code decoded to into a full
/// [Asset] record, via the confirmed `modules/asset/view/allassets`
/// endpoint (see [AssetRemoteDataSource]).
///
/// Every asset QR code sampled so far decodes to literally
/// `facilio_<id>` (confirmed by a live scan's debug log matching a live
/// captured API response's own `qrVal` field character-for-character),
/// so resolving one is: pull `<id>` out, ask the server for exactly
/// that id via `quickFilter`, and — because a filter silently being
/// ignored server-side has already bitten this feature once before
/// (the service-request form's asset picklist did exactly that for a
/// bare `id=` param) — double-check the response actually is that
/// asset rather than trusting a non-empty result on its own.
class AssetRepository {
  AssetRepository(this._dataSource);

  final AssetRemoteDataSource _dataSource;

  Future<Asset> fetchAssetByIdentifier(String identifier) async {
    final trimmed = identifier.trim();
    if (trimmed.isEmpty) {
      throw const AssetException('Asset not found for this QR code');
    }

    final extractedId = _extractAssetId(trimmed);

    if (kDebugMode) {
      debugPrint(
        '[Asset Detail] scanned "$trimmed" (extracted id: $extractedId)',
      );
    }

    if (extractedId == null) {
      if (kDebugMode) {
        debugPrint(
          '[Asset Detail] "$trimmed" doesn\'t match any known asset QR '
          'shape (facilio_<id>, a bare id, or a .../asset/<id> URL) — '
          'reporting not found.',
        );
      }
      throw const AssetException('Asset not found for this QR code');
    }

    final result = await _dataSource.fetchAssetById(extractedId);

    Map<String, dynamic>? match;
    for (final item in result.items) {
      final itemId = item['id'];
      final itemQrVal = item['qrVal'];
      final idMatches = itemId is int
          ? itemId == extractedId
          : itemId?.toString() == extractedId.toString();
      final qrValMatches = itemQrVal is String && itemQrVal.trim() == trimmed;
      if (idMatches || qrValMatches) {
        match = item;
        break;
      }
    }

    if (match == null) {
      if (kDebugMode) {
        debugPrint(
          '[Asset Detail] server returned ${result.items.length} item(s) '
          'for id=$extractedId but none actually match "$trimmed" — '
          'reporting not found rather than guessing.',
        );
      }
      throw const AssetException('Asset not found for this QR code');
    }

    return mapAssetDetail(match, supplements: result.supplements);
  }

  /// Facilio's own asset QR value is "facilio_<id>" (confirmed live: a
  /// scanned "facilio_140091" resolved to the asset whose own `qrVal`
  /// field is exactly "facilio_140091"). A bare numeric string, or a
  /// URL/path ending in "/asset/<digits>" (seen on the printable QR
  /// label page), are also accepted as plain ids.
  int? _extractAssetId(String identifier) {
    if (RegExp(r'^\d+$').hasMatch(identifier)) return int.tryParse(identifier);

    final facilioMatch =
        RegExp(r'^facilio_(\d+)$', caseSensitive: false).firstMatch(identifier);
    if (facilioMatch != null) return int.tryParse(facilioMatch.group(1)!);

    final urlMatch =
        RegExp(r'/asset/(\d+)(?:[/?#].*)?$', caseSensitive: false)
            .firstMatch(identifier);
    if (urlMatch != null) return int.tryParse(urlMatch.group(1)!);

    return null;
  }
}