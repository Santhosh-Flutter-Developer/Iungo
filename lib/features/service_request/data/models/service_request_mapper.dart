import 'package:iungo/features/service_request/domain/entities/service_request.dart';
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

  static String _normalize(String? value) {
    return (value ?? '').toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
  }

  static ServiceRequestPriority _mapPriority(
    Map<String, dynamic>? priorityInfo,
  ) {
    if (priorityInfo == null) return ServiceRequestPriority.noPriority;
    final label = _normalize(
      (priorityInfo['displayName'] ?? priorityInfo['primaryValue']) as String?,
    );
    switch (label) {
      case 'routine':
        return ServiceRequestPriority.routine;
      case 'urgent':
        return ServiceRequestPriority.urgent;
      case 'emergency':
        return ServiceRequestPriority.emergency;
      default:
        return ServiceRequestPriority.noPriority;
    }
  }

  static ServiceRequestStatus _mapStatus(
    Map<String, dynamic>? moduleStateInfo,
  ) {
    if (moduleStateInfo == null) return ServiceRequestStatus.open;
    final normalized = _normalize(
      (moduleStateInfo['status'] ?? moduleStateInfo['displayName']) as String?,
    );
    switch (normalized) {
      case 'acknowledged':
        return ServiceRequestStatus.acknowledged;
      case 'awaitingapproval':
        return ServiceRequestStatus.awaitingApproval;
      case 'closed':
        return ServiceRequestStatus.closed;
      case 'convertedasworkorder':
        return ServiceRequestStatus.convertedAsWorkorder;
      case 'onhold':
        return ServiceRequestStatus.onHold;
      case 'open':
        return ServiceRequestStatus.open;
      case 'rejected':
        return ServiceRequestStatus.rejected;
      default:
        return ServiceRequestStatus.open;
    }
  }
}
