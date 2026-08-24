import 'package:iungo/features/service_request/domain/entities/request_classification.dart';
import 'package:iungo/features/service_request/domain/entities/service_request.dart';
import 'package:iungo/features/service_request/domain/entities/service_request_attachment.dart';
import 'package:iungo/features/service_request/domain/entities/service_request_option.dart';
import 'package:iungo/features/service_request/domain/entities/service_request_priority.dart';
import 'package:iungo/features/service_request/domain/entities/service_request_status.dart';

/// Parses one page of the "My Service Requests" list API into
/// [ServiceRequest] entities.
///
/// The API (Facilio) returns a lightweight list under
/// `data.serviceRequest`, where related fields (requester, site,
/// priority, status, resource/building) are only referenced by id.
/// The actual objects for those ids live in a separate
/// `meta.supplements.serviceRequest.<field>` lookup map, keyed by id as
/// a string — this class resolves both sides into flat, display-ready
/// [ServiceRequest] values.
class ServiceRequestListPageResult {
  const ServiceRequestListPageResult({
    required this.tickets,
    required this.rawCount,
  });

  final List<ServiceRequest> tickets;

  /// Number of raw items returned by the server for this page — used by
  /// the caller to decide whether another page likely exists (a full
  /// page suggests more; a short page means the end was reached).
  final int rawCount;

  factory ServiceRequestListPageResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final rawList = (data is Map<String, dynamic>)
        ? data['serviceRequest']
        : null;
    final items = (rawList is List) ? rawList : const [];

    final meta = json['meta'];
    final supplementsRoot = (meta is Map<String, dynamic>)
        ? meta['supplements']
        : null;
    final supplements = (supplementsRoot is Map<String, dynamic>)
        ? supplementsRoot['serviceRequest']
        : null;
    final supplementsMap = (supplements is Map<String, dynamic>)
        ? supplements
        : const <String, dynamic>{};

    final sysCreatedByLookup = _idMap(supplementsMap['sysCreatedBy']);
    final resourceLookup = _idMap(supplementsMap['resource']);
    final priorityLookup = _idMap(supplementsMap['priority_serviceRequest']);
    final siteLookup = _idMap(supplementsMap['siteId']);
    final moduleStateLookup = _idMap(supplementsMap['moduleState']);

    final tickets = items
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => _mapTicket(
            item,
            sysCreatedByLookup: sysCreatedByLookup,
            resourceLookup: resourceLookup,
            priorityLookup: priorityLookup,
            siteLookup: siteLookup,
            moduleStateLookup: moduleStateLookup,
          ),
        )
        .toList();

    return ServiceRequestListPageResult(
      tickets: tickets,
      rawCount: items.length,
    );
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

  static ServiceRequest _mapTicket(
    Map<String, dynamic> item, {
    required Map<int, Map<String, dynamic>> sysCreatedByLookup,
    required Map<int, Map<String, dynamic>> resourceLookup,
    required Map<int, Map<String, dynamic>> priorityLookup,
    required Map<int, Map<String, dynamic>> siteLookup,
    required Map<int, Map<String, dynamic>> moduleStateLookup,
  }) {
    final id = _asInt(item['id']) ?? 0;
    final subject = (item['subject'] as String?)?.trim() ?? '';
    // Not present on the seeded/test data this API currently returns,
    // but read defensively in case a given ticket does carry one.
    final description = (item['description'] as String?)?.trim() ?? '';

    final sysCreatedTimeMs = _asInt(item['sysCreatedTime']);
    final raisedAt = sysCreatedTimeMs != null && sysCreatedTimeMs > 0
        ? DateTime.fromMillisecondsSinceEpoch(sysCreatedTimeMs)
        : DateTime.now();

    final dueDateMs = _asInt(item['dueDate']);
    final dueDate = dueDateMs != null && dueDateMs > 0
        ? DateTime.fromMillisecondsSinceEpoch(dueDateMs)
        : raisedAt;

    final requesterId = _asInt(_nestedId(item['sysCreatedBy']));
    final requesterInfo =
        requesterId != null ? sysCreatedByLookup[requesterId] : null;
    final requester = (requesterInfo?['name'] as String?)?.trim();

    final siteId = _asInt(item['siteId']);
    final siteInfo = siteId != null ? siteLookup[siteId] : null;
    final site = (siteInfo?['name'] as String?)?.trim();

    final resourceId = _asInt(_nestedId(item['resource']));
    final resourceInfo = resourceId != null ? resourceLookup[resourceId] : null;
    final building = _buildingName(resourceInfo);

    final priorityId = _asInt(_nestedId(item['priority_serviceRequest']));
    final priorityInfo = priorityId != null ? priorityLookup[priorityId] : null;
    final priority = _mapPriority(priorityInfo);

    final moduleStateId = _asInt(_nestedId(item['moduleState']));
    final moduleStateInfo =
        moduleStateId != null ? moduleStateLookup[moduleStateId] : null;
    final status = _mapStatus(moduleStateInfo);

    return ServiceRequest(
      id: id,
      title: subject,
      description: description,
      requester: (requester == null || requester.isEmpty) ? '--' : requester,
      site: (site == null || site.isEmpty) ? '--' : site,
      priority: priority,
      status: status,
      type: ServiceRequestOption.serviceRequest,
      dueDate: dueDate,
      raisedAt: raisedAt,
      building: building,
    );
  }

  static dynamic _nestedId(dynamic value) {
    if (value is Map<String, dynamic>) return value['id'];
    return value;
  }

  static String? _buildingName(Map<String, dynamic>? resourceInfo) {
    if (resourceInfo == null) return null;
    final buildingBlock = resourceInfo['building'];
    if (buildingBlock is Map<String, dynamic>) {
      final name = buildingBlock['name'] as String?;
      if (name != null && name.trim().isNotEmpty) return name.trim();
    }
    // Some `resource` entries *are* the building itself (asset id points
    // straight at a Building-type resource) rather than pointing at one.
    final selfName = resourceInfo['name'] as String?;
    return (selfName != null && selfName.trim().isNotEmpty)
        ? selfName.trim()
        : null;
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static ServiceRequestPriority _mapPriority(
    Map<String, dynamic>? priorityInfo,
  ) {
    if (priorityInfo == null) return ServiceRequestPriority.noPriority;
    return ServiceRequestPriorityX.fromApiLabel(
      (priorityInfo['displayName'] ?? priorityInfo['primaryValue']) as String?,
    );
  }

  static ServiceRequestStatus _mapStatus(
    Map<String, dynamic>? moduleStateInfo,
  ) {
    if (moduleStateInfo == null) return ServiceRequestStatus.open;
    return ServiceRequestStatusX.fromApiLabel(
      (moduleStateInfo['status'] ?? moduleStateInfo['displayName']) as String?,
    );
  }
}

/// Maps the raw `data.serviceRequest` object returned by the Detail
/// View API (GET .../allservicerequests?...&id=<id>) into a
/// [ServiceRequest]. Unlike the list API, `moduleState` and `requester`
/// arrive inline here (not as an id + supplement lookup) and the
/// response also carries `description`/`classificationType`/`resource`/
/// `buildingSpace`, none of which the summary list response includes.
///
/// The site's *name* isn't in this response (only `siteId`) — pass
/// [siteNameById], a lookup built from the Site pick-list, to resolve
/// it; without one the site shows as "--".
ServiceRequest mapServiceRequestDetail(
  Map<String, dynamic> json, {
  Map<int, String> siteNameById = const {},
}) {
  final id = ServiceRequestListPageResult._asInt(json['id']) ?? 0;
  final subject = (json['subject'] as String?)?.trim() ?? '';
  final description = (json['description'] as String?)?.trim() ?? '';

  final sysCreatedTimeMs =
      ServiceRequestListPageResult._asInt(json['sysCreatedTime']);
  final raisedAt = sysCreatedTimeMs != null && sysCreatedTimeMs > 0
      ? DateTime.fromMillisecondsSinceEpoch(sysCreatedTimeMs)
      : DateTime.now();

  final dueDateMs = ServiceRequestListPageResult._asInt(json['dueDate']);
  final dueDate = dueDateMs != null && dueDateMs > 0
      ? DateTime.fromMillisecondsSinceEpoch(dueDateMs)
      : raisedAt;

  final moduleState = json['moduleState'];
  final status = ServiceRequestListPageResult._mapStatus(
    moduleState is Map<String, dynamic> ? moduleState : null,
  );

  final priorityInfo = json['priority_serviceRequest'];
  final priority = ServiceRequestListPageResult._mapPriority(
    priorityInfo is Map<String, dynamic> ? priorityInfo : null,
  );

  final requesterInfo = json['requester'];
  final requesterName = (requesterInfo is Map<String, dynamic>)
      ? (requesterInfo['name'] as String?)?.trim()
      : null;
  final requesterPhone = (requesterInfo is Map<String, dynamic>)
      ? (requesterInfo['phone'] as String?)?.trim()
      : null;

  final siteId = ServiceRequestListPageResult._asInt(json['siteId']);
  final siteName = siteId != null ? siteNameById[siteId] : null;

  final buildingSpace = json['buildingSpace'];
  final buildingName = (buildingSpace is Map<String, dynamic>)
      ? (buildingSpace['primaryValue'] as String?)?.trim()
      : null;

  // The `resource` block represents whichever Space/Asset chooser
  // selection was made on the form — only surface it under "Space/Asset"
  // when it's actually an asset (a building-type resource is already
  // shown via `buildingSpace` above).
  final resource = json['resource'];
  String? assetName;
  if (resource is Map<String, dynamic> &&
      resource['resourceTypeEnum'] == 'ASSET') {
    final name = (resource['name'] ?? resource['primaryValue']) as String?;
    assetName = name?.trim();
  }

  final classification = RequestClassificationX.fromApiValue(
    ServiceRequestListPageResult._asInt(json['classificationType']),
  );

  // No confirmed capture yet includes an assigned technician (the
  // sample ticket used to build this mapper was still "Awaiting
  // Approval"), so this checks the couple of plausible key shapes
  // defensively and otherwise falls back to "Not Assigned" — the
  // existing, already-correct behavior for a ticket with no technician.
  final technicianName = _firstNonEmptyName([
    json['technician'],
    json['assignedTechnician'],
    json['assignee'],
  ]);

  return ServiceRequest(
    id: id,
    title: subject,
    description: description,
    requester: (requesterName == null || requesterName.isEmpty)
        ? '--'
        : requesterName,
    site: (siteName == null || siteName.isEmpty) ? '--' : siteName,
    priority: priority,
    status: status,
    type: ServiceRequestOption.serviceRequest,
    dueDate: dueDate,
    raisedAt: raisedAt,
    phone: (requesterPhone == null || requesterPhone.isEmpty)
        ? null
        : requesterPhone,
    assignedTechnician: technicianName,
    building: (buildingName == null || buildingName.isEmpty)
        ? null
        : buildingName,
    classification: classification,
    spaceAsset: assetName,
  );
}

String? _firstNonEmptyName(List<dynamic> candidates) {
  for (final candidate in candidates) {
    if (candidate is Map<String, dynamic>) {
      final name = (candidate['name'] ?? candidate['primaryValue']) as String?;
      if (name != null && name.trim().isNotEmpty) return name.trim();
    }
  }
  return null;
}
/// (POST /client/api/v3/modules/serviceRequest) into a [ServiceRequest]
/// for the "My Service Requests" list. Unlike the list API, this response
/// carries `moduleState` inline (not as an id + supplement lookup), but
/// has no site/building/asset *names* — those come from whatever the
/// person had selected on the form, passed in here directly.
ServiceRequest mapCreatedServiceRequest(
  Map<String, dynamic> json, {
  required String requesterName,
  required String siteName,
  String? buildingName,
  RequestClassification classification = RequestClassification.problem,
  List<ServiceRequestAttachment> attachments = const [],
}) {
  final id = ServiceRequestListPageResult._asInt(json['id']) ?? 0;
  final subject = (json['subject'] as String?)?.trim() ?? '';
  final description = (json['description'] as String?)?.trim() ?? '';

  final sysCreatedTimeMs =
      ServiceRequestListPageResult._asInt(json['sysCreatedTime']);
  final raisedAt = sysCreatedTimeMs != null && sysCreatedTimeMs > 0
      ? DateTime.fromMillisecondsSinceEpoch(sysCreatedTimeMs)
      : DateTime.now();

  final dueDateMs = ServiceRequestListPageResult._asInt(json['dueDate']);
  final dueDate = dueDateMs != null && dueDateMs > 0
      ? DateTime.fromMillisecondsSinceEpoch(dueDateMs)
      : raisedAt;

  final moduleState = json['moduleState'];
  final status = ServiceRequestListPageResult._mapStatus(
    moduleState is Map<String, dynamic> ? moduleState : null,
  );

  final priorityInfo = json['priority_serviceRequest'];
  final priority = ServiceRequestListPageResult._mapPriority(
    priorityInfo is Map<String, dynamic> ? priorityInfo : null,
  );

  return ServiceRequest(
    id: id,
    title: subject,
    description: description,
    requester: requesterName.trim().isEmpty ? '--' : requesterName.trim(),
    site: siteName.trim().isEmpty ? '--' : siteName.trim(),
    priority: priority,
    status: status,
    type: ServiceRequestOption.serviceRequest,
    dueDate: dueDate,
    raisedAt: raisedAt,
    building: buildingName,
    classification: classification,
    attachments: attachments,
  );
}