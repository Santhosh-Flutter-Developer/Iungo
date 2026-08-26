import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:iungo/core/services/session_service.dart';

import 'asset_exceptions.dart';

/// One asset module lookup's full result: the matching raw asset
/// record(s), plus the `meta.supplements` block the server sends
/// alongside them — the only place the human-readable Category/
/// Building/Site names live (the asset record itself only carries
/// their numeric ids).
class AssetSearchResult {
  const AssetSearchResult(this.items, this.supplements);

  final List<Map<String, dynamic>> items;

  /// `meta.supplements.asset` from the response — a map of field name
  /// (e.g. "category", "buildingSpace", "siteId") to a map of id (as a
  /// string) to that referenced record's own full JSON.
  final Map<String, dynamic> supplements;
}

abstract class AssetRemoteDataSource {
  /// GET .../modules/asset/view/allassets, filtered with
  /// `quickFilter={"id":{"value":["<id>"]}}` — confirmed via a live
  /// network capture to return exactly the one matching asset (unlike
  /// the service-request form's asset picklist, which was confirmed
  /// NOT to filter by id at all and always returns its default page
  /// regardless of what's asked for).
  Future<AssetSearchResult> fetchAssetById(int id);
}

/// Talks to the Facilio web app's own "Assets" list API
/// (client/assets/assets/allassets) — the real per-asset lookup Scan QR
/// needs, as opposed to the New Service Request form's asset dropdown
/// (a different, more limited endpoint that can only browse/search its
/// own bounded picklist, not fetch an arbitrary asset by id).
///
/// AUTH CAVEAT: the live capture this was built from authenticated with
/// browser session artifacts (X-Csrf-Token, X-Org-Id, a session cookie)
/// rather than the Authorization: Bearer token every other endpoint in
/// this app uses. This class sends the Bearer token anyway, matching
/// every other data source here, since that's the only auth mechanism
/// the app currently has — but it is NOT confirmed to be accepted by
/// this particular endpoint. If it comes back 401/403, this route
/// genuinely needs the browser's session cookie, and calling it
/// successfully from the mobile app would require carrying that
/// cookie/CSRF pair (e.g. captured once via a login webview), which is
/// a materially bigger change than swapping a header.
class AssetRemoteDataSourceImpl implements AssetRemoteDataSource {
  AssetRemoteDataSourceImpl(this._dio, this._session);

  final Dio _dio;
  final SessionService _session;

  static const _url =
      'https://citgroup.facilioclients.com/client/api/v3/modules/asset/view/allassets';

  @override
  Future<AssetSearchResult> fetchAssetById(int id) async {
    try {
      final token = _session.token.value;

      final response = await _dio.get<dynamic>(
        _url,
        queryParameters: {
          'fetchOnlyViewGroupColumn': true,
          'moduleName': 'asset',
          'viewName': 'allassets',
          'page': 1,
          'perPage': 50,
          'search': '',
          'quickFilter': jsonEncode({
            'id': {
              'value': [id.toString()],
            },
          }),
          'withoutCustomButtons': true,
        },
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
          '[Asset] GET $_url id=$id -> HTTP ${response.statusCode}, '
          'body: ${response.data}',
        );
      }

      final body = _asMap(response.data);
      if (body == null) {
        throw const AssetException('Unexpected response from server');
      }

      final code = body['code'];
      if (code != null && code != 0) {
        throw AssetException(
          (body['message'] ?? 'Failed to load asset').toString(),
        );
      }

      final data = body['data'];
      final rawList = (data is Map<String, dynamic>) ? data['asset'] : null;
      final items = (rawList is List)
          ? rawList.whereType<Map<String, dynamic>>().toList()
          : <Map<String, dynamic>>[];

      final meta = body['meta'];
      final supplementsRoot =
          (meta is Map<String, dynamic>) ? meta['supplements'] : null;
      final supplements = (supplementsRoot is Map<String, dynamic>)
          ? (supplementsRoot['asset'] as Map<String, dynamic>? ?? const {})
          : const <String, dynamic>{};

      if (kDebugMode) {
        debugPrint('[Asset] $_url id=$id -> ${items.length} item(s)');
      }

      return AssetSearchResult(items, supplements);
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[Asset] GET $_url id=$id FAILED: '
          'HTTP ${e.response?.statusCode}, body: ${e.response?.data ?? e.message}',
        );
      }
      final errorBody = _asMap(e.response?.data);
      final message = errorBody != null ? _extractMessage(errorBody) : null;
      throw AssetException(message ?? e.message ?? 'Something went wrong');
    } on AssetException {
      rethrow;
    } catch (_) {
      throw const AssetException('Something went wrong');
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