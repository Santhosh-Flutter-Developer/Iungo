import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:iungo/core/services/session_service.dart';
import 'package:iungo/features/work_order/data/models/work_order_detail_mapper.dart';
import 'package:iungo/features/work_order/domain/entities/work_order_attachment.dart';
import 'package:iungo/features/work_order/domain/entities/work_order_comment.dart';

import 'inventory_request_exceptions.dart';

/// Talks to the Notes and Attachments APIs backing the Inventory Request
/// Detail View's "Notes" and "Attachments" tabs.
///
/// Reuses [WorkOrderComment]/[WorkOrderAttachment] (and their mappers)
/// rather than duplicating near-identical models — the
/// [InventoryRequestDetailController]/tabs already do the same, and both
/// APIs return the same generic Facilio note/attachment response shapes
/// the Work Order side already parses correctly.
abstract class InventoryRequestDetailRemoteDataSource {
  /// GET /client/api/note/inventoryRequest/get/{id}
  ///     ?module=InventoryRequestnotes&onlyFetchParentNotes=true
  Future<List<WorkOrderComment>> fetchNotes(int inventoryRequestId);

  /// GET /client/api/attachment/inventoryrequestattachments/inventoryrequest/list/{id}
  Future<List<WorkOrderAttachment>> fetchAttachments(int inventoryRequestId);

  /// PATCH /client/api/v3/action/inventoryrequest/{inventoryRequestId}/transition
  ///
  /// Approves or rejects an Inventory Request sitting in "Awaiting
  /// Client Approval". Confirmed request shape:
  ///
  ///   { "id": <inventoryRequestId>, "stateTransitionId": <id>,
  ///     "data": { "transitionCommentData": {
  ///       "bodyHTML": "<p>...</p>", "body": "...",
  ///       "mentions": [], "attachments": [], "commentSharing": [] } } }
  ///
  /// [stateTransitionId] is the fixed id for the Approve (14145) or
  /// Reject (41229) action. [comment] is always sent as a
  /// `transitionCommentData` block — "Approved" by default for Approve,
  /// or the user-entered remarks for Reject.
  Future<void> submitTransition({
    required int inventoryRequestId,
    required int stateTransitionId,
    required String comment,
  });
}

class InventoryRequestDetailRemoteDataSourceImpl
    implements InventoryRequestDetailRemoteDataSource {
  InventoryRequestDetailRemoteDataSourceImpl(this._dio, this._session);

  final Dio _dio;
  final SessionService _session;

  static const _clientBase = 'https://citgroup.facilioclients.com/client/api';
  static const _actionBase =
      'https://citgroup.facilioclients.com/client/api/v3/action';

  // ---- Notes -----------------------------------------------------------

  @override
  Future<List<WorkOrderComment>> fetchNotes(int inventoryRequestId) async {
    const fallbackMessage = 'Failed to load notes';
    try {
      final response = await _dio.get<dynamic>(
        '$_clientBase/note/inventoryRequest/get/$inventoryRequestId',
        queryParameters: {
          'module': 'InventoryRequestnotes',
          'onlyFetchParentNotes': true,
        },
        options: Options(headers: _authHeaders()),
      );

      final raw = _asDecoded(response.data);
      if (raw is! List) {
        throw const InventoryRequestException('Unexpected response from server');
      }
      return WorkOrderCommentMapper.listFromJson(raw);
    } on InventoryRequestException {
      rethrow;
    } catch (e) {
      throw mapInventoryRequestError(e, fallbackMessage: fallbackMessage);
    }
  }

  // ---- Attachments -------------------------------------------------

  @override
  Future<List<WorkOrderAttachment>> fetchAttachments(
    int inventoryRequestId,
  ) async {
    const fallbackMessage = 'Failed to load attachments';
    try {
      final response = await _dio.get<dynamic>(
        '$_clientBase/attachment/inventoryrequestattachments/inventoryrequest/list/$inventoryRequestId',
        options: Options(headers: _authHeaders()),
      );

      final body = _asMap(response.data);
      if (body == null) {
        throw const InventoryRequestException('Unexpected response from server');
      }
      return WorkOrderAttachmentMapper.responseFromJson(body);
    } on InventoryRequestException {
      rethrow;
    } catch (e) {
      throw mapInventoryRequestError(e, fallbackMessage: fallbackMessage);
    }
  }

  // ---- Approve / Reject ---------------------------------------------

  @override
  Future<void> submitTransition({
    required int inventoryRequestId,
    required int stateTransitionId,
    required String comment,
  }) async {
    const fallbackMessage = 'Failed to submit your response';
    try {
      final response = await _dio.patch<dynamic>(
        '$_actionBase/inventoryrequest/$inventoryRequestId/transition',
        data: {
          'id': inventoryRequestId,
          'stateTransitionId': stateTransitionId,
          'data': {
            'transitionCommentData': {
              'bodyHTML': comment.isEmpty ? '' : '<p>$comment</p>',
              'body': comment,
              'mentions': [],
              'attachments': [],
              'commentSharing': [],
            },
          },
        },
        options: Options(headers: _authHeaders()),
      );

      final body = _asMap(response.data);
      if (body != null) {
        final code = body['code'];
        if (code != null && code != 0) {
          throw InventoryRequestException(
            (body['message'] ?? fallbackMessage).toString(),
          );
        }
      }
    } on InventoryRequestException {
      rethrow;
    } catch (e) {
      throw mapInventoryRequestError(e, fallbackMessage: fallbackMessage);
    }
  }

  // ---- Helpers -----------------------------------------------------

  Map<String, String> _authHeaders() {
    final token = _session.token.value;
    return {
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic>? _asMap(dynamic raw) {
    final decoded = _asDecoded(raw);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  dynamic _asDecoded(dynamic raw) {
    if (raw == null) return null;
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        return jsonDecode(raw);
      } catch (_) {
        return null;
      }
    }
    return raw;
  }
}