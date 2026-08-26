import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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

  /// GET .../pickList/forms/serviceRequest/siteId — options for the
  /// "New Service Request" form's Site field.
  Future<List<PickListOption>> fetchSiteOptions({String? search});

  /// GET .../pickList/forms/serviceRequest/resource/building, scoped to
  /// [siteId] — options for the form's Building field.
  Future<List<PickListOption>> fetchBuildingOptions({
    required int siteId,
    String? search,
  });

  /// GET .../pickList/forms/serviceRequest/resource/asset, scoped to
  /// [siteId] — options for the form's Asset field.
  Future<List<PickListOption>> fetchAssetOptions({
    required int siteId,
    String? search,
  });
}


/// Talks to the Iungo/Facilio pick-list APIs that back the Status and
/// Priority filter dropdowns on the "My Service Requests" filter screen,
/// and the Site/Building/Asset choosers on the "New Service Request" form.
/// Same auth/error handling pattern as [ServiceRequestRemoteDataSourceImpl].
class ServiceRequestPickListRemoteDataSourceImpl
    implements ServiceRequestPickListRemoteDataSource {
  ServiceRequestPickListRemoteDataSourceImpl(this._dio, this._session);

  final Dio _dio;
  final SessionService _session;

  static const _baseUrl =
      'https://citgroup.facilioclients.com/client/api/v3/pickList/forms/serviceRequest';
  static const _statusUrl = '$_baseUrl/moduleState';
  static const _priorityUrl = '$_baseUrl/priority_serviceRequest';
  static const _siteUrl = '$_baseUrl/siteId';
  static const _buildingUrl = '$_baseUrl/resource/building';
  static const _assetUrl = '$_baseUrl/resource/asset';

  /// operator 36 = lookup "is" (confirmed via the picklist/attachment API
  /// reference doc).
  static const _isOperatorId = 36;

  @override
  Future<List<PickListOption>> fetchStatusOptions() {
    return _fetch(_statusUrl, {'page': 1, 'perPage': 50});
  }

  @override
  Future<List<PickListOption>> fetchPriorityOptions() {
    return _fetch(_priorityUrl, {'perPage': 50, 'viewName': 'hidden-all'});
  }

  @override
  Future<List<PickListOption>> fetchSiteOptions({String? search}) {
    return _fetch(_siteUrl, _pageOrSearchParams(search)
      ..addAll({
        'includeDefaultIdsValue': true,
        'viewName': 'hidden-all',
      }));
  }

  @override
  Future<List<PickListOption>> fetchBuildingOptions({
    required int siteId,
    String? search,
  }) {
    return _fetch(
      _buildingUrl,
      _pageOrSearchParams(search)
        ..addAll({
          'includeDefaultIdsValue': true,
          'viewName': 'hidden-all',
          'filters': jsonEncode({
            'siteId': {
              'operatorId': _isOperatorId,
              'value': [siteId.toString()],
            },
          }),
        }),
    );
  }

  @override
  Future<List<PickListOption>> fetchAssetOptions({
    required int siteId,
    String? search,
  }) {
    return _fetch(
      _assetUrl,
      _pageOrSearchParams(search)
        ..addAll({
          'includeDefaultIdsValue': true,
          'viewName': 'hidden-all',
          'filters': jsonEncode({
            'siteId': {
              'operatorId': _isOperatorId,
              'value': [siteId.toString()],
            },
          }),
        }),
    );
  }

  /// Dropdowns load with `page`/`perPage`; once the user types, those are
  /// dropped in favour of `search` (confirmed via the picklist/attachment
  /// API reference doc).
  Map<String, dynamic> _pageOrSearchParams(String? search) {
    final trimmed = search?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return {'search': trimmed};
    }
    return {'page': 1, 'perPage': 50};
  }

  Future<List<PickListOption>> _fetch(
    String url,
    Map<String, dynamic> queryParameters,
  ) async {
    final items = await _fetchItems(url, queryParameters);
    return items
        .map(PickListOption.fromJson)
        .where((option) => option.label.isNotEmpty)
        .toList();
  }

  /// Shared request + response-envelope handling for every pick-list
  /// endpoint — returns each `data.pickList[]` entry's raw JSON, before
  /// any reduction down to [PickListOption].
  Future<List<Map<String, dynamic>>> _fetchItems(
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

      if (kDebugMode) {
        debugPrint(
          '[PickList] GET $url $queryParameters -> '
          'HTTP ${response.statusCode}, body: ${response.data}',
        );
      }

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

      if (kDebugMode) {
        debugPrint('[PickList] $url -> ${items.length} item(s)');
      }

      return items.whereType<Map<String, dynamic>>().toList();
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[PickList] GET $url $queryParameters FAILED: '
          'HTTP ${e.response?.statusCode}, body: ${e.response?.data ?? e.message}',
        );
      }
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