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
/// Two lookup strategies, tried in order:
///  1. By `id` — when the scanned value is (or reduces to, from
///     Facilio's own "facilio_<id>" code shape) a plain numeric asset
///     id, query the record directly. This is the reliable path: `id`
///     hits the exact record regardless of site.
///  2. By `search` — free-text match against the display label, same
///     as the live "Select Asset" dropdown. Used when the scanned value
///     isn't an id/code (e.g. it's the asset's name/label instead), and
///     as a fallback if an `id` lookup comes up empty.
///
/// Both are tried unscoped first, then once per known site — the
/// dropdown's only confirmed usage always scopes with `siteId`, so it's
/// untested whether the endpoint returns anything without one.
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

    final extractedId = _extractAssetId(trimmed);

    var matches = <Map<String, dynamic>>[];

    if (extractedId != null) {
      matches = await _lookup(id: extractedId);
    }
    if (matches.isEmpty) {
      matches = await _lookup(search: trimmed);
    }

    if (matches.isEmpty) {
      final sites = await _loadSiteOptions();
      for (final site in sites) {
        matches = extractedId != null
            ? await _lookup(id: extractedId, siteId: site.value)
            : await _lookup(search: trimmed, siteId: site.value);
        if (matches.isNotEmpty) break;
      }
    }

    if (matches.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[Asset Detail] no match anywhere for "$trimmed" '
          '(extracted id: $extractedId) — the resource/asset pick-list '
          'genuinely has nothing for this code.',
        );
      }
      throw const AssetException('Asset not found for this QR code');
    }

    // The search endpoint does fuzzy matching (it's built for a live
    // dropdown), so prefer an item whose label/code exactly matches what
    // was scanned over just taking the first fuzzy hit.
    final match = matches.firstWhere(
      (item) => _isExactMatch(item, trimmed, extractedId),
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

  /// Facilio's own asset code is "facilio_<id>" (confirmed from the
  /// Asset Detail screenshot: Asset Id 112229 <-> Asset Code
  /// facilio_112229). A bare numeric string is treated as an id too.
  int? _extractAssetId(String identifier) {
    final facilioMatch =
        RegExp(r'^facilio_(\d+)$', caseSensitive: false).firstMatch(identifier);
    if (facilioMatch != null) return int.tryParse(facilioMatch.group(1)!);
    if (RegExp(r'^\d+$').hasMatch(identifier)) return int.tryParse(identifier);
    return null;
  }

  Future<List<Map<String, dynamic>>> _lookup({
    int? id,
    String? search,
    int? siteId,
  }) async {
    try {
      final results = await _pickListDataSource.searchAssetsRaw(
        id: id,
        search: search,
        siteId: siteId,
      );
      if (kDebugMode) {
        final by = id != null ? 'id $id' : 'search "$search"';
        final scope = siteId != null ? '(site $siteId)' : '(unscoped)';
        debugPrint('[Asset Detail] lookup $by $scope -> ${results.length} match(es)');
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

  bool _isExactMatch(
    Map<String, dynamic> item,
    String identifier,
    int? extractedId,
  ) {
    if (extractedId != null) {
      final value = item['value'] ?? item['id'];
      if (value != null && value.toString() == extractedId.toString()) {
        return true;
      }
    }
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