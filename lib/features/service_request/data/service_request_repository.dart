import 'package:get/get.dart';
import 'package:iungo/features/service_request/data/datasources/service_request_create_remote_data_source.dart';
import 'package:iungo/features/service_request/data/datasources/service_request_exceptions.dart';
import 'package:iungo/features/service_request/data/datasources/service_request_picklist_remote_data_source.dart';
import 'package:iungo/features/service_request/data/datasources/service_request_remote_data_source.dart';
import 'package:iungo/features/service_request/data/models/service_request_mapper.dart';
import 'package:iungo/features/service_request/domain/entities/attachment_file.dart';
import 'package:iungo/features/service_request/domain/entities/pick_list_option.dart';
import 'package:iungo/features/service_request/domain/entities/request_classification.dart';
import 'package:iungo/features/service_request/domain/entities/service_request.dart';
import 'package:iungo/features/service_request/domain/entities/service_request_attachment.dart';

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
  ServiceRequestRepository(
    this._remoteDataSource,
    this._pickListDataSource,
    this._createDataSource,
  );

  final ServiceRequestRemoteDataSource _remoteDataSource;
  final ServiceRequestPickListRemoteDataSource _pickListDataSource;
  final ServiceRequestCreateRemoteDataSource _createDataSource;

  final RxList<ServiceRequest> tickets = <ServiceRequest>[].obs;

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

  Future<List<PickListOption>> fetchSiteOptions({String? search}) {
    return _pickListDataSource.fetchSiteOptions(search: search);
  }

  Future<List<PickListOption>> fetchBuildingOptions({
    required int siteId,
    String? search,
  }) {
    return _pickListDataSource.fetchBuildingOptions(
      siteId: siteId,
      search: search,
    );
  }

  Future<List<PickListOption>> fetchAssetOptions({
    required int siteId,
    String? search,
  }) {
    return _pickListDataSource.fetchAssetOptions(siteId: siteId, search: search);
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

  /// Uploads every picked file (if any), then creates the Service
  /// Request with those files' ids attached, and inserts the resulting
  /// ticket at the top of [tickets] so it shows up on "My Service
  /// Requests" immediately — matching the confirmed Postman flow
  /// (upload first, collect fileIds, then POST the create call).
  Future<ServiceRequest> submitNewServiceRequest({
    required String subject,
    required String description,
    required int siteId,
    required String siteName,
    int? resourceId,
    String? buildingName,
    String? locationFreeText,
    int? requesterId,
    String? requesterName,
    String? requesterEmail,
    String? requesterPhone,
    RequestClassification? classification,
    List<AttachmentFile> attachments = const [],
    required int formId,
  }) async {
    List<int> uploadedFileIds = const [];
    if (attachments.isNotEmpty) {
      uploadedFileIds = await _createDataSource.uploadAttachments(attachments);
      // Every picked file must have a fileId before we create the
      // record — otherwise the request would go through silently
      // missing whichever attachment failed to upload.
      if (uploadedFileIds.length != attachments.length) {
        throw const ServiceRequestException(
          'Failed to upload one or more attachments. Please try again.',
        );
      }
    }
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final data = <String, dynamic>{
      'subject': subject,
      'description': description,
      'siteId': siteId,
      if (resourceId != null) 'resource': {'id': resourceId},
      if (locationFreeText != null && locationFreeText.trim().isNotEmpty)
        'location___free_text___serviceRequest': locationFreeText,
      if (requesterId != null) 'requester': {'id': requesterId},
      if (requesterEmail != null)
        'requestor_email_serviceRequest': requesterEmail,
      'requestor_phone_serviceRequest': requesterPhone ?? '',
      'requestor_address_serviceRequest': null,
      'escalation_counter_serviceRequest': null,
      if (classification != null) 'classificationType': classification.apiValue,
      if (uploadedFileIds.isNotEmpty)
        'servicerequestsattachments': [
          for (final fileId in uploadedFileIds)
            {'fileId': fileId, 'createdTime': nowMs},
        ],
      'formId': formId,
      'actionFormId': formId,
      'mySignatureApplied': false,
    };

    final response = await _createDataSource.createServiceRequest(data);

    final ticket = mapCreatedServiceRequest(
      response,
      requesterName: requesterName ?? 'You',
      siteName: siteName,
      buildingName: buildingName,
      classification: classification ?? RequestClassification.problem,
      attachments: _toAttachmentDisplays(attachments),
    );

    tickets.insert(0, ticket);
    return ticket;
  }

  /// Turns the locally-picked files into display-ready attachments so
  /// the just-created ticket shows them immediately, without waiting on
  /// a refresh — the create response only echoes back fileId/createdTime,
  /// not name/size, so those come from what was actually picked.
  List<ServiceRequestAttachment> _toAttachmentDisplays(
    List<AttachmentFile> attachments,
  ) {
    final now = DateTime.now();
    final dateLabel =
        '${_month(now.month)} ${now.day}, ${now.year}';
    return [
      for (final file in attachments)
        ServiceRequestAttachment(
          name: file.name,
          extension: _extensionOf(file.name),
          sizeLabel: _sizeLabelFor(file),
          dateLabel: dateLabel,
          path: file.path,
          bytes: file.bytes,
        ),
    ];
  }

  String _extensionOf(String name) {
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == name.length - 1) return '';
    return name.substring(dotIndex + 1).toUpperCase();
  }

  String _sizeLabelFor(AttachmentFile file) {
    final bytes = file.bytes?.length;
    if (bytes == null) return '--';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  String _month(int month) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return names[(month - 1).clamp(0, 11)];
  }
}