import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:iungo/core/services/session_service.dart';
import 'package:iungo/features/work_order/data/models/work_order_mapper.dart';

import 'work_order_exceptions.dart';

/// Talks to the Iungo/Facilio "Awaiting for Pause Approval" list APIs.
///
/// Mirrors [WorkOrderClosureApprovalRemoteDataSourceImpl] exactly — same
/// query-parameter shape, same response parsing, same error handling —
/// swapping only the `viewName`/`view` path segment to
/// `awaitingforpauseworkorders`. The Detail View fetch is intentionally
/// left pointed at the `view/all` endpoint, unchanged from "All Work
/// Orders": Facilio's detail record is view-independent, so every Work
/// Order list (including this one) opens the exact same Detail View
/// API/URL/model.
abstract class WorkOrderPauseApprovalRemoteDataSource {
  /// Fetches one page of "Awaiting for Pause Approval" (1-indexed
  /// [page]) — the base, unfiltered list. Confirmed shape:
  ///
  ///   GET .../v3/modules/workorder/view/awaitingforpauseworkorders?
  ///       fetchOnlyViewGroupColumn=true&moduleName=workorder&
  ///       viewName=awaitingforpauseworkorders&page=<page>&
  ///       perPage=<perPage>&search=&withoutCustomButtons=true&
  ///       selectableFieldNames=description,serialNumber,status,subject,
  ///       dueDate,category,priority,siteId,type,assignedTo,createdBy&
  ///       expand=status,dueDate,category,priority,siteId,type,
  ///       assignedTo,createdBy
  Future<WorkOrderListPageResult> fetchWorkOrders({
    required int page,
    required int perPage,
  });

  /// Hits the server's `quickFilter` "Awaiting for Pause Approval"
  /// endpoint — used once a Status/Priority/Due-Date filter or a
  /// Find-Ticket lookup is active. Same `quickFilter` JSON shape as "All
  /// Work Orders" — see [WorkOrderRemoteDataSourceImpl.fetchFilteredWorkOrders].
  Future<WorkOrderListPageResult> fetchFilteredWorkOrders({
    required int page,
    required int perPage,
    Map<String, List<String>>? quickFilter,
    String? search,
  });

  /// Fetches the full record for one work order — identical endpoint,
  /// request shape, and response parsing to "All Work Orders"' own
  /// [WorkOrderRemoteDataSourceImpl.fetchWorkOrderDetail] (always
  /// `view/all`, regardless of which list the ticket was opened from).
  Future<Map<String, dynamic>> fetchWorkOrderDetail(int id);
}

class WorkOrderPauseApprovalRemoteDataSourceImpl
    implements WorkOrderPauseApprovalRemoteDataSource {
  WorkOrderPauseApprovalRemoteDataSourceImpl(this._dio, this._session);

  final Dio _dio;
  final SessionService _session;

  static const _baseUrl =
      'https://citgroup.facilioclients.com/client/api/v3/modules/workorder';
  static const _viewName = 'awaitingforpauseworkorders';
  static const _pauseApprovalUrl = '$_baseUrl/view/$_viewName';

  // Detail View is view-independent — same endpoint "All Work Orders"
  // uses for its own Detail View fetch.
  static const _detailUrl = '$_baseUrl/view/all';

  static const _selectableFieldNames =
      'description,serialNumber,status,subject,dueDate,category,priority,'
      'siteId,type,assignedTo,createdBy';
  static const _expandFields =
      'status,dueDate,category,priority,siteId,type,assignedTo,createdBy';

  @override
  Future<WorkOrderListPageResult> fetchWorkOrders({
    required int page,
    required int perPage,
  }) async {
    return _get(
      _pauseApprovalUrl,
      {
        'fetchOnlyViewGroupColumn': true,
        'moduleName': 'workorder',
        'viewName': _viewName,
        'page': page,
        'perPage': 50,
        'search': '',
        'withoutCustomButtons': true,
        'selectableFieldNames': _selectableFieldNames,
        'expand': _expandFields,
      },
      fallbackMessage: 'Failed to load work orders',
    );
  }

  @override
  Future<WorkOrderListPageResult> fetchFilteredWorkOrders({
    required int page,
    required int perPage,
    Map<String, List<String>>? quickFilter,
    String? search,
  }) async {
    final hasQuickFilter = quickFilter != null && quickFilter.isNotEmpty;

    return _get(
      _pauseApprovalUrl,
      {
        'fetchOnlyViewGroupColumn': true,
        'moduleName': 'workorder',
        'viewName': _viewName,
        'page': page,
        'perPage': 50,
        'search': search ?? '',
        if (hasQuickFilter)
          'quickFilter': jsonEncode({
            for (final entry in quickFilter.entries)
              entry.key: {'value': entry.value},
          }),
        'withoutCustomButtons': true,
        'selectableFieldNames': _selectableFieldNames,
        'expand': _expandFields,
      },
      fallbackMessage: 'Failed to load work orders',
    );
  }

  @override
  Future<Map<String, dynamic>> fetchWorkOrderDetail(int id) async {
    const fallbackMessage = 'Failed to load work order';
    try {
      final token = _session.token.value;

      final response = await _dio.get<dynamic>(
        _detailUrl,
        queryParameters: {
          'fetchOnlyViewGroupColumn': true,
          'moduleName': 'workorder',
          'viewName': 'all',
          'page': 1,
          'perPage': 50,
          'search': '',
          'withoutCustomButtons': true,
          'id': id,
          'selectableFieldNames': _selectableFieldNames,
          'expand': _expandFields,
        },
        options: Options(
          headers: {
            'Accept': 'application/json',
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
        ),
      );

      final body = _asMap(response.data);
      if (body == null) {
        throw const WorkOrderException('Unexpected response from server');
      }

      final code = body['code'];
      if (code != null && code != 0) {
        throw WorkOrderException(
          (body['message'] ?? fallbackMessage).toString(),
        );
      }

      final data = body['data'];
      final workorder =
          (data is Map<String, dynamic>) ? data['workorder'] : null;
      if (workorder is! Map<String, dynamic>) {
        throw const WorkOrderException('Unexpected response from server');
      }
      return workorder;
    } on DioException catch (e) {
      throw mapWorkOrderError(e, fallbackMessage: fallbackMessage);
    } on WorkOrderException {
      rethrow;
    } catch (_) {
      throw const WorkOrderException(fallbackMessage);
    }
  }

  Future<WorkOrderListPageResult> _get(
    String url,
    Map<String, dynamic> queryParameters, {
    required String fallbackMessage,
  }) async {
    try {
      final token = _session.token.value;

      final response = await _dio.get<dynamic>(
        url,
        queryParameters: queryParameters,
        options: Options(
          headers: {
            'Accept': 'application/json',
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
        ),
      );

      final body = _asMap(response.data);
      if (body == null) {
        throw const WorkOrderException('Unexpected response from server');
      }

      final code = body['code'];
      if (code != null && code != 0) {
        throw WorkOrderException(
          (body['message'] ?? fallbackMessage).toString(),
        );
      }

      return WorkOrderListPageResult.fromJson(body);
    } on DioException catch (e) {
      throw mapWorkOrderError(e, fallbackMessage: fallbackMessage);
    } on WorkOrderException {
      rethrow;
    } catch (_) {
      throw WorkOrderException(fallbackMessage);
    }
  }

  Map<String, dynamic>? _asMap(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map<String, dynamic>) return raw;
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
