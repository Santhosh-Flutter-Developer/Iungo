import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:iungo/core/services/session_service.dart';
import 'package:iungo/features/service_request/data/models/service_request_mapper.dart';

import 'service_request_exceptions.dart';

abstract class ServiceRequestRemoteDataSource {
  /// Fetches one page of "My Service Requests" (1-indexed [page]).
  ///
  /// [quickFilter], when non-empty, narrows the results server-side —
  /// e.g. `{'moduleState': ['2355'], 'priority_serviceRequest': ['43'],
  /// 'id': ['292']}` — matching the exact `quickFilter` JSON shape the
  /// real app sends (confirmed via Postman capture).
  Future<ServiceRequestListPageResult> fetchServiceRequests({
    required int page,
    required int perPage,
    Map<String, List<String>>? quickFilter,
  });
}

/// Talks to the Iungo/Facilio "My Service Requests" list API:
///
///   GET https://citgroup.facilioclients.com/client/api/v3/modules/
///       serviceRequest/view/allservicerequests
///
/// with `page`/`perPage` query params for pagination, and a Bearer token
/// (the logged-in user's session token — confirmed against the real
/// server via Postman, see the `Authorization: Bearer Token` tab).
class ServiceRequestRemoteDataSourceImpl
    implements ServiceRequestRemoteDataSource {
  ServiceRequestRemoteDataSourceImpl(this._dio, this._session);

  final Dio _dio;
  final SessionService _session;

  static const _baseUrl =
      'https://citgroup.facilioclients.com/client/api/v3/modules/serviceRequest/view/allservicerequests';

  @override
  Future<ServiceRequestListPageResult> fetchServiceRequests({
    required int page,
    required int perPage,
    Map<String, List<String>>? quickFilter,
  }) async {
    try {
      final token = _session.token.value;

      final hasQuickFilter = quickFilter != null && quickFilter.isNotEmpty;

      final response = await _dio.get<dynamic>(
        _baseUrl,
        queryParameters: {
          'fetchOnlyViewGroupColumn': true,
          'moduleName': 'serviceRequest',
          'viewName': 'allservicerequests',
          'page': page,
          'perPage': perPage,
          if (hasQuickFilter) 'search': '',
          if (hasQuickFilter)
            'quickFilter': jsonEncode({
              for (final entry in quickFilter.entries)
                entry.key: {'value': entry.value},
            }),
          'withoutCustomButtons': true,
          if (!hasQuickFilter)
            'expand': 'moduleState,priority_serviceRequest,sysCreatedBy',
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
        throw const ServiceRequestException('Unexpected response from server');
      }

      final code = body['code'];
      if (code != null && code != 0) {
        throw ServiceRequestException(
          (body['message'] ?? 'Failed to load service requests').toString(),
        );
      }

      return ServiceRequestListPageResult.fromJson(body);
    } on DioException catch (e) {
      final errorBody = _asMap(e.response?.data);
      final message = errorBody != null ? _extractMessage(errorBody) : null;
      throw ServiceRequestException(
        message ?? e.message ?? 'Something went wrong',
      );
    } on ServiceRequestException {
      rethrow;
    } catch (_) {
      throw const ServiceRequestException('Something went wrong');
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

  String? _extractMessage(Map<String, dynamic> body) {
    for (final key in ['message', 'Message', 'error', 'Error', 'msg']) {
      final value = body[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return null;
  }
}