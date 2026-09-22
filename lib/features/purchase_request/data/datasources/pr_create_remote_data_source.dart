import 'package:dio/dio.dart';
import 'package:iungo/core/constants/app_urls.dart';
import 'package:iungo/features/purchase_request/data/datasources/pr_create_exceptions.dart';
import 'package:iungo/features/purchase_request/data/models/pr_create_mapper.dart';
import 'package:iungo/features/purchase_request/data/models/pr_save_request_model.dart';
import 'package:iungo/features/purchase_request/domain/entities/contract_option.dart';
import 'package:iungo/features/service_request/domain/entities/attachment_file.dart';

abstract class PrCreateRemoteDataSource {
  /// `GET purchase_request.php` with `{"action": "fetch_contract_code",
  /// "user_id": ...}` (a GET carrying a JSON body — exactly as the API is
  /// called from Postman).
  Future<List<ContractOption>> fetchContracts({required String userId});

  /// `POST file_uploads.php` (multipart) — uploads ONE attachment and
  /// returns the stored filename (`data.saved_name`) that goes into the
  /// save payload's `attachments`.
  /// [field] tells the server which kind of file this is
  /// (`attachments` for a PR quotation, `delivery_notes` for a GRN
  /// delivery note) — the upload endpoint is shared across the Iungo
  /// flows, only this field name changes.
  Future<String> uploadAttachment(
    AttachmentFile file, {
    String field = 'attachments',
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  });

  /// `POST purchase_request.php` with `action: save_purchase_request`.
  /// Returns the server's success `message` (may be null).
  Future<String?> savePurchaseRequest(PrSaveRequestModel request);
}

/// Talks to `https://iungo.citgroupltd.com/api/*`. These endpoints
/// identify the user through `user_id` in the request (no bearer token).
class PrCreateRemoteDataSourceImpl implements PrCreateRemoteDataSource {
  PrCreateRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  /// The server can take a long time to answer an upload (over a minute
  /// was observed for a ~500 KB PDF), so uploads get a far more generous
  /// timeout than the JSON calls.
  static const Duration _uploadTimeout = Duration(minutes: 3);

  static const Map<String, String> _jsonHeaders = {
    'Accept': 'application/json',
  };

  @override
  Future<List<ContractOption>> fetchContracts({required String userId}) async {
    try {
      final response = await _dio.request<dynamic>(
        AppUrls.purchaseRequestApi,
        data: {
          'action': 'fetch_contract_code',
          'user_id': userId,
        },
        options: Options(
          method: 'GET',
          contentType: Headers.jsonContentType,
          headers: _jsonHeaders,
        ),
      );

      final body = _requireBody(response.data);
      prEnsureApiSuccess(body);
      return PrCreateMapper.contracts(body);
    } on DioException catch (e) {
      throw mapPrDioError(e);
    } on PrCreateException {
      rethrow;
    } catch (_) {
      throw const PrCreateException(PrCreateFailure.unknown);
    }
  }

  @override
  Future<String> uploadAttachment(
    AttachmentFile file, {
    String field = 'attachments',
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final MultipartFile multipart;
      if (file.bytes != null) {
        multipart = MultipartFile.fromBytes(file.bytes!, filename: file.name);
      } else if (file.path != null) {
        multipart = await MultipartFile.fromFile(
          file.path!,
          filename: file.name,
        );
      } else {
        throw const PrCreateException(PrCreateFailure.unknown);
      }

      final size = file.sizeBytes ?? file.bytes?.length ?? 0;
      final formData = FormData.fromMap({
        'file': multipart,
        'field': field,
        'original_name': file.name,
        'file_size': size.toString(),
      });

      final response = await _dio.post<dynamic>(
        AppUrls.fileUploadApi,
        data: formData,
        cancelToken: cancelToken,
        onSendProgress: onProgress,
        options: Options(
          headers: _jsonHeaders,
          sendTimeout: _uploadTimeout,
          receiveTimeout: _uploadTimeout,
        ),
      );

      final body = _requireBody(response.data);
      prEnsureApiSuccess(body);
      return PrCreateMapper.uploadedFileName(body);
    } on DioException catch (e) {
      throw mapPrDioError(e);
    } on PrCreateException {
      rethrow;
    } catch (_) {
      throw const PrCreateException(PrCreateFailure.unknown);
    }
  }

  @override
  Future<String?> savePurchaseRequest(PrSaveRequestModel request) async {
    try {
      final response = await _dio.post<dynamic>(
        AppUrls.purchaseRequestApi,
        data: request.toJson(),
        options: Options(
          contentType: Headers.jsonContentType,
          headers: _jsonHeaders,
        ),
      );

      final body = _requireBody(response.data);
      prEnsureApiSuccess(body);
      return prServerMessage(body);
    } on DioException catch (e) {
      throw mapPrDioError(e);
    } on PrCreateException {
      rethrow;
    } catch (_) {
      throw const PrCreateException(PrCreateFailure.unknown);
    }
  }

  Map<String, dynamic> _requireBody(dynamic raw) {
    final body = prAsJsonMap(raw);
    if (body == null) {
      throw const PrCreateException(PrCreateFailure.invalidResponse);
    }
    return body;
  }
}
