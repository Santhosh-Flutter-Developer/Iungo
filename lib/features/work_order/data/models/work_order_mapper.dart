import 'package:iungo/features/service_request/domain/entities/service_request_priority.dart';
import 'package:iungo/features/work_order/domain/entities/work_order.dart';
import 'package:iungo/features/work_order/domain/entities/work_order_maintenance_type.dart';
import 'package:iungo/features/work_order/domain/entities/work_order_status.dart';

/// Parses one page of the "My Work Orders" list API into [WorkOrder]
/// entities.
///
/// Like Service Requests, the API (Facilio) returns a lightweight list
/// under `data.workorder`, where related fields (site, priority, status,
/// category, type, assignee, requester) are only referenced by id. The
/// actual objects for those ids live in a separate
/// `meta.supplements.workorder.<field>` lookup map, keyed by id as a
/// string — this class resolves both sides into flat, display-ready
/// [WorkOrder] values.
///
/// Two confirmed captures of this API return the status field under a
/// different key depending on the endpoint hit: the base
/// `view/all?selectableFieldNames=...status...` list names it `status`,
/// while the `view/myworkorders` (quickFilter) endpoint — and the
/// `pickList/forms/workorder/moduleState` dropdown — use `moduleState`.
/// Both are read defensively below so either shape parses correctly.
class WorkOrderListPageResult {
  const WorkOrderListPageResult({required this.workOrders, required this.rawCount});

  final List<WorkOrder> workOrders;

  /// Number of raw items returned by the server for this page — used by
  /// the caller to decide whether another page likely exists (a full
  /// page suggests more; a short page means the end was reached).
  final int rawCount;

  factory WorkOrderListPageResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final rawList = (data is Map<String, dynamic>) ? data['workorder'] : null;
    final items = (rawList is List) ? rawList : const [];

    final meta = json['meta'];
    final supplementsRoot =
        (meta is Map<String, dynamic>) ? meta['supplements'] : null;
    final supplements = (supplementsRoot is Map<String, dynamic>)
        ? supplementsRoot['workorder']
        : null;
    final supplementsMap =
        (supplements is Map<String, dynamic>) ? supplements : const <String, dynamic>{};

    final siteLookup = _idMap(supplementsMap['siteId']);
    final priorityLookup = _idMap(supplementsMap['priority']);
    final categoryLookup = _idMap(supplementsMap['category']);
    final typeLookup = _idMap(supplementsMap['type']);
    final assignedToLookup = _idMap(supplementsMap['assignedTo']);
    final createdByLookup = _idMap(supplementsMap['createdBy']);
    // `moduleState` is the underlying field name (matches the pick-list
    // endpoint); `status` is the alias the base `view/all` list returns
    // when it's asked for via `selectableFieldNames`. A given response
    // only ever populates one of the two supplement blocks.
    final moduleStateLookup = _idMap(supplementsMap['moduleState']);
    final statusLookup = _idMap(supplementsMap['status']);

    final workOrders = items
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => _mapWorkOrder(
            item,
            siteLookup: siteLookup,
            priorityLookup: priorityLookup,
            categoryLookup: categoryLookup,
            typeLookup: typeLookup,
            assignedToLookup: assignedToLookup,
            createdByLookup: createdByLookup,
            moduleStateLookup:
                moduleStateLookup.isNotEmpty ? moduleStateLookup : statusLookup,
          ),
        )
        .toList();

    return WorkOrderListPageResult(workOrders: workOrders, rawCount: items.length);
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

  static WorkOrder _mapWorkOrder(
    Map<String, dynamic> item, {
    required Map<int, Map<String, dynamic>> siteLookup,
    required Map<int, Map<String, dynamic>> priorityLookup,
    required Map<int, Map<String, dynamic>> categoryLookup,
    required Map<int, Map<String, dynamic>> typeLookup,
    required Map<int, Map<String, dynamic>> assignedToLookup,
    required Map<int, Map<String, dynamic>> createdByLookup,
    required Map<int, Map<String, dynamic>> moduleStateLookup,
  }) {
    final id = _asInt(item['id']) ?? 0;
    // The ticket number shown on cards/detail and used for Find Ticket —
    // never `id`/`localId`.
    final serialNumber = _asInt(item['serialNumber']) ?? id;

    final subject = (item['subject'] as String?)?.trim() ?? '';
    final description = (item['description'] as String?)?.trim() ?? '';

    final createdTimeMs = _asInt(item['createdTime']);
    final raisedAt = createdTimeMs != null && createdTimeMs > 0
        ? DateTime.fromMillisecondsSinceEpoch(createdTimeMs)
        : DateTime.now();

    final dueDateMs = _asInt(item['dueDate']);
    final dueDate = dueDateMs != null && dueDateMs > 0
        ? DateTime.fromMillisecondsSinceEpoch(dueDateMs)
        : raisedAt;

    final siteId = _asInt(item['siteId']);
    final siteInfo = siteId != null ? siteLookup[siteId] : null;
    final site = (siteInfo?['name'] as String?)?.trim();

    final priorityId = _asInt(_nestedId(item['priority']));
    final priorityInfo = priorityId != null ? priorityLookup[priorityId] : null;
    final priority = ServiceRequestPriorityX.fromApiLabel(
      (priorityInfo?['displayName'] ?? priorityInfo?['primaryValue']) as String?,
    );

    final categoryId = _asInt(_nestedId(item['category']));
    final categoryInfo = categoryId != null ? categoryLookup[categoryId] : null;
    final discipline =
        ((categoryInfo?['displayName'] ?? categoryInfo?['name']) as String?)
                ?.trim() ??
            '';

    final typeId = _asInt(_nestedId(item['type']));
    final typeInfo = typeId != null ? typeLookup[typeId] : null;
    final maintenanceType = WorkOrderMaintenanceTypeX.fromApiLabel(
      (typeInfo?['name'] ?? typeInfo?['description']) as String?,
    );

    final moduleStateId = _asInt(_nestedId(item['moduleState'] ?? item['status']));
    final moduleStateInfo =
        moduleStateId != null ? moduleStateLookup[moduleStateId] : null;
    final status = WorkOrderStatusX.fromApiLabel(
      (moduleStateInfo?['status'] ?? moduleStateInfo?['displayName']) as String?,
    );

    final assignedToId = _asInt(_nestedId(item['assignedTo']));
    final assignedToInfo = assignedToId != null ? assignedToLookup[assignedToId] : null;
    final assignedTechnician = (assignedToInfo?['name'] as String?)?.trim();

    // The requester shown next to the person icon on each card. Some
    // work orders (e.g. auto-generated PM tickets) genuinely have no
    // `createdBy` set by the server — those honestly show '--' below
    // rather than substituting the requesting client org's contact,
    // which would show the same name for every ticket under that
    // client and look like a single wrong value repeated everywhere.
    final createdById = _asInt(_nestedId(item['createdBy']));
    final createdByInfo = createdById != null ? createdByLookup[createdById] : null;
    final requester = (createdByInfo?['name'] as String?)?.trim();

    return WorkOrder(
      id: id,
      serialNumber: serialNumber,
      title: subject,
      description: description,
      requester: (requester == null || requester.isEmpty) ? '--' : requester,
      site: (site == null || site.isEmpty) ? '--' : site,
      priority: priority,
      status: status,
      discipline: discipline,
      maintenanceType: maintenanceType,
      dueDate: dueDate,
      raisedAt: raisedAt,
      assignedTechnician:
          (assignedTechnician == null || assignedTechnician.isEmpty)
              ? null
              : assignedTechnician,
    );
  }

  static dynamic _nestedId(dynamic value) {
    if (value is Map<String, dynamic>) return value['id'];
    return value;
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
