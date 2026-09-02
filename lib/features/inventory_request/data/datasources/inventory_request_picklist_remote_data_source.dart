import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:iungo/core/services/session_service.dart';
import 'package:iungo/features/service_request/domain/entities/pick_list_option.dart';

import 'inventory_request_exceptions.dart';

abstract class InventoryRequestPickListRemoteDataSource {
  /// GET .../pickList/forms/inventoryrequest/moduleState — options for
  /// the "Select Status" filter dropdown, loaded live so status values
  /// are never hardcoded client-side.
  Future<List<PickListOption>> fetchStatusOptions();
}

/// Talks to the Iungo/Facilio pick-list API that backs the Status filter
/// dropdown on the "Awaiting Client Approval" Filter screen:
///
///   GET .../v3/pickList/forms/inventoryrequest/moduleState?perPage=50&
///       viewName=hidden-all
///
/// Same auth/error handling pattern and response shape
/// (`data.pickList` -> `[{label, value}]`) as
/// [WorkOrderPickListRemoteDataSourceImpl]; reuses the same
/// [PickListOption] model.
class InventoryRequestPickListRemoteDataSourceImpl
    implements InventoryRequestPickListRemoteDataSource {
  InventoryRequestPickListRemoteDataSourceImpl(this._dio, this._session);

  final Dio _dio;
  final SessionService _session;

  static const _statusUrl =
      'https://citgroup.facilioclients.com/client/api/v3/pickList/forms/inventoryrequest/moduleState';

  @override
  Future<List<PickListOption>> fetchStatusOptions() async {
    const fallbackMessage = 'Failed to load status options';
    try {
      final token = _session.token.value;

      final response = await _dio.get<dynamic>(
        _statusUrl,
        queryParameters: {'perPage': 50, 'viewName': 'hidden-all'},
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
        throw const InventoryRequestException('Unexpected response from server');
      }

      final code = body['code'];
      if (code != null && code != 0) {
        throw InventoryRequestException(
          (body['message'] ?? fallbackMessage).toString(),
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
      throw mapInventoryRequestError(e, fallbackMessage: fallbackMessage);
    } on InventoryRequestException {
      rethrow;
    } catch (_) {
      throw const InventoryRequestException(fallbackMessage);
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
