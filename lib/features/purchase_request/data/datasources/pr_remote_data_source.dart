import 'package:dio/dio.dart';
import 'package:iungo/core/constants/app_urls.dart';
import 'package:iungo/features/purchase_request/data/datasources/pr_create_exceptions.dart';
import 'package:iungo/features/purchase_request/data/models/pr_api_mapper.dart';
import 'package:iungo/features/purchase_request/data/models/pr_decision_request.dart';
import 'package:iungo/features/purchase_request/data/models/pr_list_query.dart';
import 'package:iungo/features/purchase_request/domain/entities/pr_list_page.dart';

abstract class PrRemoteDataSource {
  /// `GET purchase_request.php` with the list query as a JSON body.
  /// Success is body `code` 200.
  Future<PrListPage> fetchPurchaseRequests(PrListQuery query);

  /// `GET purchase_request.php` with an approve/reject body. Success is
  /// body `code` 0 (NOT 200); returns the server's `message`.
  Future<String?> submitDecision(PrDecisionRequest request);
}

/// Talks to `https://iungo.citgroupltd.com/api/purchase_request.php`.
/// Like the rest of the Iungo endpoints it identifies the user through
/// `user_id` in the body (no bearer token), and — exactly as the API
/// guide's Postman captures show — is called with a GET carrying a JSON
/// body. Failures are reported as [PrCreateException] (the shared
/// Purchase Request failure type) so every PR screen maps errors the
/// same way.
class PrRemoteDataSourceImpl implements PrRemoteDataSource {
  PrRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  static const Map<String, String> _jsonHeaders = {
    'Accept': 'application/json',
  };

  /// The mutation API's success `code`.
  static const int decisionSuccessCode = 0;

  @override
  Future<PrListPage> fetchPurchaseRequests(PrListQuery query) async {
    try {
      final body = await _send(query.toJson());
      // Listing API: code 200 == success.
      prEnsureApiSuccess(body);
      return PrApiMapper.listPage(
        body,
        requestedPage: query.pageNumber,
        requestedLimit: query.pageLimit,
      );
    } on DioException catch (e) {
      throw mapPrDioError(e);
    } on PrCreateException {
      rethrow;
    } catch (_) {
      throw const PrCreateException(PrCreateFailure.unknown);
    }
  }

  @override
  Future<String?> submitDecision(PrDecisionRequest request) async {
    try {
      final body = await _send(request.toJson());
      _ensureDecisionSuccess(body);
      return prServerMessage(body);
    } on DioException catch (e) {
      throw mapPrDioError(e);
    } on PrCreateException {
      rethrow;
    } catch (_) {
      throw const PrCreateException(PrCreateFailure.unknown);
    }
  }

  Future<Map<String, dynamic>> _send(Map<String, dynamic> payload) async {
    final response = await _dio.request<dynamic>(
      AppUrls.purchaseRequestApi,
      data: payload,
      options: Options(
        method: 'GET',
        contentType: Headers.jsonContentType,
        headers: _jsonHeaders,
      ),
    );
    final body = prAsJsonMap(response.data);
    if (body == null) {
      throw const PrCreateException(PrCreateFailure.invalidResponse);
    }
    return body;
  }

  /// Approve/reject answer HTTP 200 with `{"code": 0, "message": ...}`
  /// on success and e.g. `{"code": 1, "message": "Please enter remarks
  /// ..."}` on a refusal — so only `code == 0` counts as success, and a
  /// refusal carries the server's own message.
  void _ensureDecisionSuccess(Map<String, dynamic> body) {
    final raw = body['code'];
    final code = raw is num
        ? raw.toInt()
        : (raw is String ? int.tryParse(raw.trim()) : null);
    if (code == null) {
      throw const PrCreateException(PrCreateFailure.invalidResponse);
    }
    if (code == decisionSuccessCode) return;

    final message = prServerMessage(body);
    if (code == 401 || code == 440) {
      throw PrCreateException(
        PrCreateFailure.unauthorized,
        message: message,
        statusCode: code,
      );
    }
    if (code == 403) {
      throw PrCreateException(
        PrCreateFailure.forbidden,
        message: message,
        statusCode: code,
      );
    }
    throw PrCreateException(
      code >= 500 ? PrCreateFailure.server : PrCreateFailure.rejected,
      message: message,
      statusCode: code,
    );
  }
}
