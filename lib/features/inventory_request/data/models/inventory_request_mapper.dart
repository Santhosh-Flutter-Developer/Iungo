import 'package:iungo/features/inventory_request/domain/entities/inventory_line_item.dart';
import 'package:iungo/features/inventory_request/domain/entities/inventory_request.dart';
import 'package:iungo/features/inventory_request/domain/entities/inventory_reservation_status.dart';

/// Parses one page of the "Awaiting Client Approval" list API
/// (GET .../v3/modules/inventoryrequest/view/awaitingclientapproval_1)
/// into [InventoryRequest] entities.
///
/// The API returns a lightweight list under `data.inventoryrequest`,
/// where related fields may either be inlined as
/// `{"id": ..., "primaryValue"/"name": ...}` objects, or referenced only
/// by id with the actual object living in a separate
/// `meta.supplements.inventoryrequest.<field>` lookup map keyed by id
/// (same convention as the Work Order/Service Request list APIs). Every
/// field is read defensively, trying several plausible key names/shapes,
/// since this module's exact response could not be captured against a
/// live authenticated session.
///
/// `status` is a special case: on this module the raw moduleState value
/// (e.g. `"awaitingclientapproval"`) is *not* accompanied by a
/// ready-made display label the way Work Order's is, so this mapper only
/// extracts the raw value here — `InventoryRequestRepository
/// .resolveStatusLabel` turns it into "Awaiting Client Approval" by
/// matching it against the live `pickList/forms/inventoryrequest/
/// moduleState` options once they're loaded.
class InventoryRequestListPageResult {
  const InventoryRequestListPageResult({
    required this.requests,
    required this.rawCount,
  });

  final List<InventoryRequest> requests;

  /// Number of raw items returned by the server for this page — used by
  /// the caller to decide whether another page likely exists (a full
  /// page suggests more; a short page means the end was reached).
  final int rawCount;

  static const String moduleName = 'inventoryrequest';

  factory InventoryRequestListPageResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final rawList = (data is Map<String, dynamic>) ? data[moduleName] : null;
    final items = (rawList is List) ? rawList : const [];

    final supplementsMap = _supplementsOf(json);

    final requests = items
        .whereType<Map<String, dynamic>>()
        .map((item) => _mapInventoryRequest(item, supplementsMap))
        .toList();

    return InventoryRequestListPageResult(
      requests: requests,
      rawCount: items.length,
    );
  }

  /// Extracts `meta.supplements.inventoryrequest` from a full API
  /// response envelope (shared by the list and detail mappers).
  static Map<String, dynamic> _supplementsOf(Map<String, dynamic> json) {
    final meta = json['meta'];
    final supplementsRoot =
        (meta is Map<String, dynamic>) ? meta['supplements'] : null;
    final supplements = (supplementsRoot is Map<String, dynamic>)
        ? supplementsRoot[moduleName]
        : null;
    return (supplements is Map<String, dynamic>) ? supplements : const {};
  }

  /// Converts a `{"133176": {...}, "133196": {...}}` supplement block
  /// into a `Map<int, Map<String, dynamic>>` keyed by the numeric id.
  static Map<int, Map<String, dynamic>> _idMap(dynamic raw) {
    if (raw is! Map<String, dynamic>) return const {};
    final result = <int, Map<String, dynamic>>{};
    raw.forEach((key, value) {
      final id = int.tryParse(key);
      if (id != null && value is Map<String, dynamic>) {
        result[id] = value;
      }
    });
    return result;
  }

  static InventoryRequest _mapInventoryRequest(
    Map<String, dynamic> item,
    Map<String, dynamic> supplementsMap,
  ) {
    final workOrderLookup = _idMap(supplementsMap['workorder']);
    final requestedForLookup = _idMap(supplementsMap['requestedFor']);
    final requestedByLookup = _idMap(supplementsMap['requestedBy']);
    final createdByLookup = _idMap(
      supplementsMap['sysCreatedBy'] ??
          supplementsMap['createdBy'] ??
          supplementsMap['createdByUser'] ??
          supplementsMap['creator'],
    );
    final serviceLineLookup = _idMap(supplementsMap['serviceLine']);
    final clientApprovalAuthoritiesLookup = _idMap(
      supplementsMap['clientApprovalAuthorities'] ??
          supplementsMap['clientApprovalAuthority'] ??
          supplementsMap['approvalAuthorities'],
    );

    final id = _asInt(item['id']) ?? 0;

    final name = (item['name'] as String?)?.trim() ??
        (item['subject'] as String?)?.trim() ??
        '';
    final description = (item['description'] as String?)?.trim() ?? '';

    final createdTime = _firstDate(item, const [
          'sysCreatedTime',
          'createdTime',
          'createdOn',
          'dateCreated',
          'created_time',
        ]) ??
        DateTime.now();
    final requestedTime = _firstDate(item, const ['requestedTime']) ?? createdTime;
    final requiredTime = _firstDate(item, const ['requiredTime']) ?? requestedTime;

    final status = _rawStatusValue(item['moduleState'] ?? item['status']);

    final reservationStatusRaw = _resolveRawIdOrLabel(
      item['reservationStatus'] ?? item['reservationState'],
      const {},
    );
    final reservationStatus =
        InventoryReservationStatusX.fromId(reservationStatusRaw) ??
            InventoryReservationStatus.pending;

    final workOrderTitle = _resolveLabel(
          item['workorder'] ?? item['workOrder'],
          workOrderLookup,
          labelKeys: const ['subject', 'name', 'primaryValue'],
        ) ??
        '';

    final requestedFor = _resolveLabel(
          item['requestedFor'],
          requestedForLookup,
          labelKeys: const ['name', 'primaryValue'],
        ) ??
        '';
    final requestedBy = _resolveLabel(
          item['requestedBy'],
          requestedByLookup,
          labelKeys: const ['name', 'primaryValue'],
        ) ??
        '';
    final createdBy = _resolveLabel(
          item['sysCreatedBy'] ??
              item['createdBy'] ??
              item['createdByUser'] ??
              item['creator'],
          createdByLookup,
          labelKeys: const ['name', 'primaryValue'],
        ) ??
        '';
    final serviceLine = _resolveLabel(
          item['serviceLine'],
          serviceLineLookup,
          labelKeys: const ['name', 'primaryValue', 'displayName'],
        ) ??
        '';

    final isSparePartRequest = _asBool(
      item['isSparePartRequest'] ??
          item['sparePartRequest'] ??
          item['isSpareRequest'],
    );

    final clientApprovalAuthorities = _resolveNameList(
      item['clientApprovalAuthorities'] ??
          item['clientApprovalAuthority'] ??
          item['approvalAuthorities'] ??
          item['approvers'],
      clientApprovalAuthoritiesLookup,
    );

    return InventoryRequest(
      id: id,
      name: name,
      description: description,
      createdTime: createdTime,
      requestedTime: requestedTime,
      requiredTime: requiredTime,
      status: (status == null || status.isEmpty) ? null : status,
      reservationStatus: reservationStatus,
      workOrderTitle: workOrderTitle,
      requestedFor: requestedFor.isEmpty ? '--' : requestedFor,
      requestedBy: requestedBy.isEmpty ? '--' : requestedBy,
      isSparePartRequest: isSparePartRequest,
      createdBy: createdBy.isEmpty ? '--' : createdBy,
      clientApprovalAuthorities: clientApprovalAuthorities,
      serviceLine: serviceLine.isEmpty ? '--' : serviceLine,
      // The list view returns summary fields only — Line Items are only
      // available (and only needed) on the Detail View.
      lineItems: const [],
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == 'yes' || normalized == '1';
    }
    return false;
  }

  /// Tries an epoch-millisecond numeric value first (the convention
  /// every other timestamp field in this app uses), then falls back to
  /// parsing an ISO-8601 string, in case this particular field is
  /// returned in a different shape than `requestedTime`/`requiredTime`.
  static DateTime? _dateFrom(dynamic value) {
    final ms = _asInt(value);
    if (ms != null && ms > 0) return DateTime.fromMillisecondsSinceEpoch(ms);
    if (value is String && value.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(value.trim());
      if (parsed != null) return parsed;
    }
    return null;
  }

  /// Tries each of [keys] in order against [json] and returns the first
  /// one that parses to a valid date — used for fields (like
  /// `createdTime`) whose exact JSON key on this module is uncertain.
  static DateTime? _firstDate(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final parsed = _dateFrom(json[key]);
      if (parsed != null) return parsed;
    }
    return null;
  }

  /// Extracts a raw token identifying the moduleState/status value —
  /// preferring its **numeric id** (`{"id": 2355, ...}` or a bare
  /// number), since that's what the `pickList/forms/inventoryrequest/
  /// moduleState` API's own `value` field is keyed by, and is what
  /// `InventoryRequestRepository.resolveStatusLabel` matches against.
  /// Falls back to a raw string/slug (e.g. `"awaitingclientapproval"`)
  /// when no numeric id is present, which the repository still turns
  /// into a readable label via its own client-side formatter. Never
  /// attempts to prettify anything here — that's the repository's job,
  /// once the live pick-list is available to consult.
  static String? _rawStatusValue(dynamic value) {
    if (value == null) return null;

    if (value is num) return value.toInt().toString();

    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    if (value is Map<String, dynamic>) {
      final id = value['id'];
      if (id != null) {
        final idStr = _asInt(id)?.toString();
        if (idStr != null) return idStr;
      }
      for (final key in ['value', 'status', 'displayName', 'primaryValue', 'name']) {
        final v = value[key];
        if (v != null && v.toString().trim().isNotEmpty) {
          return v.toString().trim();
        }
      }
      return null;
    }

    return value.toString();
  }

  static List<String> _asStringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((e) {
          if (e is String) return e.trim();
          if (e is Map<String, dynamic>) {
            return ((e['name'] ?? e['primaryValue']) as String?)?.trim() ?? '';
          }
          return '';
        })
        .where((e) => e.isNotEmpty)
        .toList();
  }

  /// Resolves a list-of-people field (like Client Approval Authorities)
  /// that may come back as a plain list of names/objects (handled by
  /// [_asStringList]), or as a list of bare ids needing a
  /// supplement-lookup by id.
  static List<String> _resolveNameList(
    dynamic value,
    Map<int, Map<String, dynamic>> lookup,
  ) {
    final direct = _asStringList(value);
    if (direct.isNotEmpty) return direct;
    if (value is! List) return const [];

    return value
        .map((e) {
          final id = _asInt(_nestedId(e));
          if (id == null) return '';
          final info = lookup[id];
          if (info == null) return '';
          return ((info['name'] ?? info['primaryValue']) as String?)?.trim() ?? '';
        })
        .where((e) => e.isNotEmpty)
        .toList();
  }

  /// Extracts the numeric id of a nested relation field — either a plain
  /// id, or an object carrying one (`{"id": 2, ...}`).
  static dynamic _nestedId(dynamic value) {
    if (value is Map<String, dynamic>) return value['id'];
    return value;
  }

  /// Resolves a relation field to its display label, trying (in order):
  /// the field being an inline object already carrying [labelKeys], then
  /// a supplement-lookup by id, then giving up (null).
  static String? _resolveLabel(
    dynamic value,
    Map<int, Map<String, dynamic>> lookup, {
    required List<String> labelKeys,
  }) {
    if (value is Map<String, dynamic>) {
      for (final key in labelKeys) {
        final v = (value[key] as String?)?.trim();
        if (v != null && v.isNotEmpty) return v;
      }
    }
    final id = _asInt(_nestedId(value));
    if (id == null) return null;
    final info = lookup[id];
    if (info == null) return null;
    for (final key in labelKeys) {
      final v = (info[key] as String?)?.trim();
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  /// Resolves the Reservation Status field to the raw static id (`"1"`
  /// through `"5"`) the fixed [InventoryReservationStatus] enum expects
  /// — reading either a plain numeric value, an inline
  /// `{"id"/"value": ...}` object, or a supplement-lookup id.
  static String? _resolveRawIdOrLabel(
    dynamic value,
    Map<int, Map<String, dynamic>> lookup,
  ) {
    if (value == null) return null;
    if (value is num || value is String) {
      final id = _asInt(value);
      if (id != null) return id.toString();
    }
    final id = _asInt(_nestedId(value));
    return id?.toString();
  }
}

/// Parses the Detail View's Overview API response
/// (GET .../v3/modules/inventoryrequest/view/all?...&id=<id>) into a
/// single [InventoryRequest].
///
/// Takes the *full* response envelope (not just the record itself) so
/// `meta.supplements.inventoryrequest` is available for id-based
/// relation lookups — the same envelope shape the list mapper reads,
/// just narrowed to one record via `id=`.
InventoryRequest mapInventoryRequestDetail(Map<String, dynamic> envelope) {
  final data = envelope['data'];
  final raw = (data is Map<String, dynamic>)
      ? data[InventoryRequestListPageResult.moduleName]
      : null;

  final Map<String, dynamic> json;
  if (raw is Map<String, dynamic>) {
    json = raw;
  } else if (raw is List && raw.isNotEmpty && raw.first is Map<String, dynamic>) {
    json = raw.first as Map<String, dynamic>;
  } else {
    json = envelope;
  }

  final supplementsMap = InventoryRequestListPageResult._supplementsOf(envelope);
  final workOrderLookup =
      InventoryRequestListPageResult._idMap(supplementsMap['workorder']);
  final requestedForLookup =
      InventoryRequestListPageResult._idMap(supplementsMap['requestedFor']);
  final requestedByLookup =
      InventoryRequestListPageResult._idMap(supplementsMap['requestedBy']);
  final createdByLookup = InventoryRequestListPageResult._idMap(
    supplementsMap['sysCreatedBy'] ??
        supplementsMap['createdBy'] ??
        supplementsMap['createdByUser'] ??
        supplementsMap['creator'],
  );
  final serviceLineLookup =
      InventoryRequestListPageResult._idMap(supplementsMap['serviceLine']);
  final clientApprovalAuthoritiesLookup = InventoryRequestListPageResult._idMap(
    supplementsMap['clientApprovalAuthorities'] ??
        supplementsMap['clientApprovalAuthority'] ??
        supplementsMap['approvalAuthorities'],
  );

  final id = InventoryRequestListPageResult._asInt(json['id']) ?? 0;

  final name = (json['name'] as String?)?.trim() ??
      (json['subject'] as String?)?.trim() ??
      '';
  final description = (json['description'] as String?)?.trim() ?? '';

  final createdTime = InventoryRequestListPageResult._firstDate(json, const [
        'sysCreatedTime',
        'createdTime',
        'createdOn',
        'dateCreated',
        'created_time',
      ]) ??
      DateTime.now();
  final requestedTime =
      InventoryRequestListPageResult._firstDate(json, const ['requestedTime']) ??
          createdTime;
  final requiredTime =
      InventoryRequestListPageResult._firstDate(json, const ['requiredTime']) ??
          requestedTime;

  final status = InventoryRequestListPageResult._rawStatusValue(
    json['moduleState'] ?? json['status'],
  );

  final reservationStatusRaw = InventoryRequestListPageResult._resolveRawIdOrLabel(
    json['reservationStatus'] ?? json['reservationState'],
    const {},
  );
  final reservationStatus =
      InventoryReservationStatusX.fromId(reservationStatusRaw) ??
          InventoryReservationStatus.pending;

  final workOrderTitle = InventoryRequestListPageResult._resolveLabel(
        json['workorder'] ?? json['workOrder'],
        workOrderLookup,
        labelKeys: const ['subject', 'name', 'primaryValue'],
      ) ??
      '';

  final requestedFor = InventoryRequestListPageResult._resolveLabel(
        json['requestedFor'],
        requestedForLookup,
        labelKeys: const ['name', 'primaryValue'],
      ) ??
      '';
  final requestedBy = InventoryRequestListPageResult._resolveLabel(
        json['requestedBy'],
        requestedByLookup,
        labelKeys: const ['name', 'primaryValue'],
      ) ??
      '';
  final createdBy = InventoryRequestListPageResult._resolveLabel(
        json['sysCreatedBy'] ??
            json['createdBy'] ??
            json['createdByUser'] ??
            json['creator'],
        createdByLookup,
        labelKeys: const ['name', 'primaryValue'],
      ) ??
      '';
  final serviceLine = InventoryRequestListPageResult._resolveLabel(
        json['serviceLine'],
        serviceLineLookup,
        labelKeys: const ['name', 'primaryValue', 'displayName'],
      ) ??
      '';

  final isSparePartRequest = InventoryRequestListPageResult._asBool(
    json['isSparePartRequest'] ?? json['sparePartRequest'] ?? json['isSpareRequest'],
  );

  final clientApprovalAuthorities = InventoryRequestListPageResult._resolveNameList(
    json['clientApprovalAuthorities'] ??
        json['clientApprovalAuthority'] ??
        json['approvalAuthorities'] ??
        json['approvers'],
    clientApprovalAuthoritiesLookup,
  );

  final lineItems = _lineItemsFrom(json['lineItems'] ?? json['items']);

  return InventoryRequest(
    id: id,
    name: name,
    description: description,
    createdTime: createdTime,
    requestedTime: requestedTime,
    requiredTime: requiredTime,
    status: (status == null || status.isEmpty) ? null : status,
    reservationStatus: reservationStatus,
    workOrderTitle: workOrderTitle,
    requestedFor: requestedFor.isEmpty ? '--' : requestedFor,
    requestedBy: requestedBy.isEmpty ? '--' : requestedBy,
    isSparePartRequest: isSparePartRequest,
    createdBy: createdBy.isEmpty ? '--' : createdBy,
    clientApprovalAuthorities: clientApprovalAuthorities,
    serviceLine: serviceLine.isEmpty ? '--' : serviceLine,
    lineItems: lineItems,
  );
}

List<InventoryLineItem> _lineItemsFrom(dynamic raw) {
  if (raw is! List) return const [];
  return raw.whereType<Map<String, dynamic>>().map((item) {
    final itemInfo = item['item'];
    final itemCode = ((itemInfo is Map<String, dynamic>
                ? itemInfo['code'] ?? itemInfo['itemCode']
                : item['itemCode']) as String?)
            ?.trim() ??
        '';
    final itemName = ((itemInfo is Map<String, dynamic>
                ? itemInfo['name'] ?? itemInfo['itemName']
                : item['itemName']) as String?)
            ?.trim() ??
        '';
    final storeRoomInfo = item['storeRoom'] ?? item['store'];
    final storeRoom = ((storeRoomInfo is Map<String, dynamic>
                ? storeRoomInfo['name']
                : storeRoomInfo) as String?)
            ?.trim() ??
        '';

    return InventoryLineItem(
      itemCode: itemCode,
      itemName: itemName,
      storeRoom: storeRoom,
      requestedQty:
          InventoryRequestListPageResult._asInt(item['requestedQty']) ?? 0,
      availableQty:
          InventoryRequestListPageResult._asInt(item['availableQty']) ?? 0,
      issuedQty: InventoryRequestListPageResult._asInt(item['issuedQty']) ?? 0,
    );
  }).toList();
}