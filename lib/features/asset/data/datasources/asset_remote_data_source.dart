import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:iungo/core/services/session_service.dart';

import 'asset_exceptions.dart';

abstract class AssetRemoteDataSource {
  /// Looks up a single asset by whatever identifier the scanned QR code
  /// resolved to.
  ///
  /// When [id] is set (the QR encoded — or reduced to — a plain numeric
  /// asset id) this queries the Asset module the same way Service
  /// Request Detail queries by `id`: a single object comes back, not a
  /// list. When [code] is set instead (the QR encoded an asset code
  /// such as "facilio_112229" that didn't reduce to a bare id), this
  /// falls back to the same `search` param the Site/Building/Asset
  /// pick-lists already use and takes the first match.
  Future<Map<String, dynamic>> fetchAssetDetail({int? id, String? code});
}

/// Talks to the Iungo/Facilio Asset module:
///
///   GET https://citgroup.facilioclients.com/client/api/v3/modules/
///       asset/view/allassets
///
/// Same base host, auth header, and response envelope
/// (`code`/`message`/`data`) already confirmed for the Service Request
/// module in [ServiceRequestRemoteDataSourceImpl] — `moduleName`/
/// `viewName` are swapped to `asset`/`allassets` here to match. This
/// specific view name hasn't been confirmed against a live Postman
/// capture the way the Service Request endpoints were, so double-check
/// it (and the field names read in the mapper) against the real Asset
/// API response before shipping.
class AssetRemoteDataSourceImpl implements AssetRemoteDataSource {
  AssetRemoteDataSourceImpl(this._dio, this._session);

  final Dio _dio;
  final SessionService _session;

  static const _baseUrl =
      'https://citgroup.facilioclients.com/client/api/v3/modules/asset/view/allassets';

  @override
  Future<Map<String, dynamic>> fetchAssetDetail({int? id, String? code}) async {
    assert(
      (id != null) ^ (code != null),
      'Pass exactly one of id or code.',
    );
    try {
      final token = _session.token.value;

      final response = await _dio.get<dynamic>(
        _baseUrl,
        queryParameters: {
          'fetchOnlyViewGroupColumn': true,
          'moduleName': 'asset',
          'viewName': 'allassets',
          'page': 1,
          'perPage': id != null ? 1 : 5,
          'withoutCustomButtons': true,
          if (id != null) 'id': id,
          if (code != null) 'search': code,
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
        throw const AssetException('Unexpected response from server');
      }

      final responseCode = body['code'];
      if (responseCode != null && responseCode != 0) {
        throw AssetException(
          (body['message'] ?? 'Failed to load asset').toString(),
        );
      }

      final data = body['data'];
      final rawAsset = (data is Map<String, dynamic>) ? data['asset'] : null;

      // Looked up by `id` — the server responds with a single object,
      // same as Service Request Detail's `id`-based lookup.
      if (id != null) {
        if (rawAsset is! Map<String, dynamic>) {
          throw const AssetException('Asset not found for this QR code');
        }
        return rawAsset;
      }

      // Looked up by `search` (code) — a list comes back; take the
      // closest match.
      final items = (rawAsset is List) ? rawAsset : const [];
      final match = items.whereType<Map<String, dynamic>>().firstWhere(
            (item) => (item['assetCode'] ?? item['code'])
                    ?.toString()
                    .toLowerCase() ==
                code?.toLowerCase(),
            orElse: () => items.isNotEmpty
                ? items.first as Map<String, dynamic>
                : const <String, dynamic>{},
          );
      if (match.isEmpty) {
        throw const AssetException('Asset not found for this QR code');
      }
      return match;
    } on DioException catch (e) {
      final errorBody = _asMap(e.response?.data);
      final message = errorBody != null ? _extractMessage(errorBody) : null;
      throw AssetException(
        message ?? e.message ?? 'Something went wrong',
      );
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