import 'package:iungo/features/asset/domain/entities/asset.dart';

/// Maps the raw asset object returned by [AssetRemoteDataSource] into an
/// [Asset]. Field names are read defensively (several plausible keys
/// tried in order) the same way `service_request_mapper.dart` reads an
/// unconfirmed "assigned technician" shape — this whole response shape
/// is a best-effort placeholder pending a confirmed Postman capture for
/// the Asset module, so adjust the key names below once you have one.
Asset mapAssetDetail(
  Map<String, dynamic> json, {
  required Map<int, String> siteNameById,
}) {
  final id = _asInt(json['id']) ?? 0;

  final name = _firstNonEmptyString([
    json['name'],
    json['primaryValue'],
  ]) ?? '--';

  final assetCode = _firstNonEmptyString([
    json['assetCode'],
    json['code'],
    json['uniqueCode'],
  ]) ?? '--';

  final description = _firstNonEmptyString([json['description']]) ?? '--';

  final category = _firstNonEmptyString([
    _nestedName(json['category']),
    _nestedName(json['assetCategory']),
    json['category'] is String ? json['category'] as String : null,
  ]) ?? '--';

  final location = _composeLocation(json);

  final openPpmCount = _asInt(_firstNonNull([
        json['openPpmCount'],
        json['openPPMCount'],
        _nestedValue(json['ppm'], 'open'),
      ])) ??
      0;

  final closedPpmCount = _asInt(_firstNonNull([
        json['closedPpmCount'],
        json['closedPPMCount'],
        _nestedValue(json['ppm'], 'closed'),
      ])) ??
      0;

  final siteId = _asInt(json['siteId']) ?? 0;
  final siteName = _firstNonEmptyString([
        _nestedName(json['site']),
        siteNameById[siteId],
      ]) ??
      '--';

  return Asset(
    id: id,
    name: name,
    assetCode: assetCode,
    description: description,
    category: category,
    location: location,
    openPpmCount: openPpmCount,
    closedPpmCount: closedPpmCount,
    siteId: siteId,
    siteName: siteName,
  );
}

/// Tries a precomposed location string first (however the API happens
/// to name it), then falls back to joining Site/Building/Floor names
/// with "-", matching the reference screenshot's
/// "6-DC-Data Center-Ground Floor-" style.
String _composeLocation(Map<String, dynamic> json) {
  final precomposed = _firstNonEmptyString([
    json['location'],
    json['locationPath'],
    json['spacePath'],
  ]);
  if (precomposed != null) return precomposed;

  final parts = [
    _nestedName(json['site']),
    _nestedName(json['building']),
    _nestedName(json['floor']),
  ].whereType<String>().where((p) => p.trim().isNotEmpty).toList();

  return parts.isEmpty ? '--' : '${parts.join('-')}-';
}

String? _nestedName(dynamic value) {
  if (value is Map<String, dynamic>) {
    final name = (value['name'] ?? value['primaryValue']) as String?;
    return (name != null && name.trim().isNotEmpty) ? name.trim() : null;
  }
  return null;
}

dynamic _nestedValue(dynamic value, String key) {
  if (value is Map<String, dynamic>) return value[key];
  return null;
}

dynamic _firstNonNull(List<dynamic> candidates) {
  for (final candidate in candidates) {
    if (candidate != null) return candidate;
  }
  return null;
}

String? _firstNonEmptyString(List<dynamic> candidates) {
  for (final candidate in candidates) {
    if (candidate is String && candidate.trim().isNotEmpty) {
      return candidate.trim();
    }
  }
  return null;
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}