import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:iungo/core/services/session_service.dart';
import 'package:iungo/features/service_request/domain/entities/pick_list_option.dart';

import 'service_request_exceptions.dart';

abstract class ServiceRequestPickListRemoteDataSource {
  /// GET .../pickList/forms/serviceRequest/moduleState — options for the
  /// "Select Status" filter dropdown.
  Future<List<PickListOption>> fetchStatusOptions();

  /// GET .../pickList/forms/serviceRequest/priority_serviceRequest —
  /// options for the "Select Priority" filter dropdown.
  Future<List<PickListOption>> fetchPriorityOptions();
}

/// Talks to the Iungo/Facilio pick-list APIs that back the Status and
/// Priority filter dropdowns on the "My Service Requests" filter screen.
/// Same auth/error handling pattern as [ServiceRequestRemoteDataSourceImpl].
class ServiceRequestPickListRemoteDataSourceImpl
    implements ServiceRequestPickListRemoteDataSource {
  ServiceRequestPickListRemoteDataSourceImpl(this._dio, this._session);

  final Dio _dio;
  final SessionService _session;

  static const _statusUrl =
      'https://citgroup.facilioclients.com/client/api/v3/pickList/forms/serviceRequest/moduleState';
  static const _priorityUrl =
      'https://citgroup.facilioclients.com/client/api/v3/pickList/forms/serviceRequest/priority_serviceRequest';

  @override
  Future<List<PickListOption>> fetchStatusOptions() {
    return _fetch(_statusUrl, {'page': 1, 'perPage': 50});
  }

  @override
  Future<List<PickListOption>> fetchPriorityOptions() {
    return _fetch(_priorityUrl, {'perPage': 50, 'viewName': 'hidden-all'});
  }

  Future<List<PickListOption>> _fetch(
    String url,
    Map<String, dynamic> queryParameters,
  ) async {
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
        throw const ServiceRequestException('Unexpected response from server');
      }

      final code = body['code'];
      if (code != null && code != 0) {
        throw ServiceRequestException(
          (body['message'] ?? 'Failed to load options').toString(),
        );
      }

      final data = body['data'];
      final rawList =
          (data is Map<String, dynamic>) ? data['pickList'] : null;
      final items = (rawList is List) ? rawList : const [];

      return items
          .whereType<Map<String, dynamic>>()
          .map(PickListOption.fromJson)
          .where((option) => option.label.isNotEmpty)
          .toList();
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