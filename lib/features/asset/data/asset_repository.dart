import 'package:flutter/foundation.dart';
import 'package:iungo/features/asset/data/datasources/asset_exceptions.dart';
import 'package:iungo/features/asset/data/models/asset_mapper.dart';
import 'package:iungo/features/asset/domain/entities/asset.dart';
import 'package:iungo/features/service_request/data/datasources/service_request_exceptions.dart';
import 'package:iungo/features/service_request/data/datasources/service_request_picklist_remote_data_source.dart';

/// Single entry point the Scan QR flow talks to for asset lookups.
///
/// Resolves a scanned QR value via [ServiceRequestPickListRemoteDataSource
/// .searchAssetsRaw] — the *same, already-confirmed* endpoint that backs
/// the "New Service Request" form's Asset dropdown — rather than a
/// separate, unconfirmed "asset detail" endpoint.
///
/// That dropdown always scopes the call with a `siteId` (Site is picked
/// before Asset on the form), so it's untested whether the endpoint
/// returns anything for an *unscoped* search. To be safe, this tries an
/// unscoped search first and, if that comes back empty, retries once per
/// known site.
class AssetRepository {
  AssetRepository(this._pickListDataSource);

  final ServiceRequestPickListRemoteDataSource _pickListDataSource;

  List<PickListOptionLite>? _cachedSiteOptions;

  /// Resolves whatever the QR code scanned to into a full [Asset]
  /// record.
  Future<Asset> fetchAssetByIdentifier(String identifier) async {
    final trimmed = identifier.trim();
    if (trimmed.isEmpty) {
      throw const AssetException('Asset not found for this QR code');
    }

    var matches = await _searchAssets(trimmed);

    if (matches.isEmpty) {
      final sites = await _loadSiteOptions();
      for (final site in sites) {
        matches = await _searchAssets(trimmed, siteId: site.value);
        if (matches.isNotEmpty) break;
      }
    }

    if (matches.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[Asset Detail] no match anywhere for "$trimmed" — the '
          'resource/asset pick-list genuinely has nothing for this code.',
        );
      }
      throw const AssetException('Asset not found for this QR code');
    }

    // The search endpoint does fuzzy matching (it's built for a live
    // dropdown), so prefer an item whose label/code exactly matches what
    // was scanned over just taking the first fuzzy hit.
    final match = matches.firstWhere(
      (item) => _isExactMatch(item, trimmed),
      orElse: () => matches.first,
    );

    Map<int, String> siteNameById = const {};
    try {
      final sites = await _loadSiteOptions();
      siteNameById = {for (final option in sites) option.value: option.label};
    } catch (_) {
      // Best-effort — the asset itself already loaded fine, so don't
      // fail the whole screen just because the site name couldn't be
      // resolved; it falls back to "--" instead.
    }

    return mapAssetDetail(match, siteNameById: siteNameById);
  }

  Future<List<Map<String, dynamic>>> _searchAssets(
    String search, {
    int? siteId,
  }) async {
    try {
      final results = await _pickListDataSource.searchAssetsRaw(
        search: search,
        siteId: siteId,
      );
      if (kDebugMode) {
        debugPrint(
          '[Asset Detail] search "$search" '
          '${siteId != null ? '(site $siteId)' : '(unscoped)'} '
          '-> ${results.length} match(es)',
        );
      }
      return results;
    } on ServiceRequestException catch (e) {
      throw AssetException(e.message);
    }
  }

  Future<List<PickListOptionLite>> _loadSiteOptions() async {
    return _cachedSiteOptions ??=
        (await _pickListDataSource.fetchSiteOptions())
            .map((o) => PickListOptionLite(value: o.value, label: o.label))
            .toList();
  }

  bool _isExactMatch(Map<String, dynamic> item, String identifier) {
    final target = identifier.toLowerCase();
    for (final key in ['label', 'name', 'code', 'assetCode', 'value']) {
      final value = item[key];
      if (value != null && value.toString().trim().toLowerCase() == target) {
        return true;
      }
    }
    return false;
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