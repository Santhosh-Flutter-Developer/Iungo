import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:iungo/core/services/session_service.dart';
import 'package:iungo/features/work_order/data/models/work_order_detail_mapper.dart';
import 'package:iungo/features/work_order/domain/entities/work_order_attachment.dart';
import 'package:iungo/features/work_order/domain/entities/work_order_comment.dart';

import 'work_order_exceptions.dart';

/// Talks to the Detail View's Tasks, Comments, and Attachments APIs — the
/// three sub-modules of a Work Order shown on the Detail View's other
/// three tabs.
abstract class WorkOrderDetailRemoteDataSource {
  /// GET /client/api/v2/tasks/parent/{id} — the ticket's task
  /// sections/checklist for the "Tasks" tab.
  Future<WorkOrderTaskResult> fetchTasks(int workOrderId);

  /// GET /client/api/note/workorder/get/{id} — top-level comments only
  /// (`onlyFetchParentNotes=true`), oldest first.
  Future<List<WorkOrderComment>> fetchComments(int workOrderId);

  /// GET /client/api/attachment/ticketattachments/workorder/list/{id}
  Future<List<WorkOrderAttachment>> fetchAttachments(int workOrderId);

  /// PATCH /client/api/v3/action/workorder/{workOrderId}/transition —
  /// approves or rejects a work order sitting in an "Awaiting ...
  /// Approval from Client" status. Confirmed request shape:
  ///
  ///   { "id": <workOrderId>, "stateTransitionId": <id>,
  ///     "data": { "transitionCommentData": {
  ///       "bodyHTML": "<p>...</p>", "body": "...",
  ///       "mentions": [], "attachments": [], "commentSharing": [] } } }
  ///
  /// [stateTransitionId] is the fixed id for the specific
  /// status+action pair — see [WorkOrderStatusX.approveTransitionId]/
  /// [WorkOrderStatusX.rejectTransitionId]. [comment] is always sent as
  /// a `transitionCommentData` block; pass an empty string for Approve
  /// when the user didn't type anything (remarks are only mandatory for
  /// Reject, enforced by the Reject dialog itself).
  Future<void> submitTransition({
    required int workOrderId,
    required int stateTransitionId,
    required String comment,
  });
}

class WorkOrderDetailRemoteDataSourceImpl
    implements WorkOrderDetailRemoteDataSource {
  WorkOrderDetailRemoteDataSourceImpl(this._dio, this._session);

  final Dio _dio;
  final SessionService _session;

  static const _clientBase = 'https://citgroup.facilioclients.com/client/api';
  static const _actionBase =
      'https://citgroup.facilioclients.com/client/api/v3/action';

  // ---- Tasks -------------------------------------------------------

  @override
  Future<WorkOrderTaskResult> fetchTasks(int workOrderId) async {
    try {
      final response = await _dio.get<dynamic>(
        '$_clientBase/v2/tasks/parent/$workOrderId',
        options: Options(headers: _authHeaders()),
      );

      final body = _asMap(response.data);
      if (body == null) {
        throw const WorkOrderException('Unexpected response from server');
      }

      final responseCode = body['responseCode'];
      if (responseCode != null && responseCode != 0) {
        throw WorkOrderException(
          (body['message'] ?? 'Failed to load tasks').toString(),
        );
      }

      return WorkOrderTaskResult.fromJson(body);
    } on WorkOrderException {
      rethrow;
    } catch (e) {
      throw mapWorkOrderError(e, fallbackMessage: 'Failed to load tasks');
    }
  }

  // ---- Comments -------------------------------------------------------

  @override
  Future<List<WorkOrderComment>> fetchComments(int workOrderId) async {
    try {
      final response = await _dio.get<dynamic>(
        '$_clientBase/note/workorder/get/$workOrderId',
        queryParameters: {
          'module': 'ticketnotes',
          'onlyFetchParentNotes': true,
        },
        options: Options(headers: _authHeaders()),
      );

      final raw = _asDecoded(response.data);
      if (raw is! List) {
        throw const WorkOrderException('Unexpected response from server');
      }
      return WorkOrderCommentMapper.listFromJson(raw);
    } on WorkOrderException {
      rethrow;
    } catch (e) {
      throw mapWorkOrderError(e, fallbackMessage: 'Failed to load comments');
    }
  }

  // ---- Attachments ---------------------------------------------------

  @override
  Future<List<WorkOrderAttachment>> fetchAttachments(int workOrderId) async {
    try {
      final response = await _dio.get<dynamic>(
        '$_clientBase/attachment/ticketattachments/workorder/list/$workOrderId',
        options: Options(headers: _authHeaders()),
      );

      final body = _asMap(response.data);
      if (body == null) {
        throw const WorkOrderException('Unexpected response from server');
      }
      return WorkOrderAttachmentMapper.responseFromJson(body);
    } on WorkOrderException {
      rethrow;
    } catch (e) {
      throw mapWorkOrderError(e, fallbackMessage: 'Failed to load attachments');
    }
  }

  // ---- Approve / Reject -------------------------------------------------

  @override
  Future<void> submitTransition({
    required int workOrderId,
    required int stateTransitionId,
    required String comment,
  }) async {
    const fallbackMessage = 'Failed to submit your response';
    try {
      final response = await _dio.patch<dynamic>(
        '$_actionBase/workorder/$workOrderId/transition',
        data: {
          'id': workOrderId,
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
          throw WorkOrderException(
            (body['message'] ?? fallbackMessage).toString(),
          );
        }
      }
    } on WorkOrderException {
      rethrow;
    } catch (e) {
      throw mapWorkOrderError(e, fallbackMessage: fallbackMessage);
    }
  }

  // ---- Helpers ---------------------------------------------------------

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