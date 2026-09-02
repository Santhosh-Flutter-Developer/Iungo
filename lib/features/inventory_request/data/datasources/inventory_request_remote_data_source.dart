import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:iungo/core/services/session_service.dart';
import 'package:iungo/features/inventory_request/data/models/inventory_request_mapper.dart';

import 'inventory_request_exceptions.dart';

abstract class InventoryRequestRemoteDataSource {
  /// Fetches one page of "Inventory Request → Awaiting Client Approval"
  /// (1-indexed [page]). Per the spec:
  ///
  ///   GET .../v3/modules/inventoryrequest/view/awaitingclientapproval_1?
  ///       fetchOnlyViewGroupColumn=true&moduleName=inventoryrequest&
  ///       viewName=awaitingclientapproval_1&page=<page>&perPage=<perPage>&
  ///       search=<search>&withoutCustomButtons=true
  ///
  /// [quickFilter], when non-empty, narrows the results server-side —
  /// e.g. `{'moduleState': ['2355'], 'reservationStatus': ['2']}` —
  /// matching the same `quickFilter` JSON shape used by every other list
  /// in this app (see [WorkOrderRemoteDataSource]/
  /// [ServiceRequestRemoteDataSource]).
  ///
  /// [search], when non-empty, is sent as the plain `search` query
  /// param — used by the Search screen.
  Future<InventoryRequestListPageResult> fetchAwaitingClientApproval({
    required int page,
    required int perPage,
    Map<String, List<String>>? quickFilter,
    String? search,
  });

  /// Fetches the full record for one Inventory Request — the Detail
  /// View's Overview tab. Per the spec:
  ///
  ///   GET .../v3/modules/inventoryrequest/view/all?
  ///       fetchOnlyViewGroupColumn=true&moduleName=inventoryrequest&
  ///       viewName=all&page=1&perPage=50&search=&
  ///       withoutCustomButtons=true&id=<id>
  ///
  /// Returns the *full* response envelope (`code`/`message`/`data`/
  /// `meta`), not just the extracted record — `meta.supplements` is
  /// needed to resolve id-based relation fields (Created By, Client
  /// Approval Authorities, etc.), same as the list endpoint.
  Future<Map<String, dynamic>> fetchInventoryRequestDetail(int id);
}

/// Talks to the Iungo/Facilio "Inventory Request" list/detail APIs.
class InventoryRequestRemoteDataSourceImpl
    implements InventoryRequestRemoteDataSource {
  InventoryRequestRemoteDataSourceImpl(this._dio, this._session);

  final Dio _dio;
  final SessionService _session;

  static const _baseUrl =
      'https://citgroup.facilioclients.com/client/api/v3/modules/inventoryrequest';
  static const _awaitingClientApprovalUrl =
      '$_baseUrl/view/awaitingclientapproval_1';
  static const _allUrl = '$_baseUrl/view/all';

  static const String moduleName = InventoryRequestListPageResult.moduleName;

  @override
  Future<InventoryRequestListPageResult> fetchAwaitingClientApproval({
    required int page,
    required int perPage,
    Map<String, List<String>>? quickFilter,
    String? search,
  }) async {
    const fallbackMessage = 'Failed to load inventory requests';
    final hasQuickFilter = quickFilter != null && quickFilter.isNotEmpty;
    final hasSearch = search != null && search.isNotEmpty;

    try {
      final token = _session.token.value;

      final response = await _dio.get<dynamic>(
        _awaitingClientApprovalUrl,
        queryParameters: {
          'fetchOnlyViewGroupColumn': true,
          'moduleName': moduleName,
          'viewName': 'awaitingclientapproval_1',
          'page': page,
          'perPage': perPage,
          'search': hasSearch ? search : '',
          if (hasQuickFilter)
            'quickFilter': jsonEncode({
              for (final entry in quickFilter.entries)
                entry.key: {'value': entry.value},
            }),
          'withoutCustomButtons': true,
        },
        options: Options(headers: _authHeaders(token)),
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

      return InventoryRequestListPageResult.fromJson(body);
    } on DioException catch (e) {
      throw mapInventoryRequestError(e, fallbackMessage: fallbackMessage);
    } on InventoryRequestException {
      rethrow;
    } catch (_) {
      throw const InventoryRequestException(fallbackMessage);
    }
  }

  @override
  Future<Map<String, dynamic>> fetchInventoryRequestDetail(int id) async {
    const fallbackMessage = 'Failed to load inventory request';
    try {
      final token = _session.token.value;

      final response = await _dio.get<dynamic>(
        _allUrl,
        queryParameters: {
          'fetchOnlyViewGroupColumn': true,
          'moduleName': moduleName,
          'viewName': 'all',
          'page': 1,
          'perPage': 50,
          'search': '',
          'withoutCustomButtons': true,
          'id': id,
        },
        options: Options(headers: _authHeaders(token)),
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
      final hasRecord = data is Map<String, dynamic> &&
          (data[moduleName] is Map<String, dynamic> ||
              (data[moduleName] is List &&
                  (data[moduleName] as List).isNotEmpty));
      if (!hasRecord) {
        throw const InventoryRequestException('Unexpected response from server');
      }

      // Returns the *full* envelope (not just the extracted record) so
      // the mapper can also read `meta.supplements.inventoryrequest` for
      // id-based relation lookups (Created By, Client Approval
      // Authorities, etc.) — the same envelope shape the list endpoint
      // returns, just narrowed to one record via `id=`.
      return body;
    } on DioException catch (e) {
      throw mapInventoryRequestError(e, fallbackMessage: fallbackMessage);
    } on InventoryRequestException {
      rethrow;
    } catch (_) {
      throw const InventoryRequestException(fallbackMessage);
    }
  }

  Map<String, String> _authHeaders(String? token) {
    return {
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
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
