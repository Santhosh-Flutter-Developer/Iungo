import 'package:iungo/features/asset/data/datasources/asset_remote_data_source.dart';
import 'package:iungo/features/asset/data/models/asset_mapper.dart';
import 'package:iungo/features/asset/domain/entities/asset.dart';
import 'package:iungo/features/service_request/data/datasources/service_request_picklist_remote_data_source.dart';

/// Single entry point the Scan QR flow talks to for asset lookups.
///
/// Reuses the already-registered [ServiceRequestPickListRemoteDataSource]
/// to resolve a site *name* from the asset's `siteId` — the same trick
/// [ServiceRequestRepository.fetchServiceRequestDetail] already relies
/// on for the same reason (the detail response only carries an id).
class AssetRepository {
  AssetRepository(this._remoteDataSource, this._pickListDataSource);

  final AssetRemoteDataSource _remoteDataSource;
  final ServiceRequestPickListRemoteDataSource _pickListDataSource;

  List<PickListOptionLite>? _cachedSiteOptions;

  /// Resolves whatever the QR code scanned to into a full [Asset]
  /// record. [identifier] is a plain numeric asset id when the QR
  /// reduced to one, otherwise the raw scanned value is sent as a code
  /// search.
  Future<Asset> fetchAssetByIdentifier(String identifier) async {
    final asId = int.tryParse(identifier);

    final raw = asId != null
        ? await _remoteDataSource.fetchAssetDetail(id: asId)
        : await _remoteDataSource.fetchAssetDetail(code: identifier);

    Map<int, String> siteNameById = const {};
    try {
      _cachedSiteOptions ??= (await _pickListDataSource.fetchSiteOptions())
          .map((o) => PickListOptionLite(value: o.value, label: o.label))
          .toList();
      siteNameById = {
        for (final option in _cachedSiteOptions!) option.value: option.label,
      };
    } catch (_) {
      // Best-effort — the asset itself already loaded fine, so don't
      // fail the whole screen just because the site name couldn't be
      // resolved; it falls back to "--" instead.
    }

    return mapAssetDetail(raw, siteNameById: siteNameById);
  }
}

/// Trimmed-down copy of [PickListOption]'s two fields — avoids pulling
/// the whole service_request pick-list entity into the asset feature's
/// public surface for what is otherwise just an id/label pair.
class PickListOptionLite {
  const PickListOptionLite({required this.value, required this.label});

  final int value;
  final String label;
}