import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:iungo/core/services/session_service.dart';
import 'package:iungo/features/service_request/domain/entities/attachment_file.dart';

import 'service_request_exceptions.dart';

abstract class ServiceRequestCreateRemoteDataSource {
  /// POST /client/api/v3/modules/data/files (multipart) — uploads every
  /// picked file first, before the Service Request itself is created
  /// (confirmed via the picklist/attachment API reference doc). Returns
  /// the uploaded fileIds in the same order as [files] (duplicate
  /// filenames are disambiguated before upload so each one resolves to
  /// its own id); those ids go into `servicerequestsattachments` on the
  /// create call.
  Future<List<int>> uploadAttachments(List<AttachmentFile> files);

  /// POST /client/api/v3/modules/serviceRequest — creates the Service
  /// Request record. [data] is the inner `data` object (subject,
  /// description, siteId, resource, requester, etc. — confirmed via
  /// Postman capture); this wraps it with `moduleName`. Returns the raw
  /// `data.serviceRequest` object from the response.
  Future<Map<String, dynamic>> createServiceRequest(
    Map<String, dynamic> data,
  );
}

class ServiceRequestCreateRemoteDataSourceImpl
    implements ServiceRequestCreateRemoteDataSource {
  ServiceRequestCreateRemoteDataSourceImpl(this._dio, this._session);

  final Dio _dio;
  final SessionService _session;

  static const _uploadUrl =
      'https://citgroup.facilioclients.com/client/api/v3/modules/data/files';
  static const _createUrl =
      'https://citgroup.facilioclients.com/client/api/v3/modules/serviceRequest';

  @override
  Future<List<int>> uploadAttachments(List<AttachmentFile> files) async {
    if (files.isEmpty) return const [];
    try {
      // The response maps back by filename, so duplicate names would
      // collide into a single entry — disambiguate before upload
      // (e.g. "photo.jpg", "photo (2).jpg") so every file gets its own
      // id back, in the same order as [files].
      final uploadNames = _disambiguateNames(files.map((f) => f.name));

      final formData = FormData();
      for (var i = 0; i < files.length; i++) {
        final file = files[i];
        final uploadName = uploadNames[i];
        final multipartFile = file.bytes != null
            ? MultipartFile.fromBytes(file.bytes!, filename: uploadName)
            : await MultipartFile.fromFile(file.path!, filename: uploadName);
        formData.files.add(MapEntry('files', multipartFile));
        formData.fields.add(MapEntry('fileNames', uploadName));
        formData.fields.add(
          MapEntry('contentTypes', _contentTypeFor(file.name)),
        );
      }

      final response = await _dio.post<dynamic>(
        _uploadUrl,
        data: formData,
        options: Options(headers: _authHeaders()),
      );

      final body = _asMap(response.data);
      _throwIfError(body, fallback: 'Failed to upload attachment');

      final data = body?['data'];
      final attachments =
          (data is Map<String, dynamic>) ? data['attachments'] : null;
      if (attachments is! Map<String, dynamic>) return const [];

      // Look each file up by its (possibly disambiguated) upload name
      // to preserve 1:1 order with the input list.
      return [
        for (final name in uploadNames)
          if (attachments[name] is num) (attachments[name] as num).toInt(),
      ];
    } on DioException catch (e) {
      throw _fromDioException(e);
    } on ServiceRequestException {
      rethrow;
    } catch (_) {
      throw const ServiceRequestException('Something went wrong');
    }
  }

  @override
  Future<Map<String, dynamic>> createServiceRequest(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post<dynamic>(
        _createUrl,
        data: {
          'data': data,
          'moduleName': 'serviceRequest',
        },
        options: Options(headers: _authHeaders()),
      );

      final body = _asMap(response.data);
      _throwIfError(body, fallback: 'Failed to submit service request');

      final responseData = body?['data'];
      final serviceRequest = (responseData is Map<String, dynamic>)
          ? responseData['serviceRequest']
          : null;
      if (serviceRequest is! Map<String, dynamic>) {
        throw const ServiceRequestException('Unexpected response from server');
      }
      return serviceRequest;
    } on DioException catch (e) {
      throw _fromDioException(e);
    } on ServiceRequestException {
      rethrow;
    } catch (_) {
      throw const ServiceRequestException('Something went wrong');
    }
  }

  Map<String, String> _authHeaders() {
    final token = _session.token.value;
    return {
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  void _throwIfError(Map<String, dynamic>? body, {required String fallback}) {
    if (body == null) {
      throw const ServiceRequestException('Unexpected response from server');
    }
    final code = body['code'];
    if (code != null && code != 0) {
      throw ServiceRequestException((body['message'] ?? fallback).toString());
    }
  }

  ServiceRequestException _fromDioException(DioException e) {
    final errorBody = _asMap(e.response?.data);
    final message = errorBody != null ? _extractMessage(errorBody) : null;
    return ServiceRequestException(
      message ?? e.message ?? 'Something went wrong',
    );
  }

  /// Turns `[a.jpg, a.jpg, b.jpg]` into `[a.jpg, a (2).jpg, b.jpg]` so
  /// every upload maps back to a unique response key.
  List<String> _disambiguateNames(Iterable<String> names) {
    final seenCounts = <String, int>{};
    return [
      for (final name in names)
        if ((seenCounts[name] = (seenCounts[name] ?? 0) + 1) == 1)
          name
        else
          _withSuffix(name, seenCounts[name]!),
    ];
  }

  String _withSuffix(String name, int occurrence) {
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex <= 0) return '$name ($occurrence)';
    final base = name.substring(0, dotIndex);
    final ext = name.substring(dotIndex);
    return '$base ($occurrence)$ext';
  }

  String _contentTypeFor(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
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