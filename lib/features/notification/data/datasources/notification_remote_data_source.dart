import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:iungo/core/services/session_service.dart';
import 'package:iungo/features/notification/data/models/notification_mapper.dart';

import 'notification_exceptions.dart';

abstract class NotificationRemoteDataSource {
  /// Fetches one page of the Notification screen's "All" tab
  /// (1-indexed [page]) — GET /client/api/v3/modules/usernotification
  /// (Portal API Guide §5.1). No filters are sent: the server already
  /// scopes the list to the logged-in user and sorts newest-first.
  Future<NotificationListPageResult> fetchNotifications({
    required int page,
    required int perPage,
  });

  /// GET /client/api/v3/usernotification/update/seen (§5.3) — clears the
  /// server's "unseen since last open" badge. Bare GET, no params.
  Future<void> markAllSeen();

  /// PATCH /client/api/v3/modules/usernotification/{id} (§5.3) — marks
  /// one notification's `notificationStatus` as Seen (3) on row tap.
  Future<void> markAsRead(int notificationId);
}

/// Talks to the Iungo/Facilio Notification API:
///
///   GET https://citgroup.facilioclients.com/client/api/v3/modules/
///       usernotification
///
/// with a Bearer token (the logged-in user's session token), following
/// the same request/response shape and error handling conventions as
/// [ServiceRequestRemoteDataSourceImpl].
class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  NotificationRemoteDataSourceImpl(this._dio, this._session);

  final Dio _dio;
  final SessionService _session;

  static const _clientBase = 'https://citgroup.facilioclients.com/client/api';
  static const _listUrl = '$_clientBase/v3/modules/usernotification';
  static const _markAllSeenUrl = '$_clientBase/v3/usernotification/update/seen';

  @override
  Future<NotificationListPageResult> fetchNotifications({
    required int page,
    required int perPage,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        _listUrl,
        queryParameters: {'page': page, 'perPage': perPage, 'withCount': true},
        options: Options(headers: _authHeaders()),
      );

      final body = _asMap(response.data);
      if (body == null) {
        throw const NotificationException('Unexpected response from server');
      }

      final code = body['code'];
      if (code != null && code != 0) {
        throw NotificationException(
          (body['message'] ?? 'Failed to load notifications').toString(),
        );
      }

      final result = NotificationListPageResult.fromJson(body);

      // TEMPORARY DIAGNOSTIC LOGGING — remove once the "only 1
      // notification shows up" discrepancy vs. the reference app is
      // resolved. This prints exactly what the server sent back so we
      // can tell a server-side scoping issue (raw item count is
      // genuinely small) apart from a client-side parsing bug (raw
      // count is large but the mapper only kept a few).
      if (kDebugMode) {
        final rawList = (body['data'] is Map<String, dynamic>)
            ? (body['data'] as Map<String, dynamic>)['usernotification']
            : null;
        debugPrint(
          '[Notification] page=$page perPage=$perPage → '
          'raw data.usernotification length='
          '${rawList is List ? rawList.length : 'MISSING/not a List'}, '
          'meta.pagination.totalCount=${result.totalCount}, '
          'parsed=${result.notifications.length}',
        );
        debugPrint('[Notification] raw response body: ${jsonEncode(body)}');
      }

      return result;
    } on NotificationException {
      rethrow;
    } catch (e) {
      throw mapNotificationError(
        e,
        fallbackMessage: 'Failed to load notifications',
      );
    }
  }

  @override
  Future<void> markAllSeen() async {
    try {
      // §5.3: "No parameters, no body — the server takes the user from
      // the session and stamps the 'last seen' timestamp."
      await _dio.get<dynamic>(
        _markAllSeenUrl,
        options: Options(headers: _authHeaders()),
      );
    } on NotificationException {
      rethrow;
    } catch (e) {
      // Best-effort housekeeping call — a failure here shouldn't block
      // the Notification screen from showing what it already fetched,
      // so callers may choose to swallow this rather than surface it.
      throw mapNotificationError(
        e,
        fallbackMessage: 'Failed to update notifications',
      );
    }
  }

  @override
  Future<void> markAsRead(int notificationId) async {
    try {
      final response = await _dio.patch<dynamic>(
        '$_listUrl/$notificationId',
        data: {
          'id': notificationId,
          'moduleName': 'usernotification',
          'data': {
            'notificationStatus': 3,
            'readAt': DateTime.now().millisecondsSinceEpoch,
          },
        },
        options: Options(headers: _authHeaders()),
      );

      final body = _asMap(response.data);
      if (body != null) {
        final code = body['code'] ?? body['responseCode'];
        if (code != null && code != 0) {
          throw NotificationException(
            (body['message'] ?? 'Failed to mark notification as read')
                .toString(),
          );
        }
      }
    } on NotificationException {
      rethrow;
    } catch (e) {
      // §5.3: unlike the list call, this route does check permissions —
      // a 403 here means the portal role needs UPDATE on the
      // notification tab, which mapNotificationError already surfaces.
      throw mapNotificationError(
        e,
        fallbackMessage: 'Failed to mark notification as read',
      );
    }
  }

  Map<String, String> _authHeaders() {
    final token = _session.token.value;
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
