import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:iungo/core/services/session_service.dart';
import 'package:iungo/features/work_order/data/models/work_order_mapper.dart';

import 'work_order_exceptions.dart';

abstract class WorkOrderRemoteDataSource {
  /// Fetches one page of "My Work Orders" (1-indexed [page]) — the base,
  /// unfiltered list. Confirmed via Postman capture:
  ///
  ///   GET .../v3/modules/workorder/view/myworkorders?
  ///       fetchOnlyViewGroupColumn=true&moduleName=workorder&
  ///       viewName=myworkorders&page=<page>&perPage=<perPage>&search=&
  ///       withoutCustomButtons=true&selectableFieldNames=description,
  ///       serialNumber,status,subject,dueDate,category,priority,siteId,
  ///       type,assignedTo,createdBy&expand=status,dueDate,category,
  ///       priority,siteId,type,assignedTo,createdBy
  Future<WorkOrderListPageResult> fetchWorkOrders({
    required int page,
    required int perPage,
  });

  /// Hits the server's `quickFilter` "My Work Orders" endpoint — used
  /// once a Status/Priority/Due-Date filter or a Find-Ticket lookup is
  /// active. Confirmed via Postman capture:
  ///
  ///   GET .../v3/modules/workorder/view/myworkorders?
  ///       fetchOnlyViewGroupColumn=true&moduleName=workorder&
  ///       viewName=myworkorders&page=<page>&perPage=<perPage>&
  ///       search=<search>&quickFilter=<json>&withoutCustomButtons=true
  ///
  /// [quickFilter] carries field->value(s) pairs, e.g.
  /// `{'priority': ['43'], 'moduleState': ['147855'],
  /// 'dueDate': ['<startMs>', '<endMs>'], 'serialNumber': ['1415033']}` —
  /// matching the exact `quickFilter` JSON shape captured from the real
  /// app. Ticket lookups filter by `serialNumber` (the number shown on
  /// each card), never `id`/`localId`.
  Future<WorkOrderListPageResult> fetchFilteredWorkOrders({
    required int page,
    required int perPage,
    Map<String, List<String>>? quickFilter,
    String? search,
  });
}

/// Talks to the Iungo/Facilio "My Work Orders" list APIs.
class WorkOrderRemoteDataSourceImpl implements WorkOrderRemoteDataSource {
  WorkOrderRemoteDataSourceImpl(this._dio, this._session);

  final Dio _dio;
  final SessionService _session;

  static const _baseUrl =
      'https://citgroup.facilioclients.com/client/api/v3/modules/workorder';
  static const _myWorkOrdersUrl = '$_baseUrl/view/all';

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
      _myWorkOrdersUrl,
      {
        'fetchOnlyViewGroupColumn': true,
        'moduleName': 'workorder',
        'viewName': 'all',
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
      _myWorkOrdersUrl,
      {
        'fetchOnlyViewGroupColumn': true,
        'moduleName': 'workorder',
        'viewName': 'all',
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
