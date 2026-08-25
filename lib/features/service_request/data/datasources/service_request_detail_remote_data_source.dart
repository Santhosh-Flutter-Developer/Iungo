import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:iungo/core/services/session_service.dart';
import 'package:iungo/features/service_request/data/models/service_request_detail_mapper.dart';
import 'package:iungo/features/service_request/domain/entities/attachment_file.dart';
import 'package:iungo/features/service_request/domain/entities/service_request_attachment.dart';
import 'package:iungo/features/service_request/domain/entities/service_request_comment.dart';

import 'service_request_exceptions.dart';

/// Talks to the Detail View's Comments and Attachments APIs — the
/// `servicerequestsnotes` and `servicerequestsattachments` sub-modules of
/// a Service Request, per the Iungo Portal API Guide §3 and §4.
abstract class ServiceRequestDetailRemoteDataSource {
  /// GET /client/api/note/serviceRequest/get/{id} — top-level comments
  /// only (`onlyFetchParentNotes=true`), oldest first (§3.1).
  Future<List<ServiceRequestComment>> fetchComments(int serviceRequestId);

  /// POST .../notes/servicerequestsnotes/serviceRequest/add/{id} — posts
  /// [body] as a new top-level comment and returns the server's copy
  /// (§3.2).
  Future<ServiceRequestComment> addComment(
    int serviceRequestId,
    String body,
  );

  /// GET .../attachment/servicerequestsattachments/serviceRequest/list/{id}
  /// (§4.1).
  Future<List<ServiceRequestAttachment>> fetchAttachments(
    int serviceRequestId,
  );

  /// POST .../attachment/servicerequestsattachments/serviceRequest/add/{id}
  /// — a single multipart request uploading every file in [files] at
  /// once (§4.2). Returns the newly created attachment records.
  Future<List<ServiceRequestAttachment>> uploadAttachments(
    int serviceRequestId,
    List<AttachmentFile> files,
  );

  /// POST .../attachment/servicerequestsattachments/serviceRequest/delete/{id}
  /// (§4.3).
  Future<void> deleteAttachment(int serviceRequestId, int attachmentId);
}

class ServiceRequestDetailRemoteDataSourceImpl
    implements ServiceRequestDetailRemoteDataSource {
  ServiceRequestDetailRemoteDataSourceImpl(this._dio, this._session);

  final Dio _dio;
  final SessionService _session;

  static const _clientBase = 'https://citgroup.facilioclients.com/client/api';

  /// Per Portal API Guide §4.4.
  static const _maxFileSizeBytes = 100 * 1024 * 1024;
  static const _maxRequestSizeBytes = 200 * 1024 * 1024;

  // ---- Comments ----------------------------------------------------

  @override
  Future<List<ServiceRequestComment>> fetchComments(
    int serviceRequestId,
  ) async {
    try {
      final response = await _dio.get<dynamic>(
        '$_clientBase/note/serviceRequest/get/$serviceRequestId',
        queryParameters: {
          'module': 'servicerequestsnotes',
          'onlyFetchParentNotes': true,
        },
        options: Options(headers: _authHeaders()),
      );

      final raw = _asDecoded(response.data);
      if (raw is! List) {
        throw const ServiceRequestException('Unexpected response from server');
      }
      return ServiceRequestCommentMapper.listFromJson(raw);
    } on ServiceRequestException {
      rethrow;
    } catch (e) {
      throw mapServiceRequestError(
        e,
        fallbackMessage: 'Failed to load comments',
      );
    }
  }

  @override
  Future<ServiceRequestComment> addComment(
    int serviceRequestId,
    String body,
  ) async {
    final text = body.trim();
    if (text.isEmpty) {
      throw const ServiceRequestException('Comment cannot be empty');
    }

    try {
      final response = await _dio.post<dynamic>(
        '$_clientBase/v2/notes/servicerequestsnotes/serviceRequest/add/$serviceRequestId',
        data: {
          'module': 'servicerequestsnotes',
          'parentModuleName': 'serviceRequest',
          'note': {
            'body': text,
            'parentId': serviceRequestId,
          },
        },
        options: Options(headers: _authHeaders()),
      );

      final responseBody = _asMap(response.data);
      if (responseBody == null) {
        throw const ServiceRequestException('Unexpected response from server');
      }

      final responseCode = responseBody['responseCode'];
      if (responseCode != null && responseCode != 0) {
        throw ServiceRequestException(
          (responseBody['message'] ?? 'Failed to post comment').toString(),
        );
      }

      final result = responseBody['result'];
      final notes = (result is Map<String, dynamic>) ? result['Notes'] : null;
      if (notes is Map<String, dynamic>) {
        return ServiceRequestCommentMapper.fromJson(notes);
      }

      // The server accepted the comment but didn't echo the full record
      // back — fall back to the id it did return, if any, so the tab
      // still shows something without needing a full reload.
      final noteId = (result is Map<String, dynamic>) ? result['note'] : null;
      return ServiceRequestComment(
        id: (noteId is num) ? noteId.toInt() : null,
        author: 'You',
        dateLabel: 'Today',
        message: text,
      );
    } on ServiceRequestException {
      rethrow;
    } catch (e) {
      throw mapServiceRequestError(
        e,
        fallbackMessage: 'Failed to post comment',
      );
    }
  }

  // ---- Attachments ---------------------------------------------------

  @override
  Future<List<ServiceRequestAttachment>> fetchAttachments(
    int serviceRequestId,
  ) async {
    try {
      final response = await _dio.get<dynamic>(
        '$_clientBase/attachment/servicerequestsattachments/serviceRequest/list/$serviceRequestId',
        options: Options(headers: _authHeaders()),
      );

      final body = _asMap(response.data);
      if (body == null) {
        throw const ServiceRequestException('Unexpected response from server');
      }
      return ServiceRequestAttachmentMapper.responseFromJson(body);
    } on ServiceRequestException {
      rethrow;
    } catch (e) {
      throw mapServiceRequestError(
        e,
        fallbackMessage: 'Failed to load attachments',
      );
    }
  }

  @override
  Future<List<ServiceRequestAttachment>> uploadAttachments(
    int serviceRequestId,
    List<AttachmentFile> files,
  ) async {
    if (files.isEmpty) return const [];

    _validateFileSizes(files);

    try {
      final formData = FormData.fromMap({
        'module': 'servicerequestsattachments',
        'recordId': serviceRequestId,
        'parentModuleName': 'serviceRequest',
      });

      // §4.2: repeat the `attachment` part name for every file — this is
      // a single request, not "upload then attach".
      for (final file in files) {
        final multipartFile = file.bytes != null
            ? MultipartFile.fromBytes(file.bytes!, filename: file.name)
            : await MultipartFile.fromFile(file.path!, filename: file.name);
        formData.files.add(MapEntry('attachment', multipartFile));
      }

      final response = await _dio.post<dynamic>(
        '$_clientBase/attachment/servicerequestsattachments/serviceRequest/add/$serviceRequestId',
        data: formData,
        options: Options(headers: _authHeaders()),
      );

      final body = _asMap(response.data);
      if (body == null) {
        throw const ServiceRequestException('Unexpected response from server');
      }
      return ServiceRequestAttachmentMapper.responseFromJson(body);
    } on ServiceRequestException {
      rethrow;
    } catch (e) {
      throw mapServiceRequestError(
        e,
        fallbackMessage: 'Failed to upload attachment',
      );
    }
  }

  @override
  Future<void> deleteAttachment(int serviceRequestId, int attachmentId) async {
    try {
      final response = await _dio.post<dynamic>(
        '$_clientBase/attachment/servicerequestsattachments/serviceRequest/delete/$serviceRequestId',
        data: {
          'module': 'servicerequestsattachments',
          'parentModuleName': 'serviceRequest',
          'recordId': serviceRequestId,
          'attachmentId': [attachmentId],
        },
        options: Options(headers: _authHeaders()),
      );

      // No documented failure shape for a 2xx response on this endpoint —
      // treat a successful HTTP status as success, but still honour an
      // explicit failure flag if the server sends one.
      final body = _asMap(response.data);
      if (body != null) {
        final code = body['code'] ?? body['responseCode'];
        if (code != null && code != 0) {
          throw ServiceRequestException(
            (body['message'] ?? 'Failed to delete attachment').toString(),
          );
        }
        final success = body['success'];
        if (success is bool && success == false) {
          throw ServiceRequestException(
            (body['message'] ?? 'Failed to delete attachment').toString(),
          );
        }
      }
    } on ServiceRequestException {
      rethrow;
    } catch (e) {
      throw mapServiceRequestError(
        e,
        fallbackMessage: 'Failed to delete attachment',
      );
    }
  }

  // ---- Helpers ---------------------------------------------------------

  /// Client-side pre-check against the Portal API Guide's §4.4 limits, so
  /// an oversized pick fails immediately instead of after a slow upload
  /// only to get back a 413. Files with no known [AttachmentFile.sizeBytes]
  /// are skipped here and left for the server to validate.
  void _validateFileSizes(List<AttachmentFile> files) {
    var totalKnownBytes = 0;
    for (final file in files) {
      final size = file.sizeBytes;
      if (size == null) continue;
      if (size > _maxFileSizeBytes) {
        throw ServiceRequestException(
          '"${file.name}" is larger than the 100 MB upload limit.',
        );
      }
      totalKnownBytes += size;
    }
    if (totalKnownBytes > _maxRequestSizeBytes) {
      throw const ServiceRequestException(
        'These files are larger than the 200 MB upload limit. '
        'Try uploading fewer at a time.',
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
