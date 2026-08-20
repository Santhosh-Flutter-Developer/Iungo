import 'package:get/get.dart';
import 'package:iungo/features/service_request/data/datasources/service_request_picklist_remote_data_source.dart';
import 'package:iungo/features/service_request/data/datasources/service_request_remote_data_source.dart';
import 'package:iungo/features/service_request/data/models/service_request_mapper.dart';
import 'package:iungo/features/service_request/domain/entities/pick_list_option.dart';
import 'package:iungo/features/service_request/domain/entities/request_classification.dart';
import 'package:iungo/features/service_request/domain/entities/service_request.dart';
import 'package:iungo/features/service_request/domain/entities/service_request_option.dart';
import 'package:iungo/features/service_request/domain/entities/service_request_priority.dart';
import 'package:iungo/features/service_request/domain/entities/service_request_status.dart';

/// Single in-memory source of truth for "My Service Requests".
///
/// Registered as a permanent GetxService (not tied to a page's lifecycle)
/// so that submitting the "New Service Request" form and viewing the list
/// both read/write the same [tickets] list — a newly created request shows
/// up at the top of "My Service Requests" immediately.
///
/// Backed by the real list API (paginated, 10 per page). Pages are
/// fetched by [ServiceRequestListController] (which owns the current
/// page/loading state for infinite scroll) and pushed in here via
/// [replaceWithPage] / [appendPage].
class ServiceRequestRepository extends GetxService {
  ServiceRequestRepository(this._remoteDataSource, this._pickListDataSource);

  final ServiceRequestRemoteDataSource _remoteDataSource;
  final ServiceRequestPickListRemoteDataSource _pickListDataSource;

  final RxList<ServiceRequest> tickets = <ServiceRequest>[].obs;

  /// Ids used for tickets created locally (via the "New Service Request"
  /// sheet) before a refresh pulls the real record down from the server.
  int _nextLocalId = -1;

  // Cached so the Filter screen's dropdowns don't re-hit the pickList
  // APIs every time it's opened during a session.
  List<PickListOption>? _cachedStatusOptions;
  List<PickListOption>? _cachedPriorityOptions;

  Future<ServiceRequestListPageResult> fetchPage({
    required int page,
    required int perPage,
    Map<String, List<String>>? quickFilter,
    String? search,
  }) {
    return _remoteDataSource.fetchServiceRequests(
      page: page,
      perPage: perPage,
      quickFilter: quickFilter,
      search: search,
    );
  }

  Future<List<PickListOption>> fetchStatusOptions({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedStatusOptions != null) {
      return _cachedStatusOptions!;
    }
    final options = await _pickListDataSource.fetchStatusOptions();
    _cachedStatusOptions = options;
    return options;
  }

  Future<List<PickListOption>> fetchPriorityOptions({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedPriorityOptions != null) {
      return _cachedPriorityOptions!;
    }
    final options = await _pickListDataSource.fetchPriorityOptions();
    _cachedPriorityOptions = options;
    return options;
  }

  /// Replaces the whole list with a freshly-fetched first page (initial
  /// load / pull-to-refresh).
  void replaceWithPage(List<ServiceRequest> page) {
    tickets.assignAll(page);
  }

  /// Appends a subsequent page, skipping any ids already present (guards
  /// against duplicate cards if a ticket shifts pages between requests).
  void appendPage(List<ServiceRequest> page) {
    final existingIds = tickets.map((t) => t.id).toSet();
    final newOnes = page.where((t) => !existingIds.contains(t.id));
    tickets.addAll(newOnes);
  }

  void addFromSubmission({
    required String subject,
    required String description,
    required String site,
  }) {
    tickets.insert(
      0,
      ServiceRequest(
        id: _nextLocalId--,
        title: subject,
        description: description,
        requester: 'You',
        site: site,
        priority: ServiceRequestPriority.noPriority,
        status: ServiceRequestStatus.open,
        type: ServiceRequestOption.serviceRequest,
        dueDate: DateTime.now(),
        building: site,
        classification: RequestClassification.problem,
      ),
    );
  }
}