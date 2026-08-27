import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:iungo/core/services/session_service.dart';
import 'package:iungo/features/service_request/domain/entities/pick_list_option.dart';

import 'work_order_exceptions.dart';

abstract class WorkOrderPickListRemoteDataSource {
  /// GET .../pickList/forms/workorder/moduleState — options for the
  /// "Select Status" filter dropdown.
  Future<List<PickListOption>> fetchStatusOptions();

  /// GET .../pickList/forms/workorder/priority — options for the
  /// "Select Priority" filter dropdown.
  Future<List<PickListOption>> fetchPriorityOptions();
}

/// Talks to the Iungo/Facilio pick-list APIs that back the Status and
/// Priority filter dropdowns on the "My Work Orders" filter screen —
/// confirmed via Postman capture:
///
///   GET .../pickList/forms/workorder/priority?perPage=50&
///       viewName=hidden-all
///   GET .../pickList/forms/workorder/moduleState?perPage=50&
///       viewName=hidden-all
///
/// Same auth/error handling pattern as [WorkOrderRemoteDataSourceImpl].
class WorkOrderPickListRemoteDataSourceImpl
    implements WorkOrderPickListRemoteDataSource {
  WorkOrderPickListRemoteDataSourceImpl(this._dio, this._session);

  final Dio _dio;
  final SessionService _session;

  static const _baseUrl =
      'https://citgroup.facilioclients.com/client/api/v3/pickList/forms/workorder';
  static const _statusUrl = '$_baseUrl/moduleState';
  static const _priorityUrl = '$_baseUrl/priority';

  @override
  Future<List<PickListOption>> fetchStatusOptions() {
    return _fetch(_statusUrl);
  }

  @override
  Future<List<PickListOption>> fetchPriorityOptions() {
    return _fetch(_priorityUrl);
  }

  Future<List<PickListOption>> _fetch(String url) async {
    try {
      final token = _session.token.value;

      final response = await _dio.get<dynamic>(
        url,
        queryParameters: {'perPage': 50, 'viewName': 'hidden-all'},
        options: Options(
          headers: {
            'Accept': 'application/json',
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
        ),
      );

      if (kDebugMode) {
        debugPrint('[WorkOrderPickList] GET $url -> HTTP ${response.statusCode}');
      }

      final body = _asMap(response.data);
      if (body == null) {
        throw const WorkOrderException('Unexpected response from server');
      }

      final code = body['code'];
      if (code != null && code != 0) {
        throw WorkOrderException(
          (body['message'] ?? 'Failed to load options').toString(),
        );
      }

      final data = body['data'];
      final rawList = (data is Map<String, dynamic>) ? data['pickList'] : null;
      final items = (rawList is List) ? rawList : const [];

      return items
          .whereType<Map<String, dynamic>>()
          .map(PickListOption.fromJson)
          .where((option) => option.label.isNotEmpty)
          .toList();
    } on DioException catch (e) {
      throw mapWorkOrderError(e, fallbackMessage: 'Failed to load options');
    } on WorkOrderException {
      rethrow;
    } catch (_) {
      throw const WorkOrderException('Failed to load options');
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
