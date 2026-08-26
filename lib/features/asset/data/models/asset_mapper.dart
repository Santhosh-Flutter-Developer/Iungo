import 'package:iungo/features/asset/domain/entities/asset.dart';

/// Maps one raw asset record from [AssetRemoteDataSource.fetchAssetById]
/// (the confirmed `modules/asset/view/allassets` endpoint) into an
/// [Asset].
///
/// Field names below are read directly off a live captured response,
/// not guessed:
///   id, name, description, qrVal, tagNumber, siteId,
///   category: {id}, buildingSpace: {id}
/// The asset record itself only carries *ids* for category/building/
/// site — their human-readable names live in the response's separate
/// `meta.supplements.asset.<field>.<id>` block, passed in here as
/// [supplements].
Asset mapAssetDetail(
  Map<String, dynamic> json, {
  required Map<String, dynamic> supplements,
}) {
  final id = _asInt(json['id']) ?? 0;

  final name = _nonEmpty(json['name']) ?? '--';

  // The entity's `assetCode` field is documented as "e.g.
  // facilio_112229" — that's exactly this record's `qrVal`, and it's
  // also literally what the QR scanner reads, confirmed by a live scan
  // ("scanned facilio_140091" <-> this record's qrVal: "facilio_140091").
  final assetCode = _nonEmpty(json['qrVal']) ?? '--';

  final description = _nonEmpty(json['description']) ?? '--';

  final category = _supplementName(supplements, 'category', json['category']) ??
      '--';

  final buildingName =
      _supplementName(supplements, 'buildingSpace', json['buildingSpace']);
  final location = buildingName == null ? '--' : '$buildingName-';

  final siteId = _asInt(json['siteId']) ?? 0;
  final siteName =
      _supplementNameById(supplements, 'siteId', siteId) ?? '--';

  return Asset(
    id: id,
    name: name,
    assetCode: assetCode,
    description: description,
    category: category,
    location: location,
    // Not present anywhere in this endpoint's response — the reference
    // Asset Detail screenshot may have sourced these from a different,
    // not-yet-identified API (e.g. a PPM/work-order count endpoint).
    // Defaulting to 0 rather than guessing a shape for them.
    openPpmCount: 0,
    closedPpmCount: 0,
    siteId: siteId,
    siteName: siteName,
  );
}

/// [reference] is the nested `{"id": <n>}` object a raw asset record
/// carries for a related field (category, buildingSpace, ...) — this
/// pulls that id out and resolves it against `supplements[field][id]`.
String? _supplementName(
  Map<String, dynamic> supplements,
  String field,
  dynamic reference,
) {
  if (reference is! Map<String, dynamic>) return null;
  final id = _asInt(reference['id']);
  if (id == null) return null;
  return _supplementNameById(supplements, field, id);
}

String? _supplementNameById(
  Map<String, dynamic> supplements,
  String field,
  int id,
) {
  final byId = supplements[field];
  if (byId is! Map<String, dynamic>) return null;
  final record = byId[id.toString()];
  if (record is! Map<String, dynamic>) return null;
  return _nonEmpty(record['name']) ?? _nonEmpty(record['displayName']);
}

String? _nonEmpty(dynamic value) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  return null;
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}